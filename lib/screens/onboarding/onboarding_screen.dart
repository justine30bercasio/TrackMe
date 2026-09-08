import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:track_me/core/app_strings.dart';
import 'package:track_me/core/common_widgets.dart';
import 'package:track_me/core/theme.dart';
import 'package:track_me/data/app_repository.dart';
import 'package:track_me/providers/app_state.dart';
import 'package:track_me/screens/shell/main_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  final TextEditingController _nameController = TextEditingController();
  int _page = 0;

  String _country = '';
  String _currency = 'USD';
  String _language = 'en';
  final Set<String> _categories = {};
  bool _saving = false;

  static const int _totalPages = 3;

  void _next() {
    if (_page < _totalPages - 1) {
      _controller.nextPage(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    final repo = AppRepository.instance;
    try {
      final name = _nameController.text.trim();
      await repo.updateProfile(
        name: name,
        country: _country,
        region: AppStrings.countryNames[_country],
        preferredCurrency: _currency,
        language: _language,
        onboardingCompleted: name.isNotEmpty,
      );
      if (_categories.isNotEmpty) {
        for (final catName in _categories) {
          if (await repo.getCategoryByName(catName) == null) {
            await repo.addCategory(catName);
          }
        }
      }
      await repo.logActivity('onboarding', 'Completed onboarding setup');
      if (!mounted) return;
      Provider.of<AppState>(context, listen: false).reloadUser();
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShell()));
    } catch (e) {
      setState(() => _saving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Something went wrong: $e')));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  if (_page > 0)
                    IconButton(
                      onPressed: () => _controller.previousPage(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                      ),
                      icon: const Icon(Icons.arrow_back_ios_new),
                    ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: List.generate(_totalPages, (i) {
                        final active = i == _page;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.only(left: 6),
                          width: active ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.primary
                                : Theme.of(context).dividerColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        );
                      }),
                    ),
                  ),
                  TextButton(
                    onPressed: _page < _totalPages - 1
                        ? () => _controller.jumpToPage(_totalPages - 1)
                        : _finish,
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (p) => setState(() => _page = p),
                children: [
                  _NamePage(controller: _nameController),
                  _PreferencesPage(
                    country: _country,
                    currency: _currency,
                    language: _language,
                    onCountry: (c) => setState(() {
                      _country = c;
                      final cu = AppStrings.countryCurrencies[c];
                      if (cu != null) _currency = cu;
                    }),
                    onCurrency: (c) => setState(() => _currency = c),
                    onLanguage: (l) => setState(() => _language = l),
                  ),
                  _CategoriesPage(
                    selected: _categories,
                    onToggle: (name) => setState(() {
                      if (!_categories.remove(name)) _categories.add(name);
                    }),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: ElevatedButton(
                onPressed: _saving ? null : _next,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.4, color: Colors.white))
                    : Text(_page == _totalPages - 1
                        ? 'Start Managing Money'
                        : 'Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NamePage extends StatelessWidget {
  final TextEditingController controller;
  const _NamePage({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.savings_outlined,
                color: AppColors.onHero, size: 36),
          ),
          const SizedBox(height: 28),
          Text('Welcome!', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 10),
          Text(
            'Take control of your money with a simple, private expense tracker that works fully offline.',
            style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall!.color,
                fontSize: 15,
                height: 1.4),
          ),
          const SizedBox(height: 30),
          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'What should we call you?',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 14),
          Text('Your data stays on your device. No account, no server, no ads.',
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall!.color)),
        ],
      ),
    );
  }
}

class _PreferencesPage extends StatelessWidget {
  final String country;
  final String currency;
  final String language;
  final ValueChanged<String> onCountry;
  final ValueChanged<String> onCurrency;
  final ValueChanged<String> onLanguage;

  const _PreferencesPage({
    required this.country,
    required this.currency,
    required this.language,
    required this.onCountry,
    required this.onCurrency,
    required this.onLanguage,
  });

  Future<void> _pickCountry(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _PickerSheet(
        title: 'Select Country',
        items: AppStrings.countryNames.entries
            .map((e) => PickerItem(e.value, e.key))
            .toList(),
      ),
    );
    if (selected != null) onCountry(selected);
  }

  Future<void> _pickCurrency(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _PickerSheet(
        title: 'Preferred Currency',
        items: AppStrings.supportedCurrencies
            .map((c) =>
                PickerItem('$c - ${AppStrings.currencyNames[c] ?? c}', c))
            .toList(),
      ),
    );
    if (selected != null) onCurrency(selected);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      children: [
        const SizedBox(height: 24),
        Text('Set your preferences',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('You can change these later in Settings.',
            style:
                TextStyle(color: Theme.of(context).textTheme.bodySmall!.color)),
        const SizedBox(height: 28),
        _PrefTile(
          icon: Icons.public,
          label: 'Country',
          value: country.isEmpty
              ? 'Not selected'
              : AppStrings.countryNames[country] ?? country,
          onTap: () => _pickCountry(context),
        ),
        const SizedBox(height: 12),
        _PrefTile(
          icon: Icons.currency_exchange,
          label: 'Preferred currency',
          value:
              '$currency  ${AppStrings.currencyNames[currency] ?? ''}'.trim(),
          onTap: () => _pickCurrency(context),
        ),
        const SizedBox(height: 12),
        _PrefTile(
          icon: Icons.translate,
          label: 'Language',
          value: '${_languageName(language)} ($language)',
          onTap: () async {
            final selected = await showModalBottomSheet<String>(
              context: context,
              isScrollControlled: true,
              builder: (ctx) => _PickerSheet(
                title: 'Language',
                items: AppStrings.languages.entries
                    .map((e) => PickerItem(e.value, e.key))
                    .toList(),
              ),
            );
            if (selected != null) onLanguage(selected);
          },
        ),
      ],
    );
  }

  String _languageName(String code) => AppStrings.languages[code] ?? code;
}

class PickerItem {
  final String label;
  final String value;
  PickerItem(this.label, this.value);
}

class _PickerSheet extends StatefulWidget {
  final String title;
  final List<PickerItem> items;
  const _PickerSheet({required this.title, required this.items});

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = query.isEmpty
        ? widget.items
        : widget.items
            .where((i) => i.label.toLowerCase().contains(query.toLowerCase()))
            .toList();
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Row(
                children: [
                  Text(widget.title,
                      style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel')),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: TextField(
                onChanged: (v) => setState(() => query = v),
                decoration: const InputDecoration(
                    hintText: 'Search...', prefixIcon: Icon(Icons.search)),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (ctx, i) {
                  final item = filtered[i];
                  return ListTile(
                    leading: const Icon(Icons.check_circle_outline,
                        color: AppColors.primary, size: 22),
                    title: Text(item.label),
                    onTap: () => Navigator.pop(ctx, item.value),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrefTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  const _PrefTile(
      {required this.icon,
      required this.label,
      required this.value,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF262C38)
                  : const Color(0xFFEEF0F6)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall!.color)),
                  const SizedBox(height: 2),
                  Text(value, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _CategoriesPage extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  const _CategoriesPage({required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      children: [
        const SizedBox(height: 24),
        Text('Pick your categories',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
            'Choose the categories you use most so logging is fast. You can add more later.',
            style:
                TextStyle(color: Theme.of(context).textTheme.bodySmall!.color)),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final cat in AppStrings.defaultCategories)
              _CategoryChip(
                name: cat['name']!,
                color: cat['color']!,
                selected: selected.contains(cat['name']),
                onTap: () => onToggle(cat['name']!),
              ),
          ],
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String name;
  final String color;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip(
      {required this.name,
      required this.color,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final clr = AppColors.colorFromHex(color);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? clr.withValues(alpha: 0.15)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? clr
                : Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF262C38)
                    : const Color(0xFFEEF0F6),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? Icons.check_circle : categoryIcon(name),
                color: selected
                    ? clr
                    : Theme.of(context).textTheme.bodyLarge!.color,
                size: 20),
            const SizedBox(width: 8),
            Text(name,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? clr
                        : Theme.of(context).textTheme.bodyLarge!.color)),
          ],
        ),
      ),
    );
  }
}
