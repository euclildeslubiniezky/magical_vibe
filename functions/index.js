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

  // 【最高画質・少女の統一感プロンプト】
  const baseQuality = "Cinematic extreme wide full body shot of a youthful spirit girl, youthful features, petite and ethereal silhouette, showing the entire character from head to toe, innocent and mystical face, masterpiece, 8k, ";
  const handDetail = "matching nail polish, elegant small fingers, ";

  const prompts = {
    'Fire': baseQuality + handDetail + "red nails, Spirit girl in a roaring fire phoenix dress, burning embers",
    'Water': baseQuality + handDetail + "blue nails, Spirit girl in a flowing water dress, shimmering water particles and ethereal mist",
    'Thunder': baseQuality + handDetail + "yellow nails, Spirit girl in a lightning-bolt dress, vertical lightning strikes from heaven",
    'Ice': baseQuality + handDetail + "light blue nails, Spirit girl in a frozen crystal dress, ice shards",
    'Wind': baseQuality + handDetail + "green nails, Spirit girl in an emerald cyclone dress, floating ribbons",
    'Light': baseQuality + handDetail + "white nails, Spirit girl in a divine light dress, white fractals",
    'Dark': baseQuality + handDetail + "purple nails, Spirit girl in a cosmic void dress, mysterious shadow energy",
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
    const videoResponse = await axios.post('https://fal.run/fal-ai/kling-video/v1.5/pro/image-to-video', {
      image_url: imageUrl,
      prompt: "The video starts with a massive explosion of " + attribute + " energy. A cinematic wide shot reveals the full body of a youthful spirit girl as her dress materializes. High quality transformation, ethereal atmosphere.",
      negative_prompt: "adult woman, sexy, mature face, close up, macro shot, only hands, cropped face, deformed hands, extra fingers, blurry body",
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