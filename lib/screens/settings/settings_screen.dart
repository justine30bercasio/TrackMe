import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:track_me/core/app_strings.dart';
import 'package:track_me/core/common_widgets.dart';
import 'package:track_me/core/theme.dart';
import 'package:track_me/providers/app_state.dart';
import 'package:track_me/screens/assistant/assistant_screen.dart';
import 'package:track_me/screens/backup/backup_screen.dart';
import 'package:track_me/screens/categories/categories_screen.dart';
import 'package:track_me/screens/currencies/currencies_screen.dart';
import 'package:track_me/screens/goals/goals_screen.dart';
import 'package:track_me/screens/import/import_screen.dart';
import 'package:track_me/screens/keywords/auto_categorization_screen.dart';
import 'package:track_me/screens/loans/loans_screen.dart';
import 'package:track_me/screens/profile/profile_screen.dart';
import 'package:track_me/screens/receipts/scan_receipt_screen.dart';
import 'package:track_me/screens/recurring/recurring_list_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _ProfileBanner(
            name: user.name.isEmpty ? 'Set up your profile' : user.name,
            currency: user.preferredCurrency,
            flag: user.flagEmoji,
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
          const SizedBox(height: 20),
          _SectionTileGroup(
            title: 'Preferences',
            children: [
              _SettingsTile(
                icon: Icons.dark_mode_outlined,
                title: 'Dark mode',
                trailing: Switch(
                  value: state.darkMode,
                  onChanged: (v) => state.setDarkMode(v),
                ),
              ),
              _SettingsTile(
                icon: Icons.currency_exchange,
                title: 'Currencies',
                subtitle: 'Manage currencies and exchange rates',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const CurrenciesScreen())),
              ),
              _SettingsTile(
                icon: Icons.person_outline,
                title: 'Profile',
                subtitle: 'Name, country, language, reminders',
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen())),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SectionTileGroup(
            title: 'Manage',
            children: [
              _SettingsTile(
                icon: Icons.forum_outlined,
                title: 'TrackMe Assistant',
                subtitle: 'Chat, and it auto-logs your expenses & income',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  settings:
                      const RouteSettings(name: AssistantScreen.routeName),
                  builder: (_) => const AssistantScreen(),
                )),
              ),
              _SettingsTile(
                icon: Icons.document_scanner_outlined,
                title: 'Scan receipt',
                subtitle: 'Scan or upload a receipt to auto-fill an expense',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ScanReceiptScreen())),
              ),
              _SettingsTile(
                icon: Icons.category_outlined,
                title: 'Categories',
                subtitle: 'Add, edit and organize expense categories',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const CategoriesScreen())),
              ),
              _SettingsTile(
                icon: Icons.auto_awesome,
                title: 'Auto-categorization',
                subtitle: 'Keywords that sort your expenses automatically',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const AutoCategorizationScreen())),
              ),
              _SettingsTile(
                icon: Icons.savings_outlined,
                title: 'Savings goals',
                subtitle: 'Track your savings targets',
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const GoalsScreen())),
              ),
              _SettingsTile(
                icon: Icons.autorenew,
                title: 'Recurring transactions',
                subtitle: 'Bills and subscriptions that repeat',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const RecurringListScreen())),
              ),
              _SettingsTile(
                icon: Icons.request_quote_outlined,
                title: 'Loans & repayments',
                subtitle: 'Repayment schedules aligned to your salary',
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoansScreen())),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SectionTileGroup(
            title: 'Data',
            children: [
              _SettingsTile(
                icon: Icons.upload_file_outlined,
                title: 'Backup & restore',
                subtitle: 'Export or import your full data',
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BackupScreen())),
              ),
              _SettingsTile(
                icon: Icons.table_view_outlined,
                title: 'Import CSV',
                subtitle: 'Import expenses or income from a file',
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ImportScreen())),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.appName,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('Version 1.0.0',
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall!.color)),
                const SizedBox(height: 8),
                Text(
                  'Your data never leaves this device. Everything is stored locally in your own database.',
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodySmall!.color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileBanner extends StatelessWidget {
  final String name;
  final String currency;
  final String flag;
  final VoidCallback onTap;
  const _ProfileBanner(
      {required this.name,
      required this.currency,
      required this.flag,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: name.isEmpty
                  ? const Icon(Icons.person, color: AppColors.onHero, size: 28)
                  : Text(
                      (flag.isNotEmpty
                          ? flag
                          : name.characters.first.toUpperCase()),
                      style: const TextStyle(fontSize: 22),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name.isEmpty ? 'Your name' : name,
                      style: const TextStyle(
                          color: AppColors.onHero,
                          fontSize: 17,
                          fontWeight: FontWeight.w800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('Primary currency: $currency',
                      style: TextStyle(
                          color: AppColors.onHeroMuted, fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.onHeroMuted),
          ],
        ),
      ),
    );
  }
}

class _SectionTileGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionTileGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: Theme.of(context).textTheme.titleSmall),
        ),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _SettingsTile(
      {required this.icon,
      required this.title,
      this.subtitle,
      this.trailing,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primary, size: 21),
      ),
      title: Text(title,
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall!.color))
          : null,
      trailing: trailing ??
          (onTap != null ? const Icon(Icons.chevron_right, size: 20) : null),
      onTap: onTap,
    );
  }
}
