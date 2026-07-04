import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Maps a category/subscription name to a sensible Material icon and
/// color so imported/auto-created categories still look intentional
/// instead of falling back to a generic dot.
class CategoryIcons {
  CategoryIcons._();

  static const Map<String, IconData> _iconMap = {
    'food': Icons.restaurant_rounded,
    'groceries': Icons.local_grocery_store_rounded,
    'travel': Icons.flight_takeoff_rounded,
    'fuel': Icons.local_gas_station_rounded,
    'shopping': Icons.shopping_bag_rounded,
    'entertainment': Icons.movie_rounded,
    'bills': Icons.receipt_long_rounded,
    'medical': Icons.medical_services_rounded,
    'rent': Icons.home_rounded,
    'education': Icons.school_rounded,
    'salary': Icons.account_balance_wallet_rounded,
    'freelance': Icons.laptop_mac_rounded,
    'business': Icons.storefront_rounded,
    'investment': Icons.trending_up_rounded,
    'gift': Icons.card_giftcard_rounded,
    'refund': Icons.replay_rounded,
    'netflix': Icons.smart_display_rounded,
    'spotify': Icons.music_note_rounded,
    'amazon prime': Icons.shopping_cart_rounded,
    'youtube premium': Icons.smart_display_rounded,
    'gym': Icons.fitness_center_rounded,
    'internet': Icons.wifi_rounded,
    'insurance': Icons.shield_rounded,
    'phone recharge': Icons.phone_android_rounded,
    'electricity': Icons.bolt_rounded,
    'water': Icons.water_drop_rounded,
    'others': Icons.category_rounded,
  };

  static IconData iconFor(String name) {
    return _iconMap[name.toLowerCase().trim()] ?? Icons.category_rounded;
  }

  static Color colorFor(int index) {
    return AppColors.categoryPalette[index % AppColors.categoryPalette.length];
  }

  static Color colorFromValue(int value) => Color(value);
}
