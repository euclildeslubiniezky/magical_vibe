const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require('firebase-functions/params');
const { initializeApp } = require("firebase-admin/app");
const axios = require("axios");

initializeApp();

// 【重要】衝突を避けるための新しい名前
const falApiKey = defineSecret('FAL_SECRET_KEY');

exports.generateTransformationVideo = onCall({
  timeoutSeconds: 540,
  memory: "1GiB",
  secrets: [falApiKey],
}, async (request) => {

  const { attribute, duration = 5 } = request.data;

  console.log(`--- 召喚儀式開始: 属性 [${attribute}] ---`);

  // 【最高画質・魔法少女の統一感プロンプト】
  const baseQuality = "cinematic full body shot of a young magical girl, youthful face, elegant standing pose, closed legs, legs together, balanced stance, masterpiece, 8k, ";
  const handStable = "hands clearly visible, five clearly separated fingers, correct finger anatomy, natural relaxed hand pose, no extra fingers, no fused fingers, ";
  const dressStable = "magical girl outfit formed from light energy, elegant silhouette, symmetrical design, smooth fabric, full body visible, ";
  const hairOptions = ["long blonde hair", "long bright brown hair", "long silver hair", "long black hair", "long pastel pink hair", "long light blue hair"];
  const dressOptions = ["long flowing magical dress", "long elegant layered dress", "long frilled magical outfit", "long butterfly themed dress", "long celestial star themed dress", "long crystal ornament dress"];
  const randomDress = dressOptions[Math.floor(Math.random() * dressOptions.length)];
  const randomHair = hairOptions[Math.floor(Math.random() * hairOptions.length)];

  const prompts = {
    'Fire': baseQuality + randomHair + ", " + handStable + dressStable + randomDress + ",flaming phoenix big wings, magical staff, spreading blazing flames, many floating fire balls around her, in the great volcano, ",
    'Water': baseQuality + randomHair + ", " + handStable + dressStable + randomDress + ",fluid ribbon big wings, magical staff, rippling water reflections, many floating water balls around her, in the shining ocean, ",
    'Thunder': baseQuality + randomHair + ", " + handStable + dressStable + randomDress + ",lightning-bolt big wings, magical staff, spreading lightning-bolt, many vertical lightning-bolt strikes from heaven around her, in the lightning-bolt, ",
    'Ice': baseQuality + randomHair + ", " + handStable + dressStable + randomDress + ",sharp crystal big wings, magical staff, spreading reflect ice crystals, many ice crystals around her, in the snow, ",
    'Wind': baseQuality + randomHair + ", " + handStable + dressStable + randomDress + ",floating feather big wings, magical staff, spreading many flowers bloom, many flowers bloom around her, in the shining forest, ",
    'Light': baseQuality + randomHair + ", " + handStable + dressStable + randomDress + ",radiant angel big wings, magical staff, spreading divine light, many fractal balls around her, in the heavenly sky, ",
    'Dark': baseQuality + randomHair + ", " + handStable + dressStable + randomDress + ",shadow bat big wings, magical staff, spreading purple lightning-bolt, devil horns from the head, many purple lightning-bolt around her, in the castlevania, ",
  };

  const prompt = prompts[attribute] || prompts['Fire'];

  try {
    const apiKey = falApiKey.value();

    // 1. 静止画生成 (Flux Pro v1.1)
    console.log("工程1: 最高画質の原画を錬成中...");
    const imageResponse = await axios.post('https://fal.run/fal-ai/flux-pro/v1.1', {
      prompt: prompt,
      width: 1280,
      height: 720,
    }, {
      headers: { 'Authorization': `Key ${apiKey}`, 'Content-Type': 'application/json' },
      timeout: 60000
    });

    const imageUrl = imageResponse.data.images[0].url;
    console.log("工程1完了: 原画URL取得");

    // 2. 動画生成 (Kling v1.5 Pro) - 最高画質設定
    console.log("工程2: 生命を吹き込み中（Kling v1.5 Pro / High Quality）...");

    // Attribute-specific Staff Prompts
    const staffPrompts = {
      'Fire': "flaming phoenix long staff",
      'Water': "crystal trident long staff",
      'Thunder': "lightning spear long staff",
      'Ice': "crystal ice long staff",
      'Wind': "emerald flower long staff",
      'Light': "radiant golden long staff",
      'Dark': "purple lightning-bolt long staff",
    };
    const staffName = staffPrompts[attribute] || "magical staff";

    // Dynamic Cinematic Transformation Prompt
    const videoPrompt = `The video begins with a close-up of the young magical girl's determined face. Suddenly, powerful ${attribute} energy erupts around her. The camera rapidly zooms out to reveal her full body as her magical outfit forms in radiant light. She holds her ${staffName} confidently in one hand. Dynamic cinematic lighting, dramatic many particles. Perfect hands, five fingers visible, stable anatomy. 5 second powerful transformation sequence.`;

    const videoResponse = await axios.post('https://fal.run/fal-ai/kling-video/v1.5/pro/image-to-video', {
      image_url: imageUrl,
      prompt: videoPrompt,
      negative_prompt: "adult woman, mature face, close up, macro shot, only hands, cropped face, cropped body, extra fingers, missing fingers, bad hands, deformed hands, mutated anatomy, broken arms, extra limbs, blurry hands, malformed body, broken fingers, malformed hands, blurry hands, cropped hands, distorted fingers",
      duration: duration,
      mode: "high_quality" // 最高画質モード
    }, {
      headers: { 'Authorization': `Key ${apiKey}`, 'Content-Type': 'application/json' },
      timeout: 480000
    });

    console.log("工程2完了: 精霊が姿を現しました！");
    return { success: true, videoUrl: videoResponse.data.video.url };

  } catch (error) {
    console.error("【召喚失敗】:", error.response ? JSON.stringify(error.response.data) : error.message);
    throw new HttpsError('internal', `精霊が姿を現しませんでした: ${error.message}`);
  }
});