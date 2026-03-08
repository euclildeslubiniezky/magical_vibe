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
  Thunder: "in the vertical lightning bolts with heavy rain on the cliff",
  Ice: "in the frozen crystal field",
  Wind: "in the field of many glowing flowers",
  Light: "in the heavenly sky",
  Dark: "inside the dark castlevania throne hall",
};

const particlePrompts = {
  Fire: "many floating fire balls and embers around her",
  Water: "many transparent water spheres floating in mid-air around her",
  Thunder: "many vertical lightning bolts striking around her",
  Ice: "many floating ice crystals and light snow particles around her",
  Wind: "many glowing flower petals swirling gently around her",
  Light: "many radiant light motes floating in the air around her",
  Dark: "many purple lightning arcs and purple lightning particles around her",
};

const dressPrompts = {
  Fire: "crimson and gold layered magical dress with rich volume",
  Water: "sapphire-colored fold composed of water where time stands still and a voluminous with rich volume",
  Thunder: "violet and silver sharp-edged magical dress with rich volume",
  Ice: "icy blue crystal layered magical dress with rich volume",
  Wind: "emerald floral magical dress with flowing petals and rich volume",
  Light: "white and gold divine magical dress with rich volume",
  Dark: "black and purple gothic magical dress with rich volume",
};

/* =========================
   Fixed Weapon (Flux)
========================= */

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
   Wings (Kling only)
========================= */

const wingPrompts = {
  Fire: "flaming phoenix wings, fiercely burning wings",
  Water: "flowing translucent water wings",
  Thunder: "sharp lightning-bolt wings with electric arcs",
  Ice: "symmetrical crystal wings made of reflective ice feathers",
  Wind: "airy feather wings surrounded by petals",
  Light: "radiant angel wings with luminous layers",
  Dark: "symmetrical purple lightning-bolt bat wings",
};

/* =========================
   Flux Prompt
========================= */

function buildFluxPrompt(attribute, hair) {
  const headItem =
    attribute === "Dark"
      ? "long horns of the devil on the head"
      : "tiara with a veil";

  const staff = staffPrompts[attribute];

  return `
cinematic full body shot of a young magical girl,
${headItem},
${hair},
front-facing,
standing upright,
legs together, feet together, stable elegant posture,
holding ${staff} firmly in her one hand,
the weapon is already present and clearly visible,
photorealistic, masterpiece, 8k,
${dressPrompts[attribute]},
${particlePrompts[attribute]},
${locationPrompts[attribute]},
bright cinematic environment lighting
`.trim();
}

/* =========================
   Kling Prompt
========================= */

function buildKlingPrompt(attribute) {
  const wing = wingPrompts[attribute];
  const particle = particlePrompts[attribute];
  const staff = staffPrompts[attribute];

  return `
Start:
The footage begins with a super close-up of her eyes.

She faces the drone camera throughout the entire sequence.
She never turns around.

The drone camera zooms out and pans to capture her full figure.
${particle} must never be removed until the very end.

From 0s to 4s:
A controlled magical energy surge expands gently around her body.
No chaotic explosion. No scene transition.

At 1.5s:
${staff} she holds begins to emit light energy.
The staff must remain visible, long, stable, symmetrical,
and firmly held in her right hand until the end. She never releases it.
The staff's light energy must never fade until the very end.

At 2.5s:
${wing} gently materialize from two attachment points on her upper back.
Both wings must grow directly from her upper back.
Never from the staff. Never from the hands. Never from floating objects.
Both wings must stay attached to her body and aligned.

Camera movement must be smooth. No violent shaking.
Continuous stable 5-second sequence.

From 4s to 5s:
Hold final heroic pose with subtle motion. The staff remains in her hand.
The wings remain attached to her back.

Standing upright only. Legs together. Do not spread them.
Perfect hands with five fingers visible.
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
        "long bright brown hair",
        "long ponytail blonde hair",
        "long ponytail bright brown hair",
      ];

      const randomHair = randomPick(hairOptions);

      /* 1. Flux */
      const fluxPrompt = buildFluxPrompt(attribute, randomHair);

      const imageResponse = await axios.post(
        "https://fal.run/fal-ai/flux-pro/v1.1",
        {
          prompt: fluxPrompt,
          negative_prompt:
            "adult woman, rear view, back facing camera, turning around, wide stance, spread legs, kneeling, sitting, extra fingers, deformed hands, wings",
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
          negative_prompt: `
            broken staff, short staff, shrinking staff, thrown weapon, dropped weapon, detached wings, wings growing from the staff, 
            wings growing from hands, wings growing from floating objects, rear view, back facing camera, turning around, scene transition, 
            fade in, fade out, while sitting, without standing up, kneeling, crouching, jittery camera, violent explosion,
            `.trim(),
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