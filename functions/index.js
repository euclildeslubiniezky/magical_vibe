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
   Attribute Tables
========================= */

const locationPrompts = {
  Fire: "in the great volcano",
  Water: "in the shining sea",
  Thunder: "in the lightning storm",
  Ice: "in the frozen snow field",
  Wind: "in the Forest of Many Glowing Flowers",
  Light: "in the heavenly sky",
  Dark: "in the castlevania",
};

const particlePrompts = {
  Fire: "many floating fire balls and embers",
  Water: "many floating water spheres, floating blue water balls, glossy bubbles",
  Thunder: "electric sparks and vertical lightning particles",
  Ice: "floating ice crystals and snow particles",
  Wind: "many shining flowers and glowing petals swirling in the air",
  Light: "many fractal light motes and radiant sparkles",
  Dark: "purple lightning particles and dark smoke motes",
};

const wingPrompts = {
  Fire: "flaming phoenix wings, wide feathered fire wings",
  Water: "fluid ribbon water wings, translucent flowing wings",
  Thunder: "sharp lightning-bolt wings with electric arcs",
  Ice: "crystal shard wings with prismatic reflections",
  Wind: "airy feather wings surrounded by flower petals",
  Light: "radiant angel wings with luminous layers",
  Dark: "shadow bat wings with smoky purple aura",
};

const staffPrompts = {
  Fire: "long flaming phoenix sword, ornate symmetrical weapon",
  Water: "long crystal trident staff, transparent and symmetrical",
  Thunder: "long lightning spear staff, sharp and metallic",
  Ice: "long crystal ice staff, solid and symmetrical",
  Wind: "long emerald flower staff with elegant carvings",
  Light: "long radiant golden staff with halo ornament",
  Dark: "long purple lightning staff with dark crystal core",
};

/* =========================
   Flux Prompt (Lightweight)
========================= */

function buildFluxPrompt(attribute, randomHair) {

  const headItem =
    attribute === "Dark"
      ? "long horns of the devil on the head"
      : "tiara with a veil";

  const base =
    "cinematic full body shot of a young magical girl, " +
    `${headItem}, youthful face, elegant stable standing pose, ` +
    "legs together, feet together, no wide stance, masterpiece, photorealistic 8k, ";

  const dressOptions = {
    Fire: "deep crimson and gold magical dress",
    Water: "sapphire blue and pearl magical dress",
    Thunder: "electric violet and silver magical dress",
    Ice: "icy blue and white crystal dress",
    Wind: "emerald green floral magical dress",
    Light: "pure white and gold divine dress",
    Dark: "black and purple gothic magical dress",
  };

  return (
    base +
    `${randomHair}, ` +
    `${dressOptions[attribute]}, ` +
    `${particlePrompts[attribute]}, ` +
    `${locationPrompts[attribute]}, `
  );
}

/* =========================
   Kling Prompt (Generate Wings + Staff)
========================= */

function buildKlingPrompt(attribute) {

  const wing = wingPrompts[attribute];
  const staff = staffPrompts[attribute];

  return `
The video begins with a close-up of her determined face.

Large cinematic zoom-out to full body reveal (wide camera movement).

From 0s to 4s:
Transformation energy explodes around her.

At 1.5s:
A ${staff} forms from pure energy in her hand.
The weapon must remain long, symmetrical, stable.
Do not shrink. Do not morph.

At 2s:
${wing} grow and fully unfold.
Wings must remain large and stable.

Strong cinematic lighting.
Smooth dramatic camera motion.

From 4s to 5s:
Hold final heroic pose with subtle motion only.

Legs together. Stable posture.
Perfect hands. Five fingers visible.
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
    const { attribute = "Fire", duration = 5 } = request.data;

    try {
      const apiKey = falApiKey.value();

      const hairOptions = [
        "long blonde hair",
        "long silver hair",
        "long bright brown hair",
      ];

      const randomHair = randomPick(hairOptions);

      /* 1. Flux */
      const fluxPrompt = buildFluxPrompt(attribute, randomHair);

      const imageResponse = await axios.post(
        "https://fal.run/fal-ai/flux-pro/v1.1",
        {
          prompt: fluxPrompt,
          width: 1280,
          height: 720,
        },
        {
          headers: { Authorization: `Key ${apiKey}` },
          timeout: 60000,
        }
      );

      const imageUrl = imageResponse.data.images[0].url;

      /* 2. Kling */
      const klingPrompt = buildKlingPrompt(attribute);

      const videoResponse = await axios.post(
        "https://fal.run/fal-ai/kling-video/v1.5/pro/image-to-video",
        {
          image_url: imageUrl,
          prompt: klingPrompt,
          duration: duration,
          mode: "high_quality",
          negative_prompt:
            "small stick, tiny rod, short staff, broken staff, " +
            "wide stance, spread legs, bowlegged, pigeon-toed, " +
            "extra fingers, missing fingers, deformed hands, " +
            "low quality, blurry, jittery camera",
        },
        {
          headers: { Authorization: `Key ${apiKey}` },
          timeout: 480000,
        }
      );

      return {
        success: true,
        videoUrl: videoResponse.data.video.url,
      };

    } catch (error) {
      throw new HttpsError(
        "internal",
        `Transformation failed: ${error.message}`
      );
    }
  }
);