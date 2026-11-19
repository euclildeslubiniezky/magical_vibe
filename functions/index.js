const { onCall, onRequest, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const axios = require("axios");
const Stripe = require("stripe");
const nosoundAudioUrl = defineSecret("NOSOUND_AUDIO_URL");

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
    priceId: "price_1T9nBZFxPCtopfZ8gVLO7RWB",
    credits: 3,
  },
  "10": {
    priceId: "price_1T9nBkFxPCtopfZ8gOhZfRnM",
    credits: 10,
  },
  "20": {
    priceId: "price_1T9nBWFxPCtopfZ89KMwpD7i",
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
  Wind: "in the field of many glowing flower forest",
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
  Water: "sapphire-colored fold composed of water where time stands still and voluminous rich dress",
  Thunder: "violet and silver sharp-edged magical dress with rich volume",
  Ice: "icy blue crystal layered magical dress with rich volume",
  Wind: "emerald floral magical dress with flowing petals and rich volume",
  Light: "white and gold divine magical dress with rich volume",
  Dark: "black and purple gothic magical dress with rich volume",
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
  return `
cinematic full body shot of a cute magical woman, approximately 16 years old, front-facing, 
not anime, floating gently above the ground, not colorful long sheer dress (unfinished), 
masterpiece, 8k, soft glowing fantasy lighting, bright cinematic atmosphere, not anime, 
${headItem},
${hair},
${particlePrompts[attribute]},
${locationPrompts[attribute]},
`.trim();
}

function buildMinimaxPrompt(attribute) {
  const wing = wingPrompts[attribute];
  const particle = particlePrompts[attribute];
  const dress = dressPrompts[attribute];
  const staff = staffPrompts[attribute];

  return `
Start:
The footage begins with a close-up of her face.The camera zooms out.
She is already floating gently above the ground when the video starts.

During the transformation,
the camera performs a smooth cinematic 360-degree orbit around her body.
After the orbit, the camera stabilizes in front of her.
${particle} gently surround her during the entire sequence.

From 0s to 4s:
A controlled magical energy surge expands gently around her body.
Her monochrome unfinished dress gradually transforms into gorgeous ${dress}.
The dress transformation is smooth, continuous, elegant, and visually stable.
The final dress becomes fully detailed, fully colored, and visually rich by 4 seconds.
No torn clothes. No broken fabric. No incomplete dress sections.
The transformation remains stable during the entire sequence.

${wing} gently materialize from her upper back.
The ${wing} remain attached to her back at all times.
No ${wing} from hands. No ${wing} from the ${staff}. No floating detached ${wing}.

A single ${staff} materializes near her hand. Only one ${staff} exists. 
She naturally grabs and holds the ${staff} until the end.
The ${staff} emits stable magical light energy.
The ${staff} never floats away. The ${staff} never leaves her hand. No duplicated ${staff}.

From 4s to 5s:
The magical energy around her fades away naturally.
Her become fully visible and clear.
She slowly descends and lands gently on the ground.
She softly looks toward the camera.
A faint gentle smile gradually appears.
Hold a final heroic pose with subtle motion.
Continuous stable 5-second cinematic sequence.

The fully formed wings remain clearly visible,
complete, and attached to her back throughout
the entire final scene.

Do not remove, fade out, hide, or dissolve the wings.
Preserve their shape and structure until the final frame.
`.trim();
}

/* =========================
   Video Generation Callable
========================= */
exports.generateTransformationVideo = onCall(
  {
    timeoutSeconds: 540,
    memory: "1GiB",
    secrets: [falApiKey, nosoundAudioUrl],
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

    let usedFreeTrial = false;   // フリートライアルを使ったか
    let creditConsumed = false;   // 通常 credits を消費したか

    try {
      await db.runTransaction(async (tx) => {
        const userDoc = await tx.get(userRef);

        if (!userDoc.exists) {
          throw new HttpsError("not-found", "User not found.");
        }

        const data = userDoc.data();
        const freeTrialAvailable = data.freeTrialAvailable ?? false;
        const freeTrialUsedAt = data.freeTrialUsedAt ?? null;

        if (freeTrialAvailable === true && freeTrialUsedAt === null) {
          // === 無料トライアル消費 ===
          usedFreeTrial = true;
          tx.update(userRef, {
            freeTrialAvailable: false,
            freeTrialUsedAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        } else {
          // === 通常 credits 消費 ===
          const credits = data.credits || 0;
          if (credits <= 0) {
            throw new HttpsError("failed-precondition", "No credits left.");
          }
          creditConsumed = true;
          tx.update(userRef, {
            credits: admin.firestore.FieldValue.increment(-1),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }

        tx.set(generationLogRef, {
          uid,
          attribute,
          duration,
          status: "processing",
          usedFreeTrial,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      console.log(
        usedFreeTrial ? "Free trial consumed:" : "Credit decremented:",
        uid
      );

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
        "https://fal.run/microsoft/mai-image-2.7/flash/text-to-image",
        {
          prompt: fluxPrompt,
          // negative_prompt: `
          //       adult woman, extra fingers, deformed hands
          //   `.trim(),
          image_size: "portrait_16_9",
          resolution: "1K",
        },
        {
          headers: {
            Authorization: `Key ${apiKey}`,
            "Content-Type": "application/json",
          },
          timeout: 120000,
        }
      );

      const imageUrl = imageResponse?.data?.images?.[0]?.url;

      if (!imageUrl) {
        throw new Error("Flux image URL was not returned.");
      }

      console.log("Flux success:", imageUrl);

      const minimaxPrompt = buildMinimaxPrompt(attribute);

      console.log("Calling MiniMax H3 Turbo...");
      const videoResponse = await axios.post(
        "https://fal.run/minimax/h3-max-turbo/image-to-video",
        {
          image_url: imageUrl,
          prompt: minimaxPrompt,
          duration,
          resolution: "1080P",
          prompt_expansion_mode: "quality",
          enable_safety_checker: true,
          target_audio_url: nosoundAudioUrl.value(),
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
        throw new Error("MiniMax video URL was not returned.");
      }

      console.log("MiniMax success:", videoUrl);

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

      if (creditConsumed) {
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
    console.log("createCheckoutSession called:", {
      hasAuth: !!request.auth,
      uid: request.auth?.uid || null,
      packageKey: request.data?.packageKey || null,
    });

    if (!request.auth) {
      console.error("createCheckoutSession unauthenticated request");
      throw new HttpsError("unauthenticated", "Login required.");
    }

    const uid = request.auth.uid;
    const packageKey = String(request.data?.packageKey ?? "");
    const packageInfo = PRICE_MAP[packageKey];

    if (!packageInfo) {
      console.error("Invalid packageKey:", packageKey);
      throw new HttpsError("invalid-argument", "Invalid package selected.");
    }

    try {
      const secret = stripeSecretKey.value();
      console.log("Stripe secret present:", !!secret);

      const stripe = new Stripe(secret);

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

      console.log("Checkout session created:", {
        uid,
        packageKey,
        priceId: packageInfo.priceId,
        sessionId: session.id,
        hasUrl: !!session.url,
      });

      return {
        url: session.url,
      };
    } catch (error) {
      console.error("createCheckoutSession error full:", {
        message: error?.message || null,
        type: error?.type || null,
        code: error?.code || null,
        rawType: error?.rawType || null,
        statusCode: error?.statusCode || null,
        raw: error?.raw || null,
      });

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

    console.log("stripeWebhook received:", {
      eventId: event.id,
      eventType: event.type,
    });

    try {
      if (event.type === "checkout.session.completed") {
        const session = event.data.object;

        const uid = session.metadata?.uid;
        const creditAmount = Number(session.metadata?.creditAmount || 0);

        console.log("checkout.session.completed metadata:", {
          uid,
          creditAmount,
          sessionId: session.id || null,
        });

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
            console.log("Stripe event already processed:", event.id);
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
      console.error("stripeWebhook processing error:", {
        message: error?.message || null,
        stack: error?.stack || null,
      });
      res.status(500).send("Internal Server Error");
    }
  }
);