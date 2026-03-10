const { onCall, onRequest, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const axios = require("axios");
const Stripe = require("stripe");
// redeploy for latest Stripe webhook secret

admin.initializeApp();
const db = admin.firestore();

const falApiKey = defineSecret("FAL_SECRET_KEY");
const stripeSecretKey = defineSecret("STRIPE_SECRET_KEY");
const stripeWebhookSecret = defineSecret("STRIPE_WEBHOOK_SECRET");

/* =========================
   Stripe Price Map
========================= */
const PRICE_MAP = {
  "3": {
    priceId: "price_1T94q7C2qeonX89sfddXPUIg",
    credits: 3,
  },
  "10": {
    priceId: "price_1T94rrC2qeonX89s9oIOi8By",
    credits: 10,
  },
  "20": {
    priceId: "price_1T94seC2qeonX89suopuvvxI",
    credits: 20,
  },
};

/* =========================
   Utils
========================= */
function randomPick(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

function getSafeErrorMessage(error) {
  return (
    error?.response?.data?.detail ||
    error?.response?.data?.error ||
    error?.message ||
    "Unknown error"
  );
}

function ensureValidAttribute(attribute) {
  const allowedAttributes = [
    "Fire",
    "Water",
    "Thunder",
    "Ice",
    "Wind",
    "Light",
    "Dark",
  ];

  if (!allowedAttributes.includes(attribute)) {
    throw new HttpsError("invalid-argument", "Invalid attribute.");
  }

  return attribute;
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
  Water:
    "sapphire-colored fold composed of water where time stands still and voluminous rich dress",
  Thunder: "violet and silver sharp-edged magical dress with rich volume",
  Ice: "icy blue crystal layered magical dress with rich volume",
  Wind: "emerald floral magical dress with flowing petals and rich volume",
  Light: "white and gold divine magical dress with rich volume",
  Dark: "black and purple gothic magical dress with rich volume",
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
   Prompt Builders
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
   Video Generation Callable
========================= */
exports.generateTransformationVideo = onCall(
  {
    timeoutSeconds: 540,
    memory: "1GiB",
    secrets: [falApiKey],
    region: "us-central1",
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Login required.");
    }

    const uid = request.auth.uid;
    const rawAttribute = request.data?.attribute ?? "Fire";
    const attribute = ensureValidAttribute(rawAttribute);
    const duration = request.data?.duration ?? 5;

    if (duration !== 5) {
      throw new HttpsError("invalid-argument", "Only 5-second generation is allowed.");
    }

    const userRef = db.collection("users").doc(uid);
    const generationLogRef = db.collection("generationLogs").doc();

    console.log("generateTransformationVideo called:", {
      uid,
      attribute,
      duration,
    });

    let creditReserved = false;

    try {
      await db.runTransaction(async (tx) => {
        const userDoc = await tx.get(userRef);

        if (!userDoc.exists) {
          throw new HttpsError("not-found", "User not found.");
        }

        const credits = userDoc.data().credits || 0;

        if (credits <= 0) {
          throw new HttpsError("failed-precondition", "No credits left.");
        }

        tx.update(userRef, {
          credits: admin.firestore.FieldValue.increment(-1),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        tx.set(generationLogRef, {
          uid,
          attribute,
          duration,
          status: "processing",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      creditReserved = true;
      console.log("Credit decremented:", uid);

      const apiKey = falApiKey.value();

      const hairOptions = [
        "long blonde hair",
        "long bright brown hair",
        "long ponytail blonde hair",
        "long ponytail bright brown hair",
      ];

      const randomHair = randomPick(hairOptions);

      const fluxPrompt = buildFluxPrompt(attribute, randomHair);

      console.log("Calling Flux...");
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
          headers: {
            Authorization: `Key ${apiKey}`,
            "Content-Type": "application/json",
          },
          timeout: 60000,
        }
      );

      const imageUrl = imageResponse?.data?.images?.[0]?.url;

      if (!imageUrl) {
        throw new Error("Flux image URL was not returned.");
      }

      console.log("Flux success:", imageUrl);

      const klingPrompt = buildKlingPrompt(attribute);

      console.log("Calling Kling...");
      const videoResponse = await axios.post(
        "https://fal.run/fal-ai/kling-video/v1.5/pro/image-to-video",
        {
          image_url: imageUrl,
          prompt: klingPrompt,
          duration,
          mode: "high_quality",
          negative_prompt: `
            broken staff, short staff, shrinking staff, thrown weapon, dropped weapon, detached wings,
            wings growing from the staff, wings growing from hands, wings growing from floating objects,
            rear view, back facing camera, turning around, scene transition, fade in, fade out,
            while sitting, without standing up, kneeling, crouching, jittery camera, violent explosion
          `.trim(),
        },
        {
          headers: {
            Authorization: `Key ${apiKey}`,
            "Content-Type": "application/json",
          },
          timeout: 480000,
        }
      );

      const videoUrl = videoResponse?.data?.video?.url;

      if (!videoUrl) {
        throw new Error("Kling video URL was not returned.");
      }

      console.log("Kling success:", videoUrl);

      await generationLogRef.update({
        status: "completed",
        imageUrl,
        videoUrl,
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        videoUrl,
      };
    } catch (error) {
      const errorMessage = getSafeErrorMessage(error);

      console.error(
        "generateTransformationVideo error:",
        JSON.stringify(error?.response?.data || errorMessage, null, 2)
      );

      try {
        await generationLogRef.set(
          {
            uid,
            attribute,
            duration,
            status: "failed",
            error: errorMessage,
            failedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
      } catch (logError) {
        console.error("Failed to write generation log:", logError.message);
      }

      if (creditReserved) {
        try {
          await userRef.update({
            credits: admin.firestore.FieldValue.increment(1),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          console.log("Credit refunded:", uid);
        } catch (refundError) {
          console.error("Failed to refund credit:", refundError.message);
        }
      }

      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError("internal", errorMessage);
    }
  }
);

/* =========================
   Stripe Checkout Session Callable
========================= */
exports.createCheckoutSession = onCall(
  {
    region: "us-central1",
    timeoutSeconds: 120,
    memory: "512MiB",
    secrets: [stripeSecretKey],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Login required.");
    }

    const uid = request.auth.uid;
    const packageKey = String(request.data?.packageKey ?? "");
    const packageInfo = PRICE_MAP[packageKey];

    if (!packageInfo) {
      throw new HttpsError("invalid-argument", "Invalid package selected.");
    }

    try {
      const stripe = new Stripe(stripeSecretKey.value());

      const session = await stripe.checkout.sessions.create({
        mode: "payment",
        line_items: [
          {
            price: packageInfo.priceId,
            quantity: 1,
          },
        ],
        success_url:
          "https://magicalvibe-e3e86.web.app/?payment=success&session_id={CHECKOUT_SESSION_ID}",
        cancel_url:
          "https://magicalvibe-e3e86.web.app/?payment=cancel",
        metadata: {
          uid,
          creditAmount: String(packageInfo.credits),
          packageKey,
        },
      });

      return {
        url: session.url,
      };
    } catch (error) {
      console.error("createCheckoutSession error:", error);
      throw new HttpsError(
        "internal",
        error?.message || "Failed to create checkout session."
      );
    }
  }
);

/* =========================
   Stripe Webhook HTTP Endpoint
========================= */
exports.stripeWebhook = onRequest(
  {
    region: "us-central1",
    timeoutSeconds: 120,
    memory: "512MiB",
    secrets: [stripeSecretKey, stripeWebhookSecret],
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    const stripe = new Stripe(stripeSecretKey.value());
    const signature = req.headers["stripe-signature"];

    let event;

    try {
      event = stripe.webhooks.constructEvent(
        req.rawBody,
        signature,
        stripeWebhookSecret.value()
      );
    } catch (err) {
      console.error("Webhook signature verification failed:", err.message);
      res.status(400).send(`Webhook Error: ${err.message}`);
      return;
    }

    try {
      if (event.type === "checkout.session.completed") {
        const session = event.data.object;

        const uid = session.metadata?.uid;
        const creditAmount = Number(session.metadata?.creditAmount || 0);

        if (!uid || !creditAmount) {
          console.error("Missing uid or creditAmount in metadata.");
          res.status(400).send("Missing metadata.");
          return;
        }

        const eventRef = db.collection("stripeEvents").doc(event.id);
        const userRef = db.collection("users").doc(uid);

        await db.runTransaction(async (tx) => {
          const eventDoc = await tx.get(eventRef);

          if (eventDoc.exists) {
            return;
          }

          const userDoc = await tx.get(userRef);

          if (!userDoc.exists) {
            throw new Error("User not found for Stripe credit grant.");
          }

          tx.set(eventRef, {
            eventId: event.id,
            type: event.type,
            uid,
            creditAmount,
            checkoutSessionId: session.id || null,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          tx.update(userRef, {
            credits: admin.firestore.FieldValue.increment(creditAmount),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        });

        console.log("Credits granted:", {
          uid,
          creditAmount,
          eventId: event.id,
        });
      }

      res.status(200).send("OK");
    } catch (error) {
      console.error("stripeWebhook processing error:", error);
      res.status(500).send("Internal Server Error");
    }
  }
);