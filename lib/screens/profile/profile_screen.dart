import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:track_me/core/app_strings.dart';
import 'package:track_me/data/app_repository.dart';
import 'package:track_me/providers/app_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameController;
  String _country = '';
  String _currency = 'USD';
  String _language = 'en';
  int _salaryDay = 15;
  bool _notifyBudget = true;
  bool _notifyGoalCompleted = true;
  bool _notifyGoalMilestones = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final u = context.read<AppState>().user;
    _nameController = TextEditingController(text: u.name);
    _country = u.country;
    _currency = u.preferredCurrency;
    _language = u.language;
    _salaryDay = u.salaryDay;
    _notifyBudget = u.notifyBudgetExceeded;
    _notifyGoalCompleted = u.notifyGoalCompleted;
    _notifyGoalMilestones = u.notifyGoalMilestones;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your name.')));
      return;
    }
    setState(() => _saving = true);
    await AppRepository.instance.updateProfile(
      name: name,
      country: _country,
      preferredCurrency: _currency,
      language: _language,
      salaryDay: _salaryDay,
      notifyBudgetExceeded: _notifyBudget,
      notifyGoalCompleted: _notifyGoalCompleted,
      notifyGoalMilestones: _notifyGoalMilestones,
    );
    if (_currency != context.read<AppState>().currencyCode) {
      await AppRepository.instance.setPrimaryCurrency(_currency);
    }
    await context.read<AppState>().reloadUser();
    context.read<AppState>().bumpData();
    if (mounted) {
      setState(() => _saving = false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text('Name', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(hintText: 'Your name'),
          ),
          const SizedBox(height: 18),
          Text('Country', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _country.isEmpty ? null : _country,
            isExpanded: true,
            items: [
              for (final entry in AppStrings.countryNames.entries)
                DropdownMenuItem(value: entry.key, child: Text('${_flag(entry.key)}  ${entry.value}')),
            ],
            onChanged: (v) {
              setState(() {
                _country = v ?? '';
                final suggested = AppStrings.countryCurrencies[v];
                if (suggested != null && AppStrings.supportedCurrencies.contains(suggested)) {
                  _currency = suggested;
                }
              });
            },
            decoration: const InputDecoration(hintText: 'Select country'),
          ),
          const SizedBox(height: 18),
          Text('Currency', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _currency,
            isExpanded: true,
            items: [
              for (final c in AppStrings.supportedCurrencies)
                DropdownMenuItem(value: c, child: Text('$c  ·  ${AppStrings.currencyNames[c] ?? c}')),
            ],
            onChanged: (v) => setState(() => _currency = v ?? 'USD'),
          ),
          const SizedBox(height: 18),
          Text('Language', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _language,
            isExpanded: true,
            items: [
              for (final entry in AppStrings.languages.entries)
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
            ],
            onChanged: (v) => setState(() => _language = v ?? 'en'),
          ),
          const SizedBox(height: 18),
          Text('Salary day', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: _salaryDay > 28 ? 15 : _salaryDay,
            isExpanded: true,
            items: [
              for (var day = 1; day <= 28; day++)
                DropdownMenuItem(value: day, child: Text('Every ${_ordinal(day)} of the month')),
            ],
            onChanged: (v) => setState(() => _salaryDay = v ?? 15),
            decoration: const InputDecoration(
              hintText: 'Select salary day',
              prefixIcon: Icon(Icons.payments_outlined),
              helperText: 'Loan repayments are scheduled right on this day',
            ),
          ),
          const SizedBox(height: 24),
          Text('Notifications', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Budget exceeded alerts'),
            subtitle: const Text('Get notified when you go over a budget'),
            value: _notifyBudget,
            onChanged: (v) => setState(() => _notifyBudget = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Goal completed alerts'),
            subtitle: const Text('Get notified when you complete a savings goal'),
            value: _notifyGoalCompleted,
            onChanged: (v) => setState(() => _notifyGoalCompleted = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Goal milestone alerts'),
            subtitle: const Text('Be encouraged at 50% and 75% of a goal'),
            value: _notifyGoalMilestones,
            onChanged: (v) => setState(() => _notifyGoalMilestones = v),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.check),
            label: Text(_saving ? 'Saving...' : 'Save Profile'),
          ),
        ],
      ),
    );
  }

  String _ordinal(int n) {
    if (n == 1 || n == 21) return '${n}st';
    if (n == 2 || n == 22) return '${n}nd';
    if (n == 3 || n == 23) return '${n}rd';
    return '${n}th';
  }

  String _flag(String code) {
    const flags = {
      'PH': '🇵🇭', 'US': '🇺🇸', 'GB': '🇬🇧', 'CA': '🇨🇦', 'AU': '🇦🇺', 'JP': '🇯🇵', 'IN': '🇮🇳',
      'SG': '🇸🇬', 'TH': '🇹🇭', 'MY': '🇲🇾', 'ID': '🇮🇩', 'VN': '🇻🇳', 'KR': '🇰🇷', 'TW': '🇹🇼',
      'DE': '🇩🇪', 'FR': '🇫🇷', 'IT': '🇮🇹', 'ES': '🇪🇸', 'BR': '🇧🇷', 'MX': '🇲🇽', 'AE': '🇦🇪',
      'SA': '🇸🇦', 'CH': '🇨🇭', 'SE': '🇸🇪', 'NO': '🇳🇴', 'NL': '🇳🇱',
    };
    return flags[code] ?? '🌐';
  }
}