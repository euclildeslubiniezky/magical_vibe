const functions = require("firebase-functions");
const admin = require("firebase-admin");
const fetch = require("node-fetch");

admin.initializeApp();
const db = admin.firestore();

const FAL_KEY = process.env.FAL_KEY;

// ===============================
// 生成開始（Flutterから呼ばれる）
// ===============================
exports.generateVideo = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Login required");
  }

  const uid = context.auth.uid;
  const prompt = data.prompt;

  if (!prompt) {
    throw new functions.https.HttpsError("invalid-argument", "Prompt missing");
  }

  const userRef = db.collection("users").doc(uid);

  return await db.runTransaction(async (tx) => {
    const userDoc = await tx.get(userRef);

    if (!userDoc.exists) {
      throw new functions.https.HttpsError("not-found", "User not found");
    }

    const credits = userDoc.data().credits || 0;

    if (credits <= 0) {
      throw new functions.https.HttpsError("failed-precondition", "No credits");
    }

    // クレジット減算
    tx.update(userRef, {
      credits: credits - 1,
    });

    // videoJobs作成
    const jobRef = db.collection("videoJobs").doc();

    tx.set(jobRef, {
      uid: uid,
      prompt: prompt,
      status: "processing",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 非同期Fal呼び出し
    processFal(jobRef.id, prompt);

    return { jobId: jobRef.id };
  });
});

// ===============================
// Fal非同期処理
// ===============================
async function processFal(jobId, prompt) {
  const jobRef = db.collection("videoJobs").doc(jobId);

  try {
    // Falへ送信（例：text-to-videoモデル）
    const response = await fetch("https://fal.run/fal-ai/text-to-video", {
      method: "POST",
      headers: {
        "Authorization": `Key ${FAL_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        prompt: prompt,
        duration: 4,
        aspect_ratio: "16:9",
      }),
    });

    const result = await response.json();

    if (!response.ok) {
      throw new Error(result.detail || "Fal error");
    }

    const videoUrl = result.video?.url;

    if (!videoUrl) {
      throw new Error("No video returned");
    }

    await jobRef.update({
      status: "completed",
      videoUrl: videoUrl,
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

  } catch (error) {
    console.error("Fal Error:", error);

    // 失敗 → ステータス更新
    await jobRef.update({
      status: "failed",
      error: error.message,
    });

    // クレジット返却
    const jobDoc = await jobRef.get();
    const uid = jobDoc.data().uid;

    const userRef = db.collection("users").doc(uid);

    await userRef.update({
      credits: admin.firestore.FieldValue.increment(1),
    });
  }
}