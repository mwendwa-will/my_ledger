import 'package:flutter/material.dart';

// Centralized map of allowed IconData constants to enable icon font tree-shaking.
// Add any icons you expect to use dynamically here.
final Map<int, IconData> _iconMap = {
  // common icons used across the app
  Icons.category.codePoint: Icons.category,
  Icons.shopping_cart.codePoint: Icons.shopping_cart,
  Icons.restaurant.codePoint: Icons.restaurant,
  Icons.directions_car.codePoint: Icons.directions_car,
  Icons.receipt.codePoint: Icons.receipt,
  Icons.shopping_bag.codePoint: Icons.shopping_bag,
  Icons.movie.codePoint: Icons.movie,
  Icons.favorite.codePoint: Icons.favorite,
  Icons.more_horiz.codePoint: Icons.more_horiz,
  Icons.attach_money.codePoint: Icons.attach_money,
  Icons.work.codePoint: Icons.work,
  Icons.trending_up.codePoint: Icons.trending_up,
  Icons.add.codePoint: Icons.add,
  Icons.home.codePoint: Icons.home,
  Icons.school.codePoint: Icons.school,
  Icons.fitness_center.codePoint: Icons.fitness_center,
  Icons.medical_services.codePoint: Icons.medical_services,
  Icons.pets.codePoint: Icons.pets,
  Icons.business.codePoint: Icons.business,
  Icons.flight.codePoint: Icons.flight,
  Icons.fastfood.codePoint: Icons.fastfood,
  Icons.lightbulb.codePoint: Icons.lightbulb,
  Icons.phone.codePoint: Icons.phone,
  Icons.wifi.codePoint: Icons.wifi,
  Icons.build.codePoint: Icons.build,
  Icons.book.codePoint: Icons.book,
  Icons.watch.codePoint: Icons.watch,
  Icons.brush.codePoint: Icons.brush,
  Icons.camera_alt.codePoint: Icons.camera_alt,
  Icons.headphones.codePoint: Icons.headphones,
  Icons.devices.codePoint: Icons.devices,

  // account icons
  Icons.credit_card.codePoint: Icons.credit_card,
  Icons.savings.codePoint: Icons.savings,
  Icons.credit_score.codePoint: Icons.credit_score,
  Icons.attach_money.codePoint: Icons.attach_money,
  Icons.account_balance_wallet.codePoint: Icons.account_balance_wallet,

  // transaction-related
  Icons.money_off.codePoint: Icons.money_off,
  Icons.swap_horiz.codePoint: Icons.swap_horiz,
  Icons.arrow_downward.codePoint: Icons.arrow_downward,
  Icons.arrow_upward.codePoint: Icons.arrow_upward,
  Icons.download.codePoint: Icons.download,
};

IconData getIconFromCodePoint(int codePoint) {
  return _iconMap[codePoint] ?? Icons.category; // fallback to a safe constant
}
