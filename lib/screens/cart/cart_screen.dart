import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_navigation_provider.dart';
import '../../widgets/cart_drawer.dart';
import '../checkout/checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CartContentView(
      inDrawerOrSheet: false,
      onProceedToCheckout: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const CheckoutScreen(),
          ),
        );
      },
      onContinueShopping: () {
        context.read<AppNavigationProvider>().openShop();
      },
    );
  }
}
