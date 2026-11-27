class ApiEndpoints {
  ApiEndpoints._();

  static const String prefix = '/api/v1';
  static const String openApiJson = '/api/openapi.json';
  static const String swaggerDocs = '/api/docs';

  // Store Bootstrap & Catalog
  static const String bootstrap = '$prefix/bootstrap';
  static const String home = '$prefix/home';
  static const String products = '$prefix/products';
  static const String searchSuggest = '$prefix/search/suggest';
  static String productDetail(String slug) =>
      '$prefix/products/${Uri.encodeComponent(slug)}';
  static String productReviews(String slug) =>
      '$prefix/products/${Uri.encodeComponent(slug)}/reviews';

  // Wishlist
  static const String wishlist = '$prefix/wishlist';
  static const String wishlistToggle = '$prefix/wishlist/toggle';

  // Cart
  static const String cart = '$prefix/cart';
  static const String cartItems = '$prefix/cart/items';
  static String cartItem(int id) => '$prefix/cart/items/$id';
  static const String cartDiscount = '$prefix/cart/discount';

  // Checkout, Bakong KHQR Payment & Invoice
  static const String checkout = '$prefix/checkout';
  static String orderPayment(String orderNumber) =>
      '$prefix/orders/${Uri.encodeComponent(orderNumber)}/payment';
  static String paymentStatus(int paymentId) =>
      '$prefix/payments/$paymentId/status';
  static String orderRegenerateQr(String orderNumber) =>
      '$prefix/orders/${Uri.encodeComponent(orderNumber)}/regenerate-qr';
  static String paymentSimulatePay(int paymentId) =>
      '$prefix/payments/$paymentId/simulate-pay';
  static String orderInvoice(String orderNumber) =>
      '$prefix/orders/${Uri.encodeComponent(orderNumber)}/invoice';

  // Authentication
  static const String authRegister = '$prefix/auth/register';
  static const String authLogin = '$prefix/auth/login';
  static const String authLogout = '$prefix/auth/logout';
  static const String authForgotPassword = '$prefix/auth/forgot-password';
  static const String authMe = '$prefix/auth/me';
  static const String authPassword = '$prefix/auth/password';

  // Customer Account Portal
  static const String accountProfile = '$prefix/account/profile';
  static const String accountOrders = '$prefix/account/orders';
  static String accountOrderDetail(String orderNumber) =>
      '$prefix/account/orders/${Uri.encodeComponent(orderNumber)}';
  static const String accountAddresses = '$prefix/account/addresses';
  static String accountAddress(int addressId) =>
      '$prefix/account/addresses/$addressId';

  // Info Pages & Support
  static String pageDetail(String slug) =>
      '$prefix/pages/${Uri.encodeComponent(slug)}';
  static const String contact = '$prefix/contact';
  static const String newsletter = '$prefix/newsletter';
}
