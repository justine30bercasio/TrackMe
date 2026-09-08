import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:track_me/core/theme.dart';
import 'package:track_me/providers/app_state.dart';

class PinLockScreen extends StatefulWidget {
  const PinLockScreen({super.key});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  static const _pinLength = 4;

  final _entered = <String>[];
  bool _incorrect = false;

  Future<void> _onDigit(String digit) async {
    if (_entered.length >= _pinLength) return;
    HapticFeedback.selectionClick();
    setState(() {
      _entered.add(digit);
      _incorrect = false;
    });
    if (_entered.length == _pinLength) {
      final pin = _entered.join();
      final state = context.read<AppState>();
      if (state.checkPin(pin)) {
        await Future.delayed(const Duration(milliseconds: 120));
        if (!mounted) return;
        state.unlock();
      } else {
        HapticFeedback.vibrate();
        setState(() => _incorrect = true);
        await Future.delayed(const Duration(milliseconds: 350));
        if (!mounted) return;
        setState(() {
          _entered.clear();
          _incorrect = false;
        });
      }
    }
  }

  void _delete() {
    if (_entered.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _entered.removeLast());
  }

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).textTheme.bodySmall!.color!;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(24),
              ),
              alignment: Alignment.center,
              child:
                  const Icon(Icons.lock_outline, color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: 18),
            const Text('TrackMe',
                style:
                    TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('Enter your PIN to continue',
                style: TextStyle(fontSize: 13, color: secondary)),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pinLength, (i) {
                final filled = i < _entered.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled
                        ? AppColors.primary
                        : Theme.of(context).brightness == Brightness.dark
                            ? AppColors.surfaceDark2
                            : const Color(0xFFD9DBE3),
                    border: filled
                        ? null
                        : Border.all(color: secondary.withValues(alpha: 0.4)),
                  ),
                );
              }),
            ),
            if (_incorrect) ...[
              const SizedBox(height: 12),
              const Text('Incorrect PIN. Try again.',
                  style: TextStyle(color: AppColors.danger, fontSize: 13)),
            ],
            const Spacer(flex: 2),
            _Keypad(onDigit: _onDigit, onDelete: _delete),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onDelete;

  const _Keypad({required this.onDigit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.onSurface;
    Widget key(String label, {Widget? child, VoidCallback? action}) {
      return Expanded(
        child: AspectRatio(
          aspectRatio: 1.25,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: action,
                child: Center(
                  child: child ??
                      Text(label,
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              color: primary)),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          Row(children: [
            key('1', action: () => onDigit('1')),
            key('2', action: () => onDigit('2')),
            key('3', action: () => onDigit('3')),
          ]),
          Row(children: [
            key('4', action: () => onDigit('4')),
            key('5', action: () => onDigit('5')),
            key('6', action: () => onDigit('6')),
          ]),
          Row(children: [
            key('7', action: () => onDigit('7')),
            key('8', action: () => onDigit('8')),
            key('9', action: () => onDigit('9')),
          ]),
          Row(children: [
            const Expanded(child: SizedBox()),
            key('0', action: () => onDigit('0')),
            key('del',
                child: Icon(Icons.backspace_outlined,
                    color: Theme.of(context).colorScheme.onSurface),
                action: onDelete),
          ]),
        ],
      ),
    );
  }
}