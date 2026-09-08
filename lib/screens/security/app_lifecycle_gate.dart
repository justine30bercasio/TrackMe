import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:track_me/providers/app_state.dart';

/// Locks TrackMe with the PIN when the app returns to the foreground.
class AppLifecycleGate extends StatefulWidget {
  final Widget child;

  const AppLifecycleGate({super.key, required this.child});

  @override
  State<AppLifecycleGate> createState() => _AppLifecycleGateState();
}

class _AppLifecycleGateState extends State<AppLifecycleGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<AppState>().lockIfEnabled();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}