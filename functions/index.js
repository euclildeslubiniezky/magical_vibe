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
  const baseQuality = "Cinematic full body shot of a young magical girl, youthful face, balanced stance, masterpiece, 8k, ";
  const handStable = "hands clearly visible, five clearly separated fingers, correct finger anatomy, natural relaxed hand pose, no extra fingers, no fused fingers, ";
  const dressStable = "Transforming from see through lingerie to a luxurious dress while glowing, elegant posture, smooth silk texture, symmetrical design, structured bodice, layered skirt, controlled fabric physics, no distortion, full body visible, entire character visible, no cropping, ";
  const hairOptions = ["long blonde hair", "bright brown hair", "silver hair", "black hair", "pastel pink hair", "light blue hair"];
  const dressOptions = ["flowing magical dress", "elegant layered dress", "short frilled magical outfit", "butterfly themed dress", "celestial star themed dress", "crystal ornament dress"];
  const randomDress = dressOptions[Math.floor(Math.random() * dressOptions.length)];
  const randomHair = hairOptions[Math.floor(Math.random() * hairOptions.length)];

  const prompts = {
    'Fire': baseQuality + randomHair + ", " + handStable + dressStable + randomDress + ",flaming phoenix wings, magical staff, burning embers, many fire particles, red light behind her, full body visible, entire character visible, no cropping",
    'Water': baseQuality + randomHair + ", " + handStable + dressStable + randomDress + ",fluid ribbon wings, magical staff, rippling water reflections, many floating water balls, many water particles, blue light behind her, ocean, in the water, full body visible, entire character visible, no cropping",
    'Thunder': baseQuality + randomHair + ", " + handStable + dressStable + randomDress + ",lightning-bolt wings, magical staff, many vertical lightning-bolt strikes from heaven, lightning-bolt particles, lightning-bolt behind her, full body visible, entire character visible, no cropping",
    'Ice': baseQuality + randomHair + ", " + handStable + dressStable + randomDress + ",sharp crystal wings, magical staff,hard reflective ice surfaces, many snow particles, cold blue lighting, solid geometric structure, frozen crystal particles, blue light behind her, full body visible, entire character visible, no cropping",
    'Wind': baseQuality + randomHair + ", " + handStable + dressStable + randomDress + ",floating feather wings, magical staff, floating ribbons, many emerald particles, green light behind her, full body visible, entire character visible, no cropping",
    'Light': baseQuality + randomHair + ", " + handStable + dressStable + randomDress + ",radiant angel wings, magical staff white fractals, many light particles, white light behind her, full body visible, entire character visible, no cropping",
    'Dark': baseQuality + randomHair + ", " + handStable + dressStable + randomDress + ",shadow bat wings, magical staff, purple mysterious shadow energy, devil horns from the head, many purple dark magic lightning particles, full body visible, entire character visible, no cropping",
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
      'Fire': "flaming phoenix staff",
      'Water': "crystal trident staff",
      'Thunder': "lightning spear staff",
      'Ice': "crystal ice staff",
      'Wind': "emerald wind staff",
      'Light': "radiant golden staff",
      'Dark': "shadow magic staff",
    };
    const staffName = staffPrompts[attribute] || "magical staff";

    // Dynamic Cinematic Transformation Prompt
    const videoPrompt = `The video begins with a close-up of the young magical girl's determined face. Suddenly, powerful ${attribute} energy erupts around her. The camera rapidly zooms out to reveal her full body as her magical outfit forms in radiant light. She holds her ${staffName} confidently in one hand. Dynamic cinematic lighting, dramatic many particles. Perfect hands, five fingers visible, stable anatomy. 5 second powerful transformation sequence.`;

    const videoResponse = await axios.post('https://fal.run/fal-ai/kling-video/v1.5/pro/image-to-video', {
      image_url: imageUrl,
      prompt: videoPrompt,
      negative_prompt: "adult woman, sexy, mature face, close up, macro shot, only hands, cropped face, cropped body, extra fingers, missing fingers, bad hands, deformed hands, mutated anatomy, broken arms, extra limbs, blurry hands, malformed body, broken fingers, malformed hands, blurry hands, cropped hands, distorted fingers",
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