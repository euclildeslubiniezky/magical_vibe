const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { initializeApp } = require("firebase-admin/app");
const axios = require("axios");

initializeApp();

// Secret
const falApiKey = defineSecret("FAL_SECRET_KEY");

/* =========================
   Utils
========================= */
function randomPick(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

/* =========================
   Attribute Tables
========================= */

// 羽根（←Kling側へ移す）
const wingPrompts = {
  Fire: "flaming phoenix big wings",
  Water: "fluid ribbon big wings",
  Thunder: "lightning-bolt big wings",
  Ice: "sharp crystal big wings",
  Wind: "floating feather big wings",
  Light: "radiant angel big wings",
  Dark: "shadow bat big wings",
};

// 杖（←Flux側へ固定で描く）
const staffPrompts = {
  Fire: "flaming phoenix long staff",
  Water: "crystal trident long staff",
  Thunder: "lightning spear long staff",
  Ice: "crystal ice long staff",
  Wind: "emerald flower long staff",
  Light: "radiant golden long staff",
  Dark: "purple lightning-bolt long staff",
};

// 場所（←Flux側の最後に必ず入れる）
const locationPrompts = {
  Fire: "in the great volcano",
  Water: "in the shining sea",
  Thunder: "in the lightning-bolt",
  Ice: "in the snow",
  Wind: "in the shining forest",
  Light: "in the heavenly sky",
  Dark: "in the castlevania",
};

function safeAttribute(attribute) {
  return wingPrompts[attribute] ? attribute : "Fire";
}

/* =========================
   Build Prompts
========================= */

function buildFluxPrompt(attribute, randomHair, randomDress) {
  // 要望：髪は現状のまま（カラーを追加するなどはしない）
  // ※元のセットを維持
  const baseQuality =
    "cinematic full body shot of a young magical girl, bridal gown, choker, brooch, " +
    "youthful face, elegant standing pose and don't move, closed legs and don't move, " +
    "keep your feet together and don't move, maintain a stable posture and don't move, " +
    "masterpiece, photorealistic 8k, ";

  const handStable =
    "hands clearly visible, five clearly separated fingers, correct finger anatomy, " +
    "natural relaxed hand pose, no extra fingers, no fused fingers, ";

  const dressStable =
    "magical girl outfit formed from light energy, elegant silhouette, symmetrical design, " +
    "smooth fabric, full body visible, ";

  const staff = staffPrompts[attribute] || "magical staff";
  const place = locationPrompts[attribute] || locationPrompts.Fire;

  // ★重要：Fluxでは羽根を入れない（羽根はKlingで“出現”）
  // ただし、場所は「そのまま維持」の要望なので入れる
  // ついでに「杖が壊れる」対策として、Fluxで杖の造形を確定させる（具体ワードを入れる）
  return (
    baseQuality +
    `${randomHair}, ` +
    handStable +
    dressStable +
    `${randomDress}, ` +
    `${staff}, ` +
    "spreading magical energy, " +
    `${place}, `
  );
}

function buildKlingVideoPrompt(attribute) {
  const wing = wingPrompts[attribute] || "mystical big wings";
  // 4秒で変身完了、最後1秒は余韻
  // 「羽根は途中で出る」を強制（start = no wings / mid = forming / end = fully unfolded）
  // 「杖を壊さない」を強化（do not break / do not melt / do not morph）
  return `
The video begins with a close-up of a young magical girl's determined face.
No wings at the start. Keep her staff intact and unchanged.

Suddenly, powerful ${attribute} energy erupts around her.
A drone camera quickly zooms out to reveal her full body.

From 0s to 4s: transformation completes fully.
Her costume forms in radiant light, particles surge dramatically.
Wings appear during the transformation (NOT at the start):
${wing} materialize from energy around 2s, then fully unfold by 4s.

From 4s to 5s: hold the final heroic pose with subtle motion only
(gentle particles, soft energy shimmer). No additional changes.

Perfect hands, correct anatomy, five fingers visible.
Cinematic lighting, dramatic but stable framing.
`;
}

/* =========================
   Callable Function
========================= */

exports.generateTransformationVideo = onCall(
  {
    timeoutSeconds: 540,
    memory: "1GiB",
    secrets: [falApiKey],
    region: "us-central1",
  },
  async (request) => {
    const { attribute, duration = 5 } = request.data;

    const attr = safeAttribute(attribute);
    console.log(`--- 召喚儀式開始: 属性 [${attr}] / duration=${duration} ---`);

    try {
      const apiKey = falApiKey.value();

      // 髪：現状維持（あなたの最初のセット）
      const hairOptions = [
        "long blonde hair",
        "long bright brown hair",
        "long silver hair",
        "long black hair",
        "long pastel pink hair",
        "long light blue hair",
      ];

      const dressOptions = [
        "long flowing magical dress",
        "long elegant layered dress",
        "long frilled magical outfit",
        "long butterfly themed dress",
        "long celestial star themed dress",
        "long crystal ornament dress",
      ];

      const randomHair = randomPick(hairOptions);
      const randomDress = randomPick(dressOptions);

      // 1) Flux 静止画（杖あり・羽根なし・場所あり）
      console.log("工程1: 最高画質の原画を錬成中（杖あり・羽根なし）...");
      const fluxPrompt = buildFluxPrompt(attr, randomHair, randomDress);

      const imageResponse = await axios.post(
        "https://fal.run/fal-ai/flux-pro/v1.1",
        {
          prompt: fluxPrompt,
          width: 1280,
          height: 720,
        },
        {
          headers: { Authorization: `Key ${apiKey}`, "Content-Type": "application/json" },
          timeout: 60000,
        }
      );

      const imageUrl = imageResponse?.data?.images?.[0]?.url;
      if (!imageUrl) throw new Error("Flux returned no image URL");
      console.log("工程1完了: 原画URL取得");

      // 2) Kling 動画（羽根を途中で出す）
      console.log("工程2: 生命を吹き込み中（Kling v1.5 Pro / High Quality）...");

      const videoPrompt = buildKlingVideoPrompt(attr);

      const videoResponse = await axios.post(
        "https://fal.run/fal-ai/kling-video/v1.5/pro/image-to-video",
        {
          image_url: imageUrl,
          prompt: videoPrompt,

          // 杖崩れ対策・手崩れ対策・羽根消失対策を入れる
          negative_prompt:
            "broken staff, cracked staff, melted staff, warped staff, deformed staff, " +
            "extra fingers, missing fingers, bad hands, deformed hands, mutated anatomy, " +
            "broken arms, extra limbs, blurry hands, malformed body, cropped body, " +
            "disappearing wings, hidden wings, low quality, blurry, jittery camera",

          // durationは5固定推奨（あなたのUX方針）
          duration: duration,
          mode: "high_quality",
        },
        {
          headers: { Authorization: `Key ${apiKey}`, "Content-Type": "application/json" },
          timeout: 480000,
        }
      );

      const videoUrl = videoResponse?.data?.video?.url;
      if (!videoUrl) throw new Error("Kling returned no video URL");

      console.log("工程2完了: 精霊が姿を現しました！");
      return { success: true, videoUrl };
    } catch (error) {
      console.error(
        "【召喚失敗】:",
        error.response ? JSON.stringify(error.response.data) : error.message
      );
      throw new HttpsError("internal", `精霊が姿を現しませんでした: ${error.message}`);
    }
  }
);