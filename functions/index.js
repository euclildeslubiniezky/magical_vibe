const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { initializeApp } = require("firebase-admin/app");
const axios = require("axios");

initializeApp();

const falApiKey = defineSecret("FAL_SECRET_KEY");

/* =========================
   Utils
========================= */
function randomPick(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

/* =========================
   Prompt Parts
========================= */

// 1) Flux用：素体（羽根・派手背景を避ける）
function buildBaseImagePrompt(randomHair, randomDress) {
  // 「動かない」を強めると、後段のズームアウト演出が作りやすい（顔→全身）
  const baseQuality =
    "cinematic full body shot of a young magical girl, youthful face, photorealistic, masterpiece, 8k, " +
    "elegant standing pose, stable posture, legs together, full body visible, ";

  const handStable =
    "hands clearly visible, five clearly separated fingers, correct finger anatomy, natural relaxed hand pose, ";

  const dressStable =
    "magical girl outfit formed from soft light energy, elegant silhouette, symmetrical design, smooth fabric, ";

  // ★重要：Fluxでは羽根・属性エフェクト・派手背景を入れない（後でKlingに任せる）
  const neutralScene =
    "simple dark studio background, subtle fog, no wings, no big effects, no extreme particles, ";

  return (
    baseQuality +
    `${randomHair}, ` +
    handStable +
    dressStable +
    `${randomDress}, ` +
    "holding a simple staff (not detailed), " +
    neutralScene
  );
}

// 2) Kling用：羽根（後描写で生やす）
function getWingPrompt(attribute) {
  const wings = {
    Fire: "flaming phoenix big wings materializing from fire",
    Water: "fluid ribbon big wings forming from water streams",
    Thunder: "lightning-bolt big wings bursting with electric arcs",
    Ice: "sharp crystal big wings growing from ice crystals",
    Wind: "floating feather big wings appearing in swirling wind",
    Light: "radiant angel big wings unfolding with holy light rays",
    Dark: "shadow bat big wings emerging from dark smoke",
  };
  return wings[attribute] || "mystical glowing wings forming";
}

// 3) Kling用：武器（あなたのstaff案を維持）
function getStaffName(attribute) {
  const staffPrompts = {
    Fire: "flaming phoenix long staff",
    Water: "crystal trident long staff",
    Thunder: "lightning spear long staff",
    Ice: "crystal ice long staff",
    Wind: "emerald flower long staff",
    Light: "radiant golden long staff",
    Dark: "purple lightning-bolt long staff",
  };
  return staffPrompts[attribute] || "magical staff";
}

// 4) Kling用：属性別カメラ演出（同属性内ランダム）
function buildVideoPrompt(attribute, staffName) {
  const wingPrompt = getWingPrompt(attribute);

  const commonQuality = `
Cinematic transformation video. Dynamic camera. Dramatic lighting.
Perfect hands, correct anatomy, five fingers visible.
No extra fingers, no missing fingers, no deformed hands.
5 second transformation sequence.
`;

  // ★各属性：複数パターン（同属性でも毎回変化）
  const patterns = {
    Fire: [
      `
The video starts with a tight face close-up. Her eyes ignite.
A violent explosion of blazing fire erupts around her.
The camera spins rapidly in a circular motion, then WHIP-ZOOMS OUT to full body.
${wingPrompt}.
Flames spiral upward as her outfit ignites into existence.
She grips a ${staffName} confidently. Heat distortion, embers flying.
${commonQuality}
`,
      `
Close-up on her lips and eyes, then sudden fire flash.
The camera shakes from a massive fire blast, then pulls back fast to reveal full body.
${wingPrompt}.
Lava-like light forms her dress in an instant.
She swings her ${staffName} and fire particles burst outward.
${commonQuality}
`,
      `
Start with extreme close-up of her hand on the staff.
Fire energy crawls up the staff, then detonates.
The camera rotates diagonally upward and zooms out dramatically.
${wingPrompt}.
Infernal flames surround her as the costume completes.
${commonQuality}
`,
    ],

    Water: [
      `
A calm sphere of water surrounds her face close-up.
The camera slowly performs a smooth 360° orbit, then gently zooms out.
${wingPrompt}.
Water ribbons flow gracefully around her as her dress forms from liquid light.
She holds a ${staffName} elegantly. Soft reflections, serene glow.
${commonQuality}
`,
      `
Mist and droplets fill the frame in close-up.
The camera glides backward in slow motion, revealing the full body.
${wingPrompt}.
A tidal wave of light-water wraps her body, dress forms smoothly.
She lifts the ${staffName} and water particles shimmer.
${commonQuality}
`,
      `
Start from above looking down at her face.
The camera descends through mist and rotates around her.
${wingPrompt}.
Water spirals upward, forming wings last for a dramatic reveal.
She points her ${staffName} forward.
${commonQuality}
`,
    ],

    Thunder: [
      `
Lightning strikes. Close-up of her eyes reflecting electric arcs.
The camera performs fast vertical movements with dynamic tilt and shake.
${wingPrompt}.
Electric energy wraps around her, costume flashes into existence.
She thrusts a ${staffName} upward. High intensity sparks.
${commonQuality}
`,
      `
Start with close-up on the staff tip crackling.
A huge lightning blast detonates behind her.
The camera snaps outward with a fast zoom-out and slight roll.
${wingPrompt}.
Electric arcs outline her wings as they appear at the end.
${commonQuality}
`,
      `
Storm clouds swirl. Quick cuts feeling in a single prompt: rapid camera tilt, shake.
The camera orbits fast and pulls back to full body.
${wingPrompt}.
Her transformation completes in a flash, sparks everywhere.
${commonQuality}
`,
    ],

    Ice: [
      `
Close-up of frost crystals forming on her cheek.
The camera slowly zooms out from close view to full body.
${wingPrompt}.
Crystals grow around her, dress materializes like frozen light.
Cold blue glow, shimmering particles. She calmly holds a ${staffName}.
${commonQuality}
`,
      `
Start with drifting frozen mist in close-up.
The camera slides sideways smoothly, then reveals full body with slow pull-back.
${wingPrompt}.
Ice shards float and lock into wing shape at the end for a big reveal.
She raises her ${staffName} slowly.
${commonQuality}
`,
      `
The scene freezes for a split second.
The camera rotates gently upward and pulls back.
${wingPrompt}.
Frost erupts outward, dress forms, wings unfold last.
${commonQuality}
`,
    ],

    Wind: [
      `
A powerful gust swirls. Close-up of her hair moving in wind.
The camera circles wide from below (heroic low angle), then zooms out.
${wingPrompt}.
Glowing particles spiral upward. Her outfit flows dramatically.
She steadies a ${staffName}.
${commonQuality}
`,
      `
Leaves and petals fly past the lens in close-up.
The camera arcs wide around her and pulls back fast to full body.
${wingPrompt}.
Wind energy forms wings in a final sweep.
She swings the ${staffName}.
${commonQuality}
`,
      `
Start near the ground looking up.
The camera ascends vertically while orbiting slightly.
${wingPrompt}.
A vortex forms, her dress forms, wings appear late with a big flourish.
${commonQuality}
`,
    ],

    Light: [
      `
Begin in darkness with a close-up silhouette.
Radiant beams descend from above. The camera slowly rises upward revealing full body.
${wingPrompt}.
Volumetric light rays. Wings unfold last with a holy burst.
She holds a ${staffName} gracefully.
${commonQuality}
`,
      `
Golden particles fall in close-up like glitter.
The camera rotates slowly, then expands outward into bright full-body reveal.
${wingPrompt}.
Divine aura surrounds her. She lifts the ${staffName} skyward.
${commonQuality}
`,
      `
Close-up on her eyes, then sudden bloom of light.
The camera zooms out from darkness into brilliance.
${wingPrompt}.
Angelic wings open at the end. Soft but powerful holy transformation.
${commonQuality}
`,
    ],

    Dark: [
      `
Dark shadows expand. Close-up of her face partially hidden.
The camera slowly moves forward then pulls back to full-body framing.
${wingPrompt}.
Purple-black energy pulses. Deep contrast cinematic lighting.
She raises a ${staffName} ominously.
${commonQuality}
`,
      `
Start with smoky darkness in close-up.
The camera circles from a distance then glides closer.
${wingPrompt}.
Wings emerge late from black smoke for a dramatic reveal.
She grips the ${staffName} tightly.
${commonQuality}
`,
      `
A dark portal opens behind her in close-up.
The camera tilts dramatically and pulls out.
${wingPrompt}.
Shadow energy spirals upward, wings form last, ominous glow.
${commonQuality}
`,
    ],
  };

  const selected = patterns[attribute] ? randomPick(patterns[attribute]) : `
Magical energy explodes. Dynamic cinematic camera movement.
Wings form during transformation. She holds a magical staff.
${commonQuality}
`;

  return selected;
}

/* =========================
   Function
========================= */

exports.generateTransformationVideo = onCall(
  {
    timeoutSeconds: 540,
    memory: "1GiB",
    secrets: [falApiKey],
  },
  async (request) => {
    const { attribute, duration = 5 } = request.data;

    console.log(`--- 召喚儀式開始: 属性 [${attribute}] ---`);

    try {
      const apiKey = falApiKey.value();

      // ランダム髪・衣装（見た目の差分を作る）
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

      // ===== 1) 静止画生成（羽根なしの素体） =====
      console.log("工程1: 素体（羽根なし）原画を錬成中...");
      const imagePrompt = buildBaseImagePrompt(randomHair, randomDress);

      const imageResponse = await axios.post(
        "https://fal.run/fal-ai/flux-pro/v1.1",
        {
          prompt: imagePrompt,
          width: 1280,
          height: 720,
        },
        {
          headers: {
            Authorization: `Key ${apiKey}`,
            "Content-Type": "application/json",
          },
          timeout: 60000,
        }
      );

      const imageUrl = imageResponse.data?.images?.[0]?.url;
      if (!imageUrl) {
        throw new Error("Flux returned no image URL");
      }
      console.log("工程1完了: 原画URL取得");

      // ===== 2) 動画生成（羽根・属性エフェクト・カメラ演出を後描写） =====
      console.log("工程2: 生命を吹き込み中（Kling v1.5 Pro / High Quality）...");

      const staffName = getStaffName(attribute);
      const videoPrompt = buildVideoPrompt(attribute, staffName);

      const videoResponse = await axios.post(
        "https://fal.run/fal-ai/kling-video/v1.5/pro/image-to-video",
        {
          image_url: imageUrl,
          prompt: videoPrompt,
          negative_prompt:
            "adult woman, mature face, macro shot, only hands, cropped body, extra fingers, missing fingers, bad hands, deformed hands, mutated anatomy, broken arms, extra limbs, blurry hands, malformed body, broken fingers, distorted fingers, disappearing wings, hidden wings, low quality, blurry",
          duration: duration,
          mode: "high_quality",
        },
        {
          headers: {
            Authorization: `Key ${apiKey}`,
            "Content-Type": "application/json",
          },
          timeout: 480000,
        }
      );

      const videoUrl = videoResponse.data?.video?.url;
      if (!videoUrl) {
        throw new Error("Kling returned no video URL");
      }

      console.log("工程2完了: 精霊が姿を現しました！");
      return { success: true, videoUrl };

    } catch (error) {
      console.error("【召喚失敗】:", error.response ? JSON.stringify(error.response.data) : error.message);
      throw new HttpsError("internal", `精霊が姿を現しませんでした: ${error.message}`);
    }
  }
);