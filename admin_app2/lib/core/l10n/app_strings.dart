/// UZ/RU tarjimalar lug'ati. Kalit -> {uz, ru}.
class AppStrings {
  static const Map<String, Map<String, String>> values = {
    // ===== Sidebar / navigatsiya =====
    'nav.dashboard': {'uz': 'Boshqaruv', 'ru': 'Главная'},
    'nav.warehouse': {'uz': 'Sklad', 'ru': 'Склад'},
    'nav.stockin': {'uz': 'Prixod', 'ru': 'Приход'},
    'nav.pos': {'uz': 'Kassa', 'ru': 'Касса'},
    'nav.session': {'uz': 'Kassa smenasi', 'ru': 'Смена кассы'},
    'nav.orders': {'uz': 'Buyurtmalar', 'ru': 'Заказы'},
    'nav.discount': {'uz': 'Chegirma', 'ru': 'Скидки'},
    'nav.sales': {'uz': 'Savdo tarixi', 'ru': 'История продаж'},
    'nav.reports': {'uz': 'Hisobotlar', 'ru': 'Отчёты'},
    'nav.categories': {'uz': 'Kategoriyalar', 'ru': 'Категории'},
    'nav.settings': {'uz': 'Sozlamalar', 'ru': 'Настройки'},

    // ===== Umumiy =====
    'common.add': {'uz': "Qo'shish", 'ru': 'Добавить'},
    'common.edit': {'uz': 'Tahrirlash', 'ru': 'Изменить'},
    'common.delete': {'uz': "O'chirish", 'ru': 'Удалить'},
    'common.save': {'uz': 'Saqlash', 'ru': 'Сохранить'},
    'common.cancel': {'uz': 'Bekor', 'ru': 'Отмена'},
    'common.confirm': {'uz': 'Tasdiqlash', 'ru': 'Подтвердить'},
    'common.close': {'uz': 'Yopish', 'ru': 'Закрыть'},
    'common.search': {'uz': 'Qidirish', 'ru': 'Поиск'},
    'common.total': {'uz': 'Jami', 'ru': 'Итого'},
    'common.sum': {'uz': "so'm", 'ru': 'сум'},
    'common.qty': {'uz': 'Soni', 'ru': 'Кол-во'},
    'common.price': {'uz': 'Narx', 'ru': 'Цена'},
    'common.name': {'uz': 'Nomi', 'ru': 'Название'},
    'common.category': {'uz': 'Kategoriya', 'ru': 'Категория'},
    'common.all': {'uz': 'Barchasi', 'ru': 'Все'},
    'common.empty': {'uz': "Bo'sh", 'ru': 'Пусто'},
    'common.notFound': {'uz': 'Topilmadi', 'ru': 'Не найдено'},
    'common.loading': {'uz': 'Yuklanmoqda...', 'ru': 'Загрузка...'},
    'common.today': {'uz': 'Bugun', 'ru': 'Сегодня'},
    'common.print': {'uz': 'Chop etish', 'ru': 'Печать'},
    'common.note': {'uz': 'Izoh', 'ru': 'Заметка'},
    'common.success': {'uz': 'Muvaffaqiyatli', 'ru': 'Успешно'},
    'common.error': {'uz': 'Xatolik', 'ru': 'Ошибка'},

    // ===== Tovar =====
    'product.buyPrice': {'uz': 'Kelish narxi', 'ru': 'Цена прихода'},
    'product.sellPrice': {'uz': 'Sotish narxi', 'ru': 'Цена продажи'},
    'product.barcode': {'uz': 'Shtrix kod', 'ru': 'Штрих-код'},
    'product.stock': {'uz': 'Qoldiq', 'ru': 'Остаток'},
    'product.size': {'uz': "O'lcham", 'ru': 'Размер'},
    'product.color': {'uz': 'Rang', 'ru': 'Цвет'},
    'product.variants': {'uz': 'Variantlar', 'ru': 'Варианты'},
    'product.image': {'uz': 'Rasm', 'ru': 'Фото'},
    'product.discount': {'uz': 'Chegirma', 'ru': 'Скидка'},
    'product.new': {'uz': "Yangi tovar", 'ru': 'Новый товар'},
    'product.lowStock': {'uz': 'Kam qolgan', 'ru': 'Заканчивается'},
    'product.outOfStock': {'uz': "Tugagan", 'ru': 'Нет в наличии'},
    'product.generateBarcode': {
      'uz': 'Shtrix kod generatsiya',
      'ru': 'Сгенерировать штрих-код'
    },
    'product.printLabel': {'uz': 'Yorliq chop etish', 'ru': 'Печать этикетки'},
    'product.scan': {'uz': 'Skanerlash', 'ru': 'Сканировать'},

    // ===== Kassa (POS) =====
    'pos.title': {'uz': 'Kassa', 'ru': 'Касса'},
    'pos.searchHint': {
      'uz': 'Qidirish yoki shtrix kodni skaner qiling...',
      'ru': 'Поиск или сканируйте штрих-код...'
    },
    'pos.cart': {'uz': 'Savat', 'ru': 'Корзина'},
    'pos.check': {'uz': 'Chek', 'ru': 'Чек'},
    'pos.pay': {'uz': "TO'LASH", 'ru': 'ОПЛАТА'},
    'pos.payment': {'uz': "To'lov", 'ru': 'Оплата'},
    'pos.payable': {'uz': 'To\'lanadigan summa', 'ru': 'К оплате'},
    'pos.cash': {'uz': 'Naqd', 'ru': 'Наличные'},
    'pos.card': {'uz': 'Karta', 'ru': 'Карта'},
    'pos.debt': {'uz': 'Qarz', 'ru': 'Долг'},
    'pos.mixed': {'uz': 'Aralash', 'ru': 'Смешанная'},
    'pos.received': {'uz': 'Olingan', 'ru': 'Получено'},
    'pos.change': {'uz': 'Qaytim', 'ru': 'Сдача'},
    'pos.remaining': {'uz': 'Qoldi', 'ru': 'Осталось'},
    'pos.exact': {'uz': 'Aniq', 'ru': 'Точно'},
    'pos.customer': {'uz': 'Mijoz ismi', 'ru': 'Имя клиента'},
    'pos.outOfStockMsg': {
      'uz': 'Omborda yetarli emas',
      'ru': 'Недостаточно на складе'
    },
    'pos.chooseVariant': {'uz': 'Variantni tanlang', 'ru': 'Выберите вариант'},
    'pos.paid': {'uz': "to'landi", 'ru': 'оплачено'},
    'pos.noSession': {
      'uz': 'Avval kassa smenasini oching!',
      'ru': 'Сначала откройте смену кассы!'
    },

    // ===== Prixod =====
    'stockin.title': {'uz': 'Prixod (tovar kelishi)', 'ru': 'Приход товара'},
    'stockin.new': {'uz': 'Yangi prixod', 'ru': 'Новый приход'},
    'stockin.supplier': {'uz': 'Yetkazib beruvchi', 'ru': 'Поставщик'},
    'stockin.qtyIncoming': {'uz': 'Kelgan soni', 'ru': 'Поступило'},
    'stockin.history': {'uz': 'Prixod tarixi', 'ru': 'История прихода'},
    'stockin.todayTotal': {'uz': 'Bugungi prixod', 'ru': 'Приход за сегодня'},
    'stockin.pickProduct': {
      'uz': 'Avval tovarni tanlang',
      'ru': 'Сначала выберите товар'
    },
    'stockin.fillQtyPrice': {
      'uz': "Soni va kelish narxini to'ldiring",
      'ru': 'Заполните кол-во и цену прихода'
    },
    'stockin.byVariant': {
      'uz': 'Variantlar bo\'yicha qabul',
      'ru': 'Приём по вариантам'
    },
    'stockin.perPieceLabels': {
      'uz': 'Har dona uchun alohida etiketka (aks holda — 1 ta)',
      'ru': 'Этикетка на каждую штуку (иначе — 1 шт.)'
    },

    // ===== Etiketka / Asboblar =====
    'label.copies': {'uz': 'Nusxa', 'ru': 'Копии'},
    'form.barcodeAuto': {'uz': '(avtomatik)', 'ru': '(авто)'},
    'tools.normalizeBarcodes': {
      'uz': 'Shtrixlarni tartiblash',
      'ru': 'Упорядочить штрих-коды'
    },
    'tools.normalizeBarcodesShort': {
      'uz': "Bo'sh/takroriy shtrixlarni to'g'rilash",
      'ru': 'Исправить пустые/повторяющиеся'
    },
    'tools.normalizeBarcodesDesc': {
      'uz': "Shtrixi bo'sh yoki takrorlangan barcha tovar va variantlarga yangi "
          "unikal ichki shtrix beriladi. Mavjud to'g'ri shtrixlar saqlanadi.",
      'ru': 'Всем товарам и вариантам с пустым или повторяющимся штрих-кодом '
          'будет присвоен новый уникальный внутренний код. Корректные коды '
          'сохранятся.'
    },
    'tools.normalizeDone': {
      'uz': "Yangilangan SKU'lar soni",
      'ru': 'Обновлено SKU'
    },

    // ===== Smena =====
    'session.title': {'uz': 'Kassa smenasi', 'ru': 'Смена кассы'},
    'session.open': {'uz': 'Smena ochish', 'ru': 'Открыть смену'},
    'session.close': {'uz': 'Smena yopish', 'ru': 'Закрыть смену'},
    'session.openingCash': {'uz': 'Boshlang\'ich naqd', 'ru': 'Начальная касса'},
    'session.closingCash': {'uz': 'Sanab chiqilgan naqd', 'ru': 'Подсчитано'},
    'session.expected': {'uz': 'Kutilgan naqd', 'ru': 'Ожидаемая касса'},
    'session.difference': {'uz': 'Farq', 'ru': 'Разница'},
    'session.cashIn': {'uz': 'Kirim', 'ru': 'Внести'},
    'session.cashOut': {'uz': 'Chiqim', 'ru': 'Изъять'},
    'session.cashSales': {'uz': 'Naqd savdo', 'ru': 'Наличные продажи'},
    'session.reason': {'uz': 'Sababi', 'ru': 'Причина'},
    'session.open.status': {'uz': 'Smena ochiq', 'ru': 'Смена открыта'},
    'session.closed.status': {'uz': 'Smena yopiq', 'ru': 'Смена закрыта'},
    'session.openedAt': {'uz': 'Ochilgan', 'ru': 'Открыта'},

    // ===== Dashboard / Hisobot =====
    'dash.todaySales': {'uz': 'Bugungi savdo', 'ru': 'Продажи сегодня'},
    'dash.salesCount': {'uz': 'Savdolar soni', 'ru': 'Кол-во продаж'},
    'dash.avgCheck': {'uz': "O'rtacha chek", 'ru': 'Средний чек'},
    'dash.profit': {'uz': 'Foyda', 'ru': 'Прибыль'},
    'dash.revenue': {'uz': 'Tushum', 'ru': 'Выручка'},
    'dash.topProducts': {'uz': 'Top mahsulotlar', 'ru': 'Топ товары'},
    'dash.stockValue': {'uz': 'Sklad qiymati', 'ru': 'Стоимость склада'},
    'dash.lowStock': {'uz': 'Kam qolgan tovarlar', 'ru': 'Заканчиваются'},
    'report.weekly': {'uz': 'Haftalik savdo', 'ru': 'Продажи за неделю'},
    'report.byCategory': {'uz': 'Kategoriya bo\'yicha', 'ru': 'По категориям'},
    'report.byPayment': {'uz': 'To\'lov turi bo\'yicha', 'ru': 'По типу оплаты'},
    'report.period': {'uz': 'Davr', 'ru': 'Период'},

    // ===== Buyurtmalar (zaglushka) =====
    'orders.dev': {
      'uz': "Ishlab chiqilmoqda",
      'ru': 'На этапе разработки'
    },
    'orders.devDesc': {
      'uz': 'Bu bo\'lim tez kunda ishga tushadi',
      'ru': 'Этот раздел скоро будет доступен'
    },
    'orders.openMap': {
      'uz': 'Xaritada ochish',
      'ru': 'Открыть на карте'
    },

    // ===== Shtrix biriktirish (skanerlab) =====
    'bind.title': {
      'uz': 'Shtrixni mahsulotga biriktirish',
      'ru': 'Привязать штрих-код к товару'
    },
    'bind.hint': {
      'uz': 'Bu shtrix bazada yo\'q. Qaysi mahsulotga biriktiramiz?',
      'ru': 'Этого штрих-кода нет в базе. К какому товару привязать?'
    },
    'bind.hasVariants': {
      'uz': 'Variantli — keyin o\'lcham/rang tanlanadi',
      'ru': 'С вариантами — далее выбор размера/цвета'
    },
    'bind.done': {
      'uz': 'Shtrix biriktirildi va savatga qo\'shildi',
      'ru': 'Штрих-код привязан и добавлен в корзину'
    },

    // ===== Buyurtmalar (mijoz buyurtmalari) =====
    'ordersAdmin.new': {'uz': 'Yangi', 'ru': 'Новые'},
    'ordersAdmin.active': {'uz': 'Faol', 'ru': 'Активные'},
    'ordersAdmin.completed': {'uz': 'Yakunlangan', 'ru': 'Завершённые'},
    'ordersAdmin.changeStatus': {
      'uz': 'Holatni o\'zgartirish',
      'ru': 'Изменить статус'
    },
    'ordersAdmin.empty': {
      'uz': 'Buyurtmalar yo\'q',
      'ru': 'Заказов нет'
    },
    'ordersAdmin.items': {'uz': 'Mahsulotlar', 'ru': 'Товары'},
    'ordersAdmin.phone': {'uz': 'Telefon', 'ru': 'Телефон'},
    'ordersAdmin.address': {'uz': 'Manzil', 'ru': 'Адрес'},
    'ordersAdmin.statusUpdated': {
      'uz': 'Holat yangilandi',
      'ru': 'Статус обновлён'
    },

    // ===== Buyurtma holatlari =====
    'orderStatus.pending': {'uz': 'Kutilmoqda', 'ru': 'Ожидает'},
    'orderStatus.confirmed': {'uz': 'Tasdiqlandi', 'ru': 'Подтверждён'},
    'orderStatus.processing': {'uz': 'Tayyorlanmoqda', 'ru': 'В обработке'},
    'orderStatus.shipped': {'uz': 'Yetkazilmoqda', 'ru': 'Доставляется'},
    'orderStatus.delivered': {'uz': 'Yetkazildi', 'ru': 'Доставлен'},
    'orderStatus.cancelled': {'uz': 'Bekor qilindi', 'ru': 'Отменён'},

    // ===== Nasiya / Mijozlar =====
    'nav.clients': {'uz': 'Nasiyalar', 'ru': 'Долги'},
    'clients.title': {'uz': 'Mijozlar va nasiyalar', 'ru': 'Клиенты и долги'},
    'clients.new': {'uz': 'Yangi mijoz', 'ru': 'Новый клиент'},
    'clients.name': {'uz': 'Mijoz ismi', 'ru': 'Имя клиента'},
    'clients.phone': {'uz': 'Telefon', 'ru': 'Телефон'},
    'clients.address': {'uz': 'Manzil', 'ru': 'Адрес'},
    'clients.totalDebt': {'uz': 'Umumiy qarz', 'ru': 'Общий долг'},
    'clients.outstanding': {'uz': 'Qaytarilmagan qarz', 'ru': 'Непогашенный долг'},
    'clients.noDebt': {'uz': 'Qarzi yo\'q', 'ru': 'Нет долгов'},
    'clients.debts': {'uz': 'Qarzlar', 'ru': 'Долги'},
    'debt.amount': {'uz': 'Qarz summasi', 'ru': 'Сумма долга'},
    'debt.paid': {'uz': "To'langan", 'ru': 'Оплачено'},
    'debt.remaining': {'uz': 'Qoldiq', 'ru': 'Остаток'},
    'debt.pay': {'uz': "To'lov qilish", 'ru': 'Внести оплату'},
    'debt.dueDate': {'uz': 'Muddati', 'ru': 'Срок'},
    'debt.overdue': {'uz': 'Muddati o\'tgan', 'ru': 'Просрочен'},
    'debt.fromSale': {'uz': 'Savdo', 'ru': 'Продажа'},

    // ===== Sozlamalar =====
    'settings.language': {'uz': 'Til', 'ru': 'Язык'},
    'settings.printer': {'uz': 'Printer', 'ru': 'Принтер'},
    'settings.store': {'uz': "Do'kon ma'lumotlari", 'ru': 'Данные магазина'},
    'settings.printerSettings': {
      'uz': 'Printer sozlamalari',
      'ru': 'Настройки принтера'
    },
    'settings.notConfigured': {'uz': 'Sozlanmagan', 'ru': 'Не настроено'},
    'settings.storeSubtitle': {
      'uz': 'Nomi, manzil, telefon',
      'ru': 'Название, адрес, телефон'
    },
    'settings.comingSoon': {
      'uz': "Tez orada qo'shiladi...",
      'ru': 'Скоро будет добавлено...'
    },
    'settings.telegramBot': {'uz': 'Telegram bot', 'ru': 'Telegram бот'},
    'settings.active': {'uz': 'Faol ✓', 'ru': 'Активен ✓'},
    'settings.disabled': {'uz': "O'chirilgan", 'ru': 'Отключён'},
    'settings.staff': {'uz': 'Xodimlar', 'ru': 'Сотрудники'},
    'settings.staffSubtitle': {
      'uz': 'Foydalanuvchilar boshqaruvi',
      'ru': 'Управление пользователями'
    },
    'settings.backup': {'uz': 'Zaxira nusxa', 'ru': 'Резервная копия'},
    'settings.backupSubtitle': {
      'uz': "Ma'lumotlarni eksport qilish",
      'ru': 'Экспорт данных'
    },
    'settings.about': {'uz': 'Dastur haqida', 'ru': 'О программе'},
    'settings.version': {'uz': 'Versiya', 'ru': 'Версия'},

    // ===== Printer dialogi =====
    'printer.title': {'uz': 'Printer sozlamalari', 'ru': 'Настройки принтера'},
    'printer.info': {
      'uz':
          "Xprinter XP-370B termal printer aniqlandi. Printerni USB orqali ulang va drayverini o'rnating.",
      'ru':
          'Обнаружен термопринтер Xprinter XP-370B. Подключите принтер по USB и установите драйвер.'
    },
    'printer.available': {
      'uz': 'Mavjud printerlar:',
      'ru': 'Доступные принтеры:'
    },
    'printer.refresh': {'uz': 'Yangilash', 'ru': 'Обновить'},
    'printer.notFound': {
      'uz': 'Printer topilmadi.\nUSB kabelini ulang va qayta skanerlang.',
      'ru': 'Принтер не найден.\nПодключите USB-кабель и повторите сканирование.'
    },
    'printer.default': {'uz': 'Asosiy printer', 'ru': 'Принтер по умолчанию'},
    'printer.selected': {'uz': 'tanlandi', 'ru': 'выбран'},
    'printer.autoReceipt': {
      'uz': 'Chekni avtomatik chop etish',
      'ru': 'Автопечать чека'
    },
    'printer.autoReceiptDesc': {
      'uz': 'Har bir sotuvdan keyin',
      'ru': 'После каждой продажи'
    },
    'printer.autoLabel': {
      'uz': 'Yorliqni avtomatik chop etish',
      'ru': 'Автопечать этикетки'
    },
    'printer.autoLabelDesc': {
      'uz': "Yangi mahsulot qo'shganda",
      'ru': 'При добавлении нового товара'
    },
    'printer.testLabel': {
      'uz': "Test yorlig'i chop etish",
      'ru': 'Печать тестовой этикетки'
    },
    'printer.testPrinted': {
      'uz': "Test yorlig'i chop etildi!",
      'ru': 'Тестовая этикетка напечатана!'
    },
    'printer.testError': {
      'uz': 'Xato! Printer ulanishini tekshiring.',
      'ru': 'Ошибка! Проверьте подключение принтера.'
    },
    'printer.notConfigured': {
      'uz': 'Printer sozlanmagan. Sozlamalardan tanlang.',
      'ru': 'Принтер не настроен. Выберите в настройках.'
    },
    'printer.labelPrinted': {
      'uz': 'Yorliq chop etildi',
      'ru': 'Этикетка напечатана'
    },
    'printer.printError': {'uz': 'Chop etishda xato', 'ru': 'Ошибка печати'},

    // ===== Telegram dialogi =====
    'telegram.title': {
      'uz': 'Telegram Bot sozlamalari',
      'ru': 'Настройки Telegram бота'
    },
    'telegram.howTo': {'uz': '📌 Qanday sozlash:', 'ru': '📌 Как настроить:'},
    'telegram.step1': {
      'uz': '1. @BotFather ga /newbot yozing',
      'ru': '1. Напишите /newbot боту @BotFather'
    },
    'telegram.step2': {
      'uz': 'Bot nomini va username kiriting',
      'ru': '2. Укажите имя и username бота'
    },
    'telegram.step3': {
      'uz': '3. Olingan tokenni quyiga kiriting',
      'ru': '3. Введите полученный токен ниже'
    },
    'telegram.step4': {
      'uz': '4. @userinfobot orqali Chat ID oling',
      'ru': '4. Получите Chat ID через @userinfobot'
    },
    'telegram.botToken': {'uz': 'Bot Token', 'ru': 'Токен бота'},
    'telegram.enterToken': {
      'uz': 'Bot tokenini kiriting',
      'ru': 'Введите токен бота'
    },
    'telegram.tokenFormat': {
      'uz': "Token formati noto'g'ri",
      'ru': 'Неверный формат токена'
    },
    'telegram.enterChatId': {'uz': 'Chat ID kiriting', 'ru': 'Введите Chat ID'},
    'telegram.notifyEnabled': {
      'uz': 'Xabarnomalar faol',
      'ru': 'Уведомления включены'
    },
    'telegram.newOrders': {'uz': 'Yangi buyurtmalar', 'ru': 'Новые заказы'},
    'telegram.newOrdersDesc': {
      'uz': 'Har bir buyurtmada xabar',
      'ru': 'Сообщение по каждому заказу'
    },
    'telegram.stockAlert': {
      'uz': 'Tovar tugashi haqida',
      'ru': 'Оповещение об остатках'
    },
    'telegram.stockAlertDesc': {
      'uz': 'Mahsulot tugaganda',
      'ru': 'Когда товар заканчивается'
    },
    'telegram.dailyReport': {'uz': 'Kunlik hisobot', 'ru': 'Ежедневный отчёт'},
    'telegram.dailyReportDesc': {
      'uz': 'Har kuni savdo statistikasi',
      'ru': 'Статистика продаж каждый день'
    },
    'telegram.test': {'uz': 'Test', 'ru': 'Тест'},
    'telegram.saved': {
      'uz': 'Telegram sozlamalari saqlandi!',
      'ru': 'Настройки Telegram сохранены!'
    },
    'telegram.enterFirst': {
      'uz': 'Avval token va chat ID kiriting',
      'ru': 'Сначала введите токен и Chat ID'
    },
    'telegram.testSent': {
      'uz': 'Test xabari yuborildi! Telegramni tekshiring.',
      'ru': 'Тестовое сообщение отправлено! Проверьте Telegram.'
    },
    'telegram.testError': {
      'uz': "Xato! Token yoki Chat ID noto'g'ri.",
      'ru': 'Ошибка! Неверный токен или Chat ID.'
    },

    // ===== Dashboard qo'shimcha =====
    'dash.searchHint': {'uz': 'Qidirish...', 'ru': 'Поиск...'},
    'dash.admin': {'uz': 'Admin', 'ru': 'Админ'},
    'dash.recentSales': {'uz': "So'nggi savdolar", 'ru': 'Последние продажи'},
    'dash.noSales': {'uz': "Savdolar yo'q", 'ru': 'Нет продаж'},
    'dash.allStockOk': {'uz': 'Hammasi yetarli', 'ru': 'Всего достаточно'},

    // ===== Analytics qo'shimcha =====
    'report.week': {'uz': 'Hafta', 'ru': 'Неделя'},
    'report.all': {'uz': 'Hammasi', 'ru': 'Всё'},
    'report.discountGiven': {
      'uz': 'Chegirma berilgan',
      'ru': 'Предоставлено скидок'
    },
    'report.revenueTrend': {'uz': 'tushum trend', 'ru': 'тренд выручки'},
    'report.noData': {'uz': "Ma'lumot yo'q", 'ru': 'Нет данных'},

    // ===== Birliklar =====
    'unit.pcs': {'uz': 'ta', 'ru': 'шт'},
    'unit.items': {'uz': 'tovar', 'ru': 'товаров'},
    'common.other': {'uz': 'Boshqa', 'ru': 'Другое'},

    // ===== Chegirma =====
    'discount.title': {'uz': 'Chegirmalar', 'ru': 'Скидки'},
    'discount.add': {'uz': "Chegirma qo'shish", 'ru': 'Добавить скидку'},
    'discount.noProducts': {
      'uz': "Chegirmali mahsulotlar yo'q",
      'ru': 'Нет товаров со скидкой'
    },
    'discount.addHint': {
      'uz': "Tovarlarni tahrirlash orqali chegirma qo'shing",
      'ru': 'Добавьте скидку через редактирование товара'
    },
    'discount.removeTitle': {
      'uz': 'Chegirmani olib tashlash',
      'ru': 'Убрать скидку'
    },
    'discount.removeConfirm': {
      'uz': 'dan chegirmani olib tashlamoqchimisiz?',
      'ru': '— убрать скидку?'
    },
    'discount.remove': {'uz': 'Olib tashlash', 'ru': 'Убрать'},
    'discount.selectProduct': {
      'uz': 'Mahsulotni tanlang:',
      'ru': 'Выберите товар:'
    },
    'discount.selectProductHint': {
      'uz': 'Mahsulot tanlang',
      'ru': 'Выберите товар'
    },
    'discount.percent': {'uz': 'Chegirma foizi (%)', 'ru': 'Процент скидки (%)'},
    'discount.current': {'uz': 'Joriy', 'ru': 'Текущая'},
    'discount.apply': {'uz': "Qo'llash", 'ru': 'Применить'},
    'discount.applied': {'uz': 'chegirma qo\'shildi', 'ru': 'скидка добавлена'},

    // ===== Savdo tarixi qo'shimcha =====
    'sales.noSales': {'uz': "Hali savdolar yo'q", 'ru': 'Продаж пока нет'},
    'sales.details': {'uz': 'Savdo tafsilotlari', 'ru': 'Детали продажи'},
    'sales.products': {'uz': 'Tovarlar:', 'ru': 'Товары:'},
    'sales.originalAmount': {'uz': 'Asl summa:', 'ru': 'Сумма без скидки:'},
    'sales.discountLabel': {'uz': 'Chegirma:', 'ru': 'Скидка:'},
    'sales.totalUpper': {'uz': 'JAMI:', 'ru': 'ИТОГО:'},

    // ===== Sklad qo'shimcha =====
    'warehouse.nothingFound': {
      'uz': 'Hech narsa topilmadi',
      'ru': 'Ничего не найдено'
    },
    'warehouse.noProducts': {
      'uz': "Hali mahsulot yo'q",
      'ru': 'Товаров пока нет'
    },
    'warehouse.addFirst': {
      'uz': "Birinchi mahsulotni qo'shing",
      'ru': 'Добавьте первый товар'
    },
    'warehouse.deleted': {'uz': "o'chirildi", 'ru': 'удалён'},
    'warehouse.confirmDelete': {
      'uz': "O'chirishni tasdiqlang",
      'ru': 'Подтвердите удаление'
    },
    'warehouse.deleteConfirm': {
      'uz': "ni o'chirishni xohlaysizmi?",
      'ru': '— удалить?'
    },

    // ===== Tovar formasi qo'shimcha =====
    'form.enterName': {
      'uz': 'Tovar nomini kiriting',
      'ru': 'Введите название товара'
    },
    'form.selectCategory': {
      'uz': 'Kategoriya tanlang',
      'ru': 'Выберите категорию'
    },
    'form.required': {'uz': 'Majburiy', 'ru': 'Обязательно'},
    'form.invalid': {'uz': "Noto'g'ri", 'ru': 'Неверно'},
    'form.profit': {'uz': 'Foyda', 'ru': 'Прибыль'},
    'form.barcodeHint': {
      'uz': "Skaner orqali yoki qo'lda kiriting",
      'ru': 'Сканером или вручную'
    },
    'form.hasVariants': {
      'uz': "bor (o'lcham/rang)",
      'ru': 'есть (размер/цвет)'
    },
    'form.variantTotal': {'uz': 'jami', 'ru': 'всего'},
    'form.variant': {'uz': 'Variant', 'ru': 'Вариант'},
    'form.variantHint': {
      'uz': "Variant qo'shing: o'lcham + rang + soni. Shtrix kod avtomatik.",
      'ru':
          'Добавьте вариант: размер + цвет + количество. Штрих-код автоматически.'
    },
    'form.addVariantFirst': {
      'uz': "Kamida bitta variant qo'shing",
      'ru': 'Добавьте хотя бы один вариант'
    },
    'form.updated': {'uz': 'yangilandi!', 'ru': 'обновлён!'},
    'form.saved': {'uz': 'saqlandi!', 'ru': 'сохранён!'},
    'form.saving': {'uz': 'Saqlanmoqda...', 'ru': 'Сохранение...'},
    'form.barcodeLabel': {'uz': 'Shtrix kod', 'ru': 'Штрих-код'},

    // ===== Misc =====
    'common.created': {'uz': 'Yaratildi', 'ru': 'Создано'},

    // ===== Autentifikatsiya =====
    'auth.title': {'uz': 'Kirish', 'ru': 'Вход'},
    'auth.email': {'uz': 'Email', 'ru': 'Email'},
    'auth.password': {'uz': 'Parol', 'ru': 'Пароль'},
    'auth.login': {'uz': 'Kirish', 'ru': 'Войти'},
    'auth.loginError': {
      'uz': "Email yoki parol noto'g'ri",
      'ru': 'Неверный email или пароль'
    },
    'auth.logout': {'uz': 'Chiqish', 'ru': 'Выход'},
  };
}
