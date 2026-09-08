import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:track_me/core/common_widgets.dart';
import 'package:track_me/core/theme.dart';
import 'package:track_me/providers/app_state.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  Future<void> _enablePin() async {
    final pin = await _promptPin();
    if (pin == null) return;
    final confirm = await _promptPin(message: 'Confirm your PIN');
    if (confirm == null) return;
    if (pin != confirm) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PINs did not match. Try again.')),
      );
      return;
    }
    await context.read<AppState>().setPin(pin);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('App lock enabled.')),
    );
  }

  Future<String?> _promptPin({String message = 'Create a 4-digit PIN'}) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(message),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          decoration: const InputDecoration(
            labelText: 'PIN',
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _disablePin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Turn off app lock?'),
        content: const Text('TrackMe will no longer ask for a PIN.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Turn off'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await context.read<AppState>().disablePin();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('App lock disabled.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final secondary = Theme.of(context).textTheme.bodySmall!.color!;
    return Scaffold(
      appBar: AppBar(title: const Text('Security & privacy')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.verified_user_outlined, color: AppColors.primary),
                    SizedBox(width: 10),
                    Text('Private by design',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Your financial data is stored only on this device. '
                  'No accounts, no cloud, no tracking.',
                  style: TextStyle(fontSize: 13, color: secondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionTileGroup(
            title: 'App lock',
            children: [
              _SettingsTile(
                icon: Icons.lock_outline,
                title: state.pinEnabled ? 'Change PIN' : 'Enable PIN lock',
                subtitle: state.pinEnabled
                    ? 'Lock TrackMe with a 4-digit PIN'
                    : 'Protect TrackMe with a 4-digit PIN',
                onTap: _enablePin,
              ),
              if (state.pinEnabled)
                _SettingsTile(
                  icon: Icons.lock_open_outlined,
                  title: 'Turn off PIN lock',
                  subtitle: 'Remove the PIN requirement',
                  onTap: _disablePin,
                ),
              _SettingsTile(
                icon: Icons.visibility_outlined,
                title: 'Hide balances',
                subtitle:
                    'Mask amounts on the dashboard and wallet',
                trailing: Switch(
                  value: state.hideBalances,
                  onChanged: (v) => state.setHideBalances(v),
                ),
              ),
            ],
          ),
        ],
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