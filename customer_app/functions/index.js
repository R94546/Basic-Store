// Basic Store — buyurtma bildirishnomalari (Cloud Functions v2).
// Token Firestore `settings/telegram` da (admin kiritadi) — mijoz ilovasida ko'rinmaydi.
const {
  onDocumentCreated,
  onDocumentUpdated,
} = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");
const crypto = require("crypto");

initializeApp();
const db = getFirestore();

function money(n) {
  const s = String(Math.abs(Number(n) || 0));
  let out = "";
  for (let i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 === 0) out += " ";
    out += s[i];
  }
  return out;
}

// Telegram HTML rejimida xavfsiz ko'rsatish uchun maxsus belgilarni qochirish
// (mijoz yuborgan matnga HTML/inektsiya kira olmasligi uchun).
function esc(v) {
  return String(v == null ? "" : v)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}

// Buyurtmaning narxini mahsulot bazasidan qayta hisoblaydi (mijoz narxni
// soxtalashtirmasligi uchun). Mos kelmasa — to'g'rilab, qaytaradi.
async function recomputeOrderTotal(orderRef, o) {
  const items = Array.isArray(o.items) ? o.items : [];
  let subtotal = 0;
  for (const it of items) {
    const qty = Number(it.quantity) || 0;
    let unit = Number(it.price) || 0;
    try {
      if (it.productId) {
        const pdoc = await db.doc(`products/${it.productId}`).get();
        if (pdoc.exists) {
          const p = pdoc.data();
          let serverUnit = Number(p.price) || 0;
          if (p.hasVariants && (it.size || it.color)) {
            const vsnap = await db
              .collection(`products/${it.productId}/variants`)
              .get();
            const v = vsnap.docs
              .map((d) => d.data())
              .find(
                (vr) =>
                  (!it.size || vr.size === it.size) &&
                  (!it.color || vr.color === it.color)
              );
            if (v) serverUnit = (Number(p.price) || 0) + (Number(v.priceModifier) || 0);
          }
          unit = serverUnit; // serverdagi narxga ishonamiz
        }
      }
    } catch (e) {
      console.error("price recompute item error", e);
    }
    subtotal += unit * qty;
  }
  const deliveryFee = Number(o.deliveryFee) || 0;
  const total = subtotal + deliveryFee;
  if (total !== Number(o.total) || subtotal !== Number(o.subtotal)) {
    try {
      await orderRef.update({ subtotal, total, priceCorrected: true });
      console.warn(
        `Order price corrected: client total ${o.total} -> ${total}`
      );
    } catch (e) {
      console.error("price correct update error", e);
    }
    return { ...o, subtotal, total };
  }
  return o;
}

async function getTg() {
  const snap = await db.doc("settings/telegram").get();
  return snap.exists ? snap.data() : null;
}

async function send(token, chatId, text) {
  if (!token || chatId === undefined || chatId === null || chatId === "") return;
  try {
    const res = await fetch(`https://api.telegram.org/bot${token}/sendMessage`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ chat_id: chatId, text, parse_mode: "HTML" }),
    });
    if (!res.ok) console.error("telegram status", res.status, await res.text());
  } catch (e) {
    console.error("telegram send error", e);
  }
}

const STATUS_UZ = {
  pending: "🕐 Kutilmoqda",
  confirmed: "✅ Tasdiqlandi",
  processing: "📦 Tayyorlanmoqda",
  shipped: "🚚 Yo'lda",
  delivered: "✅ Yetkazildi",
  cancelled: "❌ Bekor qilindi",
};

// Telegram initData ni HMAC bilan tekshirib, Firebase custom token beradi.
// Shu orqali Telegram identifikatori ISHONCHLI bo'ladi (initDataUnsafe soxta
// bo'lishi mumkin). Mijoz ilovasi token bilan signInWithCustomToken qiladi.
exports.telegramAuth = onCall(async (req) => {
  const initData = req.data && req.data.initData;
  if (!initData || typeof initData !== "string") {
    throw new HttpsError("invalid-argument", "initData yo'q");
  }
  const cfg = await getTg();
  if (!cfg || !cfg.botToken) {
    throw new HttpsError("failed-precondition", "bot token yo'q");
  }
  // data_check_string + HMAC tekshiruvi (Telegram WebApp spetsifikatsiyasi)
  const params = new URLSearchParams(initData);
  const hash = params.get("hash");
  params.delete("hash");
  const dataCheck = [...params.entries()]
    .map(([k, v]) => `${k}=${v}`)
    .sort()
    .join("\n");
  const secret = crypto
    .createHmac("sha256", "WebAppData")
    .update(cfg.botToken)
    .digest();
  const computed = crypto
    .createHmac("sha256", secret)
    .update(dataCheck)
    .digest("hex");
  if (computed !== hash) {
    throw new HttpsError("permission-denied", "initData imzosi noto'g'ri");
  }
  let user;
  try {
    user = JSON.parse(params.get("user") || "{}");
  } catch (e) {
    user = {};
  }
  if (!user.id) throw new HttpsError("invalid-argument", "user yo'q");
  const uid = `tg_${user.id}`;
  const token = await getAuth().createCustomToken(uid, {
    tgId: String(user.id),
  });
  return { token };
});

// Yangi buyurtma -> do'kon egasiga xabar
exports.onNewOrder = onDocumentCreated("orders/{id}", async (event) => {
  let o = event.data && event.data.data();
  if (!o) return;
  // Narxni serverda qayta hisoblaymiz (soxtalashtirishni oldini olish)
  o = await recomputeOrderTotal(event.data.ref, o);

  const cfg = await getTg();
  if (!cfg || cfg.isEnabled === false || cfg.orderNotifications === false) return;
  if (!cfg.botToken || !cfg.chatId) return;

  const items = (o.items || [])
    .map((i) => `• ${esc(i.name)} ×${esc(i.quantity)} — ${money((i.price || 0) * (i.quantity || 0))}`)
    .join("\n");

  const text =
    `🛍 <b>Yangi buyurtma!</b>\n\n` +
    `👤 ${esc(o.customerName || "-")}` +
    (o.customerUsername ? ` (@${esc(o.customerUsername)})` : "") +
    `\n📞 ${esc(o.customerPhone || "-")}\n` +
    (o.customerAddress ? `📍 ${esc(o.customerAddress)}\n` : "") +
    `\n${items}\n\n` +
    `💰 <b>Jami: ${money(o.total)} so'm</b>`;

  await send(cfg.botToken, cfg.chatId, text);
});

// Holat o'zgarsa -> mijozga xabar (Telegram orqali buyurtma bergan bo'lsa)
exports.onOrderStatus = onDocumentUpdated("orders/{id}", async (event) => {
  const before = event.data && event.data.before.data();
  const after = event.data && event.data.after.data();
  if (!before || !after || before.status === after.status) return;

  const customerChat = after.customerId; // Telegram user id
  if (!customerChat) return;

  const cfg = await getTg();
  if (!cfg || !cfg.botToken) return;

  const label = STATUS_UZ[after.status] || after.status;
  const text =
    `📦 <b>Buyurtmangiz holati yangilandi</b>\n\n${esc(label)}` +
    (after.customerName ? `\n\nRahmat, ${esc(after.customerName)}!` : "");

  await send(cfg.botToken, customerChat, text);
});
