// Basic Store — buyurtma bildirishnomalari (Cloud Functions v2).
// Token Firestore `settings/telegram` da (admin kiritadi) — mijoz ilovasida ko'rinmaydi.
const {
  onDocumentCreated,
  onDocumentUpdated,
} = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");

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

// Yangi buyurtma -> do'kon egasiga xabar
exports.onNewOrder = onDocumentCreated("orders/{id}", async (event) => {
  const o = event.data && event.data.data();
  if (!o) return;
  const cfg = await getTg();
  if (!cfg || cfg.isEnabled === false || cfg.orderNotifications === false) return;
  if (!cfg.botToken || !cfg.chatId) return;

  const items = (o.items || [])
    .map((i) => `• ${i.name} ×${i.quantity} — ${money((i.price || 0) * (i.quantity || 0))}`)
    .join("\n");

  const text =
    `🛍 <b>Yangi buyurtma!</b>\n\n` +
    `👤 ${o.customerName || "-"}` +
    (o.customerUsername ? ` (@${o.customerUsername})` : "") +
    `\n📞 ${o.customerPhone || "-"}\n` +
    (o.customerAddress ? `📍 ${o.customerAddress}\n` : "") +
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
    `📦 <b>Buyurtmangiz holati yangilandi</b>\n\n${label}` +
    (after.customerName ? `\n\nRahmat, ${after.customerName}!` : "");

  await send(cfg.botToken, customerChat, text);
});
