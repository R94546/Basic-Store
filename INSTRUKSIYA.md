# Basic Store — To'liq Qo'llanma (Instruksiya)

> Kiyim do'koni uchun avtomatlashtirish tizimi. Bu hujjat — do'kon egasi va
> sotuvchilar uchun **noldan** o'rganish qo'llanmasi. Hech qanday texnik bilim
> talab qilinmaydi.

---

## 1. Tizim nima va nimadan iborat?

Basic Store — bu **ikkita ilovadan** iborat yagona tizim. Ikkalasi bitta
umumiy bazada (Firebase) ishlaydi, ya'ni bir ilovada qilingan o'zgarish
ikkinchisida darhol ko'rinadi.

| Ilova | Kim uchun | Qayerda ishlaydi |
|-------|-----------|------------------|
| **Admin (Kassa) ilovasi** | Do'kon egasi va sotuvchilar | Windows kompyuter (`.exe`) yoki brauzer: **basicstore-admin.web.app** |
| **Mijoz ilovasi** | Xaridorlar | Brauzer: **zara-shop-automation-uz.web.app** va **Telegram** (@Basics\_StoreBot) |

**Admin ilova** bilan: tovar kiritish (prixod), sotuv (kassa), mijozlar,
nasiya, kassa smenasi, hisobotlar, buyurtmalar boshqariladi.

**Mijoz ilovasi** bilan: xaridor tovarlarni ko'radi, savatga soladi, buyurtma
beradi (yetkazib berish manzilini xaritadan tanlab).

> 📷 *[Skrinshot 1: Admin ilova bosh ekrani (Dashboard) — chap tomonda menyu]*

---

## 2. O'rnatish

### 2.1. Admin ilovani do'kon kompyuteriga o'rnatish (tavsiya etiladi)

1. `BasicStorePOS-Setup.exe` faylini do'kon kompyuteriga ko'chiring
   (USB yoki Telegram orqali).
2. Ustiga ikki marta bosing → **"Ha"** (administrator ruxsati).
3. O'rnatilgach ish stolida **"Basic Store POS"** yorlig'i paydo bo'ladi.
4. Ochib, tizimga kiring (pastda 3.1-bo'lim).

> Visual Studio yoki boshqa dastur kerak emas — hamma narsa setup ichida.
> Internet bo'lishi shart (baza bulutda).

### 2.2. Brauzerda ishlatish (o'rnatishsiz)

Istalgan kompyuter/telefon brauzeridan **basicstore-admin.web.app** ni oching.
Bir xil login bilan kiriladi. (Lekin USB printer va skanerga jim chop etish
faqat o'rnatilgan `.exe` versiyada to'liq ishlaydi.)

---

## 3. Birinchi ishga tushirish (sozlash)

### 3.1. Tizimga kirish

- **Login:** `admin@basicstore.uz`
- **Parol:** `BSjyWM4n87!9`

> 📷 *[Skrinshot 2: Login ekrani]*

### 3.2. Printerni ulash (yorliq/etiketka printeri)

1. Yorliq printerini (termal etiketka printeri) kompyuterga USB orqali ulang.
2. Windows'ga printer drayverini o'rnating.
3. **Muhim (bir marta):** Windows → **Parametrlar → Printerlar → [printeringiz]
   → Chop etish sozlamalari** da qog'oz o'lchamini **40 × 30 mm** qiling va
   media turini **"Gap / Etiketka"** qiling.
4. Printerni **kalibrlang**: printerni o'chiring → **FEED** tugmasini bosib
   turib yoqing → 1-2 ta yorliq chiqib, indikator chaqnaguncha ushlang → qo'yib
   yuboring. (Bu yorliq uzunligini sozlaydi — bo'sh yorliq chiqmasligi uchun.)
5. Ilovada: **Sozlamalar → Printer** → ro'yxatdan printeringizni tanlang.
   "Birka o'lchami" **40 × 30** turibdimi tekshiring.

> 📷 *[Skrinshot 3: Sozlamalar → Printer oynasi]*

### 3.3. Skanerni ulash

- **Simsiz (2.4GHz):** quticha ichidagi kichik **USB qabul qilgichni (dongle)**
  kompyuterga uling — u darhol ishlaydi (drayver kerak emas).
- Skaner klaviatura sifatida ishlaydi: kodni "yozadi" + Enter. Qo'shimcha
  sozlash shart emas.

### 3.4. Telegram bildirishnomalarini ulash (ixtiyoriy)

Yangi buyurtma kelganda Telegramingizga xabar kelishi uchun:
1. Telegram'da **@BotFather** dan bot yarating, tokenini oling.
2. **@userinfobot** dan o'zingizning **Chat ID**ingizni oling.
3. Ilovada: **Sozlamalar → Telegram bot** → token va Chat ID ni kiriting →
   **Saqlash** → **Test** bosib tekshiring.

> 📷 *[Skrinshot 4: Sozlamalar → Telegram bot oynasi]*

---

## 4. Kundalik ish oqimlari

### 4.1. PRIXOD — tovar kiritish (eng muhim, bitta oyna)

Chap menyudan **Sklad → "Prixod"** tugmasini bosing (yoki to'g'ridan-to'g'ri
Prixod ekranini oching). Bu **bitta tezkor oyna**:

1. Yuqoridagi maydonga **skanerlang** yoki **nom/narx bo'yicha qidiring**
   (masalan `Fut 200` — 200 so'mlik futbolkalar).
2. **Tovar topilsa:** sonini kiriting → **"Qabul qilish va birka chop etish"**.
   Variantli tovar bo'lsa (o'lcham/rang) — har biriga soni.
3. **Topilmasa (yangi tovar):** **"Yangi tovar qo'shish"** → nom, kategoriya,
   kelish narxi, sotish narxi, soni → saqlang. Birka avtomatik chiqadi.
4. O'ng tomonda **shu seansda qilinganlar logi** va **jami summa** ko'rinadi.
5. Chiqqan yorliqlarni tovarlarga yopishtirib, skladga joylang.

> 💡 Prixod jarayoni: do'kon yopiladi → pachka ochiladi → dona sanaladi →
> kassada birka generatsiya + print → yopishtirib skladga.

> 📷 *[Skrinshot 5: Prixod oynasi — chapda qabul paneli, o'ngda seans logi]*

### 4.2. KASSA (POS) — sotuv

Chap menyudan **Kassa** ni oching.

1. **Smena ochiq bo'lishi shart** (o'ng yuqorida "Smena" tugmasi **yashil**
   bo'lsa — ochiq). Qizil bo'lsa, bosib smenani oching (pastda 4.3).
2. Tovarni **skanerlang** yoki qidiring/bosing → savatga tushadi.
   - Variantli tovar skanerlansa — **o'lcham/rang tanlash** oynasi ochiladi.
   - Agar shtrix biriktirilmagan bo'lsa — **"shtrixni tovarga biriktirish"**
     oynasi chiqadi (mavjud tovarga bog'lang yoki yangi tovar qo'shing).
3. O'ng tomonda **savat** (Chek). Bir vaqtda bir nechta chek ochish mumkin.
4. **ОПЛАТА (To'lov)** bosing → to'lov usulini tanlang:
   - **Naqd**, **Karta**, **Nasiya (qarz)** — yoki **aralash** (bir qismini
     naqd, bir qismini karta...).
   - **Nasiya** bo'lsa: mijozni **bazadan tanlang** yoki yangi mijoz + telefon
     kiriting.
5. Tasdiqlang → sotuv saqlanadi, chek chop etiladi (printer sozlangan bo'lsa).

> 📷 *[Skrinshot 6: Kassa (POS) — chapda tovarlar, o'ngda savat va to'lov]*

### 4.3. SMENA (kassa smenasi) — Kassa ichida

Kassa ekranida o'ng yuqoridagi **"Smena"** tugmasini bosing:

- **Ochish:** boshlang'ich naqd summani kiriting.
- Smena davomida: **Naqd/Karta/Nasiya savdo** va **sotuvlar soni** jonli
  ko'rinadi. Kerak bo'lsa **Kirim/Chiqim** (naqd qo'shish/olish) qiling.
- **Yopish:** sanagan naqd summani kiriting → **kutilgan naqd** va **farq**
  ko'rsatiladi. Farq 0 bo'lsa — hammasi to'g'ri.

> 📷 *[Skrinshot 7: Smena boshqaruvi oynasi]*

### 4.4. Boshqa bo'limlar

| Bo'lim | Nima qiladi |
|--------|-------------|
| **Sklad (Ombor)** | Barcha tovarlar ro'yxati, tahrirlash, yorliq chop etish, skanerlab shtrix biriktirish |
| **Mijozlar** | Mijozlar bazasi, telefon, nasiya (qarz) qoldiqlari |
| **Buyurtmalar** | Mijoz ilovasidan kelgan online buyurtmalar. Holatini o'zgartiring (Tasdiqlandi → ... → **Yetkazildi**). "Yetkazildi" qilinganda sotuv hisobotga tushadi. |
| **Chegirmalar** | Tovarlarga chegirma foizi |
| **Sotuvlar tarixi** | Barcha sotuvlar; **sana bo'yicha filtr**; chek tafsilotlari |
| **Hisobotlar (Analitika)** | Tushum (oborot), Foyda, **Foyda foizi (marja)**, chegirmalar, to'lov turlari va kategoriyalar bo'yicha diagrammalar, haftalik grafik, top mahsulotlar |
| **Jurnal (Loglar)** | Kim, qachon, nima qildi (sotuv, prixod, shtrix biriktirish, smena, tovar o'zgarishi) — vaqti bilan |
| **Kategoriyalar** | Kategoriyalar; har birida tovar soni |
| **Sozlamalar** | Til (UZ/RU), Printer, Telegram bot |

> 📷 *[Skrinshot 8: Analitika — KPI kartalar va diagrammalar]*
> 📷 *[Skrinshot 9: Jurnal (Loglar) ekrani]*
> 📷 *[Skrinshot 10: Buyurtmalar ekrani]*

---

## 5. Mijoz ilovasi (xaridorlar uchun)

**zara-shop-automation-uz.web.app** yoki Telegram **@Basics\_StoreBot** →
menyu tugmasi.

1. Xaridor tovarlarni ko'radi (bosh sahifa, kategoriyalar, qidiruv).
2. Tovarni ochib **o'lcham/rang** tanlaydi → **savatga** qo'shadi.
3. **Buyurtma berish** (checkout): ism, **+998 telefon**, manzil —
   **"Xaritadan tanlash"** bilan aniq nuqtani belgilaydi.
4. Buyurtma beradi → do'kon egasiga Telegram xabar keladi.
5. Xaridor **Profil → Buyurtmalarim** da holatini kuzatadi.

> 📷 *[Skrinshot 11: Mijoz ilovasi — bosh sahifa]*
> 📷 *[Skrinshot 12: Checkout — xaritadan manzil tanlash]*

---

## 6. Apparat (qurilmalar)

- **Skaner:** Global POS GP-9400B (2D, simsiz — Bluetooth/2.4GHz/USB). USB
  dongle bilan ishlatish eng oson.
- **Printer:** termal **yorliq (etiketka)** printeri — mahsulot shtrix-
  yorliqlarini chop etadi. 40×30 mm yorliq + kalibrlash (3.2-bo'lim).

> ⚠️ Bu **chek printeri emas** — 80mm kassa cheki uchun alohida chek printeri
> kerak bo'ladi. Hozircha chek shu yorliq printeriga chiqmasligi mumkin.

---

## 7. Prezentatsiyaga tayyorlik bahosi

**Umumiy tayyorlik: ~85%** — asosiy biznes jarayonlari to'liq ishlaydi va
jonli (live) holatda.

### ✅ Tayyor va ishlaydi
- To'liq POS (sotuv, aralash to'lov, nasiya, bir nechta chek)
- Bitta-oyna Prixod + yorliq chop etish + skaner
- Kassa smenasi (ochish/yopish, kirim/chiqim, naqd hisobi to'g'ri)
- Mijozlar, nasiya, kategoriyalar, sotuvlar tarixi (sana filtri bilan)
- Analitika (oborot, foyda, marja, diagrammalar) va Dashboard
- Jurnal (audit log) — barcha amallar vaqti bilan
- Online buyurtmalar → "Yetkazildi" da hisobotga tushadi
- Mijoz ilovasi + Telegram Mini App + xaritadan manzil
- **Xavfsizlik:** buyurtmalar faqat egasi/adminga ko'rinadi; narx serverda
  tekshiriladi; Telegram identifikatori HMAC bilan tasdiqlanadi

### ⚠️ Kamchiliklar / keyingi ishlar
1. **Chek printeri** — hozir faqat yorliq printeri bor. 80mm kassa cheki uchun
   alohida printer kerak.
2. **App Check** (Firebase) hali yoqilmagan — skript orqali suiiste'molni
   bloklash uchun Console'da reCAPTCHA sozlash kerak.
3. **Prixodda** mavjud variantli tovarga **yangi o'lcham/variant** qo'shish
   hozircha faqat Ombor orqali.
4. Mijoz ilovasida yetkazib berish narxi masofaga qarab emas, sobit (25 000,
   500 000 dan yuqorida bepul).
5. Ko'p foydalanuvchi (bir nechta sotuvchi) uchun alohida loginlar hali yo'q
   (bitta admin login).

---

## 8. Tez-tez uchraydigan savollar

**Skan qilganda "topilmadi" chiqyapti.**
Tovarga shu shtrix biriktirilmagan. Chiqqan oynada mavjud tovarga biriktiring
yoki "Yangi tovar" qo'shing. Keyingi safar to'g'ridan-to'g'ri topiladi.

**Yorliq bo'sh chiqyapti / shtrix o'qilmayapti.**
Printer drayverida qog'oz 40×30 qilinganini va printer **kalibrlangan**ini
tekshiring (3.2-bo'lim).

**Online sotuv hisobotда ko'rinmayapti.**
Buyurtmani **"Yetkazildi"** holatiga o'tkazing — shunda sotuv hisobga olinadi.

**Sklad qiymati qanday hisoblanadi?**
Tovarlar **kelish (tan) narxi** × qoldiq bo'yicha (kelish narxi yo'q bo'lsa —
sotish narxidan).

---

*Basic Store — © 2026. Savollar bo'lsa do'kon administratori bilan bog'laning.*
