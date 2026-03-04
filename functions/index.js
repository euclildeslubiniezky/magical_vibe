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
   World Tables (Flux)
========================= */

const locationPrompts = {
  Fire: "in the great volcano",
  Water: "in the shining sea",
  Thunder: "in the vertical lightning bolts with hard rain on the cliff",
  Ice: "in the frozen crystal field",
  Wind: "in the Many Glowing Flowers",
  Light: "in the heavenly sky",
  Dark: "inside the dark castlevania throne hall",
};

const particlePrompts = {
  Fire: "many floating fire balls and embers around her",
  Water: "many transparent water spheres floating in mid-air around her",
  Thunder: "many vertical lightning bolts striking in the around her",
  Ice: "many floating ice crystals and light snow particles around her",
  Wind: "many glowing flower petals swirling gently around her",
  Light: "many radiant light motes floating in the air and around her",
  Dark: "subtle purple lightning arcs and dark smoke particles around her",
};

const dressPrompts = {
  Fire: "crimson and gold layered magical dress with rich volume",
  Water: "sapphire flowing magical dress liquid-like folds with rich volume",
  Thunder: "violet and silver sharp-edged magical dress with rich volume",
  Ice: "icy blue crystal layered magical dress with rich volume",
  Wind: "emerald floral magical dress flowing petals with rich volume",
  Light: "white and gold divine magical dress with rich volume",
  Dark: "black and purple gothic magical dress with rich volume",
};

/* =========================
   Kling Tables
========================= */

const wingPrompts = {
  Fire: "flaming phoenix wings, fiercely burning wings",
  Water: "flowing translucent water wings, translucent flowing wings",
  Thunder: "sharp lightning-bolt wings with electric arcs",
  Ice: "feathers made of ice crystals that reflect light",
  Wind: "airy feather wings surrounded by petals",
  Light: "radiant angel wings with luminous layers",
  Dark: "purple bat wings with purple lightning-bolt",
};

const staffPrompts = {
  Fire: "long flaming phoenix staff, ornate symmetrical weapon",
  Water: "long crystal trident staff, transparent and symmetrical",
  Thunder: "long lightning spear staff, sharp and metallic",
  Ice: "long crystal ice staff, solid and symmetrical",
  Wind: "long emerald flower staff with elegant carvings",
  Light: "long radiant golden staff with halo ornament",
  Dark: "long purple lightning staff with dark crystal core",
};

/* =========================
   Flux Prompt
========================= */

function buildFluxPrompt(attribute, hair) {

  const headItem =
    attribute === "Dark"
      ? "long horns of the devil on the head"
      : "tiara with a veil";

  return `
cinematic full body shot of a young magical girl,
${headItem},
${hair},
legs together, feet together, stable elegant posture,
photorealistic, masterpiece, 8k,
${dressPrompts[attribute]},
${particlePrompts[attribute]},
${locationPrompts[attribute]},
bright cinematic environment lighting,
`.trim();
}

/* =========================
   Kling Prompt (Stable Mode)
========================= */

function buildKlingPrompt(attribute) {

  const wing = wingPrompts[attribute];
  const staff = staffPrompts[attribute];

  return `
Start with close-up of her determined face.

The drone camera zooms out and pans to capture her full figure.

From 0s to 4s:
A controlled magical energy surge expands gently (NOT chaotic explosion).

At 1.5s:
A ${staff} forms from stable light energy in her right hand.
The staff must remain long, symmetrical, stable,
and must remain in her hand until the end.

At 2s:
${wing} grow from her back attachment points.
Wings must stay attached to her body and aligned.

Camera movement must be smooth.No violent shaking.
Continuous stable 5-second sequence.

From 4s to 5s:
Hold final heroic pose with subtle motion.

Legs together.
Perfect hands, five fingers visible.
`.trim();
}

/* =========================
   Callable
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
          negative_prompt:
            "adult woman, wide stance, spread legs, extra fingers, deformed hands, wings, staff",
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
          duration,
          mode: "high_quality",
          negative_prompt:
            "broken staff, short staff, shrinking staff, detached wings, jittery camera, violent explosion",
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
      throw new HttpsError("internal", error.message);
    }
  }
);