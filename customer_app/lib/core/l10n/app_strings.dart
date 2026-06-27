/// Mijozlar ilovasi UZ/RU tarjimalar lug'ati. Kalit -> {uz, ru}.
class AppStrings {
  static const Map<String, Map<String, String>> values = {
    // Navigatsiya
    'nav.home': {'uz': 'Bosh sahifa', 'ru': 'Главная'},
    'nav.search': {'uz': 'Qidiruv', 'ru': 'Поиск'},
    'nav.menu': {'uz': 'Menyu', 'ru': 'Меню'},
    'nav.cart': {'uz': 'Savat', 'ru': 'Корзина'},
    'nav.wishlist': {'uz': 'Sevimlilar', 'ru': 'Избранное'},
    'nav.profile': {'uz': 'Profil', 'ru': 'Профиль'},
    'nav.orders': {'uz': 'Buyurtmalarim', 'ru': 'Мои заказы'},

    // Umumiy
    'common.sum': {'uz': "so'm", 'ru': 'сум'},
    'common.all': {'uz': 'Barchasi', 'ru': 'Все'},
    'common.cancel': {'uz': 'Bekor', 'ru': 'Отмена'},
    'common.save': {'uz': 'Saqlash', 'ru': 'Сохранить'},
    'common.close': {'uz': 'Yopish', 'ru': 'Закрыть'},
    'common.error': {'uz': 'Xatolik', 'ru': 'Ошибка'},
    'common.empty': {'uz': "Bo'sh", 'ru': 'Пусто'},
    'common.loading': {'uz': 'Yuklanmoqda...', 'ru': 'Загрузка...'},
    'common.notFound': {'uz': 'Topilmadi', 'ru': 'Не найдено'},
    'common.retry': {'uz': 'Qayta urinish', 'ru': 'Повторить'},
    'common.viewAll': {'uz': "Barchasini ko'rish", 'ru': 'Смотреть все'},

    // Home
    'home.newArrivals': {'uz': 'Yangi mahsulotlar', 'ru': 'Новинки'},
    'home.categories': {'uz': 'Kategoriyalar', 'ru': 'Категории'},
    'home.popular': {'uz': 'Ommabop', 'ru': 'Популярное'},
    'home.shopNow': {'uz': 'XARID QILISH', 'ru': 'В МАГАЗИН'},
    'home.welcome': {'uz': 'Xush kelibsiz', 'ru': 'Добро пожаловать'},
    'home.sale': {'uz': 'Chegirmalar', 'ru': 'Скидки'},
    'home.collection': {'uz': 'Kolleksiya', 'ru': 'Коллекция'},
    'home.discountUpTo': {'uz': 'CHEGIRMA', 'ru': 'СКИДКА'},

    // Qidiruv
    'search.hint': {'uz': 'Mahsulot qidirish...', 'ru': 'Поиск товаров...'},
    'search.start': {
      'uz': 'Qidirish uchun yozing',
      'ru': 'Введите запрос для поиска'
    },
    'search.noResults': {'uz': 'Hech narsa topilmadi', 'ru': 'Ничего не найдено'},

    // Mahsulot
    'product.size': {'uz': "O'lcham", 'ru': 'Размер'},
    'product.color': {'uz': 'Rang', 'ru': 'Цвет'},
    'product.addToCart': {'uz': 'SAVATGA', 'ru': 'В КОРЗИНУ'},
    'product.addMore': {'uz': 'YANA QO\'SHISH', 'ru': 'ДОБАВИТЬ ЕЩЁ'},
    'product.added': {'uz': 'Savatga qo\'shildi', 'ru': 'Добавлено в корзину'},
    'product.outOfStock': {'uz': 'Tugagan', 'ru': 'Нет в наличии'},
    'product.selectSize': {
      'uz': "Iltimos o'lchamni tanlang",
      'ru': 'Выберите размер'
    },
    'product.selectColor': {'uz': 'Iltimos rangni tanlang', 'ru': 'Выберите цвет'},
    'product.inStock': {'uz': 'Mavjud', 'ru': 'В наличии'},
    'product.description': {'uz': 'Tavsif', 'ru': 'Описание'},
    'product.viewCart': {'uz': 'SAVATNI KO\'RISH', 'ru': 'В КОРЗИНУ'},

    // Savat
    'cart.title': {'uz': 'Savat', 'ru': 'Корзина'},
    'cart.empty': {'uz': "Savat bo'sh", 'ru': 'Корзина пуста'},
    'cart.subtotal': {'uz': 'Mahsulotlar', 'ru': 'Товары'},
    'cart.delivery': {'uz': 'Yetkazib berish', 'ru': 'Доставка'},
    'cart.free': {'uz': 'Bepul', 'ru': 'Бесплатно'},
    'cart.total': {'uz': 'Jami', 'ru': 'Итого'},
    'cart.checkout': {'uz': 'BUYURTMA BERISH', 'ru': 'ОФОРМИТЬ ЗАКАЗ'},
    'cart.continueShopping': {'uz': 'XARIDNI DAVOM ETTIRISH', 'ru': 'ПРОДОЛЖИТЬ ПОКУПКИ'},
    'cart.items': {'uz': 'mahsulot', 'ru': 'товаров'},
    'cart.freeOver': {
      'uz': '500 000 so\'mdan yuqorida yetkazib berish bepul',
      'ru': 'Бесплатная доставка при заказе от 500 000 сум'
    },

    // Checkout
    'checkout.title': {'uz': 'Buyurtma berish', 'ru': 'Оформление заказа'},
    'checkout.name': {'uz': 'Ism familiya', 'ru': 'Имя и фамилия'},
    'checkout.phone': {'uz': 'Telefon raqam', 'ru': 'Номер телефона'},
    'checkout.address': {'uz': 'Manzil', 'ru': 'Адрес'},
    'checkout.notes': {'uz': 'Izoh (ixtiyoriy)', 'ru': 'Комментарий (необязательно)'},
    'checkout.placeOrder': {'uz': 'BUYURTMANI TASDIQLASH', 'ru': 'ПОДТВЕРДИТЬ ЗАКАЗ'},
    'checkout.success': {'uz': 'Buyurtma qabul qilindi!', 'ru': 'Заказ принят!'},
    'checkout.successDesc': {
      'uz': 'Tez orada siz bilan bog\'lanamiz',
      'ru': 'Мы скоро с вами свяжемся'
    },
    'checkout.required': {'uz': 'Majburiy maydon', 'ru': 'Обязательное поле'},
    'checkout.pickFromMap': {
      'uz': 'Xaritadan tanlash',
      'ru': 'Выбрать на карте'
    },
    'checkout.locationSelected': {
      'uz': 'Joylashuv tanlandi',
      'ru': 'Местоположение выбрано'
    },

    // Xarita
    'map.title': {'uz': 'Manzilni tanlang', 'ru': 'Выберите адрес'},
    'map.hint': {
      'uz': 'Xaritani suring — markazdagi belgi manzilni ko\'rsatadi',
      'ru': 'Двигайте карту — метка в центре указывает адрес'
    },
    'map.confirm': {'uz': 'Tasdiqlash', 'ru': 'Подтвердить'},
    'map.searching': {'uz': 'Manzil aniqlanmoqda...', 'ru': 'Определяем адрес...'},
    'map.myLocation': {'uz': 'Mening joylashuvim', 'ru': 'Моё местоположение'},
    'map.locationError': {
      'uz': 'Joylashuvni aniqlab bo\'lmadi',
      'ru': 'Не удалось определить местоположение'
    },

    // Buyurtmalar
    'orders.title': {'uz': 'Buyurtmalarim', 'ru': 'Мои заказы'},
    'orders.active': {'uz': 'Faol', 'ru': 'Активные'},
    'orders.completed': {'uz': 'Yakunlangan', 'ru': 'Завершённые'},
    'orders.empty': {'uz': 'Buyurtmalar yo\'q', 'ru': 'Заказов нет'},
    'orders.cancel': {'uz': 'Bekor qilish', 'ru': 'Отменить'},
    'orders.cancelConfirmTitle': {
      'uz': 'Buyurtmani bekor qilasizmi?',
      'ru': 'Отменить заказ?'
    },
    'orders.cancelConfirmBody': {
      'uz': 'Bu amalni qaytarib bo\'lmaydi.',
      'ru': 'Это действие нельзя отменить.'
    },
    'orders.cancelled': {
      'uz': 'Buyurtma bekor qilindi',
      'ru': 'Заказ отменён'
    },
    'common.no': {'uz': 'Yo\'q', 'ru': 'Нет'},
    'orders.noPhone': {
      'uz': 'Buyurtma bergach bu yerda ko\'rinadi',
      'ru': 'Заказы появятся здесь после оформления'
    },
    'orderStatus.pending': {'uz': 'Kutilmoqda', 'ru': 'Ожидает'},
    'orderStatus.confirmed': {'uz': 'Tasdiqlangan', 'ru': 'Подтверждён'},
    'orderStatus.processing': {'uz': 'Tayyorlanmoqda', 'ru': 'Готовится'},
    'orderStatus.shipped': {'uz': 'Yo\'lda', 'ru': 'В пути'},
    'orderStatus.delivered': {'uz': 'Yetkazilgan', 'ru': 'Доставлен'},
    'orderStatus.cancelled': {'uz': 'Bekor qilingan', 'ru': 'Отменён'},

    // Wishlist
    'wishlist.title': {'uz': 'Sevimlilar', 'ru': 'Избранное'},
    'wishlist.empty': {'uz': 'Sevimlilar yo\'q', 'ru': 'Список избранного пуст'},
    'wishlist.added': {'uz': 'Sevimlilarga qo\'shildi', 'ru': 'Добавлено в избранное'},
    'wishlist.removed': {'uz': 'Sevimlilardan o\'chirildi', 'ru': 'Удалено из избранного'},

    // Profil
    'profile.title': {'uz': 'Profil', 'ru': 'Профиль'},
    'profile.language': {'uz': 'Til', 'ru': 'Язык'},
    'profile.myOrders': {'uz': 'Buyurtmalarim', 'ru': 'Мои заказы'},
    'profile.contact': {'uz': 'Aloqa', 'ru': 'Контакты'},
    'profile.about': {'uz': 'Biz haqimizda', 'ru': 'О нас'},
  };
}
