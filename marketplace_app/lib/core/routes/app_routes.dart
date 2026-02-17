/// Routes nommées de l'application
class AppRoutes {
  // Auth
  static const String login = '/login';
  static const String register = '/register';
  
  // Home & Products
  static const String home = '/';
  static const String productDetail = '/product/:id';
  static const String search = '/search';
  static const String createProduct = '/create-product';
  
  // Orders
  static const String orders = '/orders';
  static const String orderDetail = '/order/:id';
  
  // Profile
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String settings = '/settings';
  static const String myProducts = '/my-products';
  static const String favorites = '/favorites';
  static const String addresses = '/addresses';
  static const String addressForm = '/addresses/:id'; // id = new|existing
  static const String sellerProfile = '/seller/:id';

  // Chat
  static const String conversations = '/conversations';
  static const String chat = '/chat/:id';
}
