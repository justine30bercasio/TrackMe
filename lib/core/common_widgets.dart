import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import 'package:track_me/core/payment_methods.dart';
import 'package:track_me/core/theme.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? color;
  final BorderRadius? borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.onLongPress,
    this.color,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(20);
    final card = Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.surface,
        borderRadius: radius,
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF262C38)
              : const Color(0xFFEEF0F6),
          width: 1,
        ),
      ),
      child: child,
    );
    if (onTap == null && onLongPress == null) return card;
    return InkWell(borderRadius: radius, onTap: onTap, onLongPress: onLongPress, child: card);
  }
}

class MoneyText extends StatelessWidget {
  final double amount;
  final String currencyCode;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? color;
  final bool showSign;

  const MoneyText(
    this.amount,
    this.currencyCode, {
    super.key,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w700,
    this.color,
    this.showSign = false,
  });

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat('#,##0.00');
    final sign = showSign && amount != 0
        ? (amount > 0 ? '+' : '-')
        : '';
    return Text(
      '$sign${currencySymbol(currencyCode)}${nf.format(amount.abs())}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? Theme.of(context).textTheme.bodyLarge!.color,
      ),
    );
  }
}

String currencySymbol(String code) {
  const symbols = {
    'USD': r'$', 'EUR': '€', 'GBP': '£', 'JPY': '¥', 'PHP': '₱',
    'AUD': r'A$', 'CAD': r'C$', 'SGD': r'S$', 'HKD': r'HK$', 'INR': '₹',
    'THB': '฿', 'MYR': 'RM', 'IDR': 'Rp', 'VND': '₫', 'CNY': '¥',
    'CHF': 'Fr', 'SEK': 'kr', 'NOK': 'kr', 'DKK': 'kr', 'BRL': r'R$',
    'MXN': r'$', 'NZD': r'NZ$', 'KRW': '₩', 'TWD': r'NT$', 'AED': 'د.إ',
    'SAR': '﷼', 'ZAR': 'R', 'ARS': r'$',
  };
  return symbols[code] ?? r'$';
}

String formatMoney(double amount, String currencyCode, {int decimals = 2}) {
  final nf = NumberFormat(decimals == 0 ? '#,##0' : '#,##0.${'0' * decimals}');
  return '${currencySymbol(currencyCode)}${nf.format(amount)}';
}

IconData categoryIcon(String categoryName, {String fallback = 'other'}) {
  final name = categoryName.toLowerCase();
  if (name.contains('food') || name.contains('restaurant') || name.contains('grocery')) return Icons.restaurant;
  if (name.contains('transport') || name.contains('fuel') || name.contains('gas')) return Icons.directions_car;
  if (name.contains('entertain') || name.contains('movie') || name.contains('music')) return Icons.movie;
  if (name.contains('health') || name.contains('medical') || name.contains('doctor')) return Icons.local_hospital;
  if (name.contains('education') || name.contains('school') || name.contains('tuition')) return Icons.school;
  if (name.contains('bill') || name.contains('utility') || name.contains('electric')) return Icons.receipt_long;
  if (name.contains('shopping') || name.contains('mall') || name.contains('shop')) return Icons.shopping_bag;
  if (name.contains('salary') || name.contains('income')) return Icons.payments;
  if (name.contains('saving')) return Icons.savings;
  if (name.contains('travel') || name.contains('vacation')) return Icons.flight;
  if (name.contains('other') || name.contains('misc')) return Icons.category;
  if (name.contains('subscription')) return Icons.update;
  if (name.contains('rent') || name.contains('home')) return Icons.home;
  switch (fallback) {
    case 'income':
      return Icons.south_west;
    default:
      return Icons.category;
  }
}

class PaymentMethodBadge extends StatelessWidget {
  final String code;
  final double size;
  final bool outlined;

  const PaymentMethodBadge({super.key, required this.code, this.size = 26, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    final info = paymentMethodInfo(code);
    final bg = info?.brandColor ?? AppColors.colorFromHex('#6B7280');
    final fg = ThemeData.estimateBrightnessForColor(bg) == Brightness.dark
        ? Colors.white
        : const Color(0xFF1F2430);
    final radius = size * 0.28;
    final icon = info?.icon;
    final monogram = info?.monogram;
    final assetIcon = info?.assetIcon;
    Container shape;
    if (assetIcon != null) {
      shape = Container(
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
        alignment: Alignment.center,
        padding: EdgeInsets.all(size * 0.12),
        child: SvgPicture.asset(
          assetIcon,
          fit: BoxFit.contain,
          width: size * 0.76,
          height: size * 0.76,
        ),
      );
    } else {
      shape = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(radius),
        ),
        alignment: Alignment.center,
        child: icon != null
            ? Icon(icon, color: fg, size: size * 0.58)
            : Text(
                monogram ?? (code.isEmpty ? '?' : code[0].toUpperCase()),
                style: TextStyle(color: fg, fontSize: size * (monogram != null && monogram.length > 2 ? 0.26 : 0.42), fontWeight: FontWeight.w800),
                maxLines: 1,
                textAlign: TextAlign.center,
              ),
      );
    }
    if (!outlined) return shape;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: shape,
    );
  }
}

class CategoryAvatar extends StatelessWidget {
  final String? color;
  final String? name;
  final double size;
  final IconData? icon;

  const CategoryAvatar({super.key, this.color, this.name, this.size = 40, this.icon});

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.colorFromHex(color ?? '');
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(
        icon ?? categoryIcon(name ?? ''),
        color: bg,
        size: size * 0.52,
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const EmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).textTheme.bodySmall!.color!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message, style: TextStyle(color: secondary, fontSize: 14), textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const SectionTitle(this.title, {super.key, this.trailing, this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 12)});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class Pill extends StatelessWidget {
  final String text;
  final Color color;

  const Pill(this.text, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

class StatTile extends StatelessWidget {
  final String label;
  final Widget value;
  final IconData icon;
  final Color iconColor;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Theme.of(context).textTheme.bodySmall!.color, fontSize: 12)),
                const SizedBox(height: 2),
                value,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProgressBar extends StatelessWidget {
  final double fraction;
  final Color color;
  final double height;

  const ProgressBar({super.key, required this.fraction, this.color = AppColors.primary, this.height = 8});

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark2 : const Color(0xFFE9EBF2);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: LinearProgressIndicator(
          value: fraction.clamp(0, 1),
          backgroundColor: bg,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ),
    );
  }
}

String formatDate(String isoDate) {
  final dt = DateTime.tryParse(isoDate);
  if (dt == null) return isoDate;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(dt.year, dt.month, dt.day);
  final diff = today.difference(d).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff == -1) return 'Tomorrow';
  return DateFormat('MMM d, yyyy').format(dt);
}

String formatDateShort(String isoDate) {
  final dt = DateTime.tryParse(isoDate);
  if (dt == null) return isoDate;
  return DateFormat('MMM d, yyyy').format(dt);
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);