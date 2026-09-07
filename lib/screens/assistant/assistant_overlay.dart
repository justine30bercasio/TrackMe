import 'package:flutter/material.dart';

import 'package:track_me/app_navigator.dart';
import 'package:track_me/core/theme.dart';
import 'package:track_me/screens/assistant/assistant_chat_view.dart';
import 'package:track_me/screens/assistant/assistant_screen.dart';

const String _splashRoute = '/';
const String _panelRoute = '/assistant-panel';

/// Tracks which route is on top so the floating assistant bubble hides itself
/// while the splash screen or any assistant surface (panel / full screen) is
/// open, and reappears everywhere else.
class AssistantNavigatorObserver extends NavigatorObserver {
  AssistantNavigatorObserver._();

  static final AssistantNavigatorObserver instance = AssistantNavigatorObserver._();

  final ValueNotifier<int> revision = ValueNotifier(0);
  bool _shouldHide = false;

  bool get shouldHide => _shouldHide;

  void _update(Route<dynamic>? top) {
    final name = top?.settings.name;
    _shouldHide = name == _splashRoute || name == _panelRoute || name == AssistantScreen.routeName;
    revision.value++;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _update(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _update(previousRoute);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) => _update(previousRoute);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) => _update(newRoute);
}

/// App-wide wrapper (MaterialApp.builder) that floats the assistant chat
/// bubble above every page.
class AssistantOverlay extends StatelessWidget {
  final Widget child;

  const AssistantOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        ValueListenableBuilder<int>(
          valueListenable: AssistantNavigatorObserver.instance.revision,
          builder: (context, _, __) {
            if (AssistantNavigatorObserver.instance.shouldHide) return const SizedBox.shrink();
            return Positioned(
              left: 16,
              bottom: MediaQuery.paddingOf(context).bottom + 92,
              child: const _AssistantBubble(),
            );
          },
        ),
      ],
    );
  }
}

class _AssistantBubble extends StatelessWidget {
  const _AssistantBubble();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => appNavigatorKey.currentState?.push(AssistantPanelRoute()),
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: AppColors.brandGradient),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 27),
              Positioned(
                right: 3,
                bottom: 3,
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: AppColors.income,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A Messenger-style chat window that floats over the current page.
class AssistantPanelRoute extends PageRouteBuilder<void> {
  AssistantPanelRoute()
      : super(
          settings: const RouteSettings(name: _panelRoute),
          opaque: false,
          barrierColor: Colors.black.withValues(alpha: 0.35),
          barrierDismissible: true,
          transitionDuration: const Duration(milliseconds: 280),
          reverseTransitionDuration: const Duration(milliseconds: 220),
          pageBuilder: (context, animation, secondaryAnimation) => const _AssistantPanel(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            return SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(curved),
              child: child,
            );
          },
        );
}

class _AssistantPanel extends StatelessWidget {
  const _AssistantPanel();

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final surface = Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark : Colors.white;

    return Padding(
      padding: EdgeInsets.only(top: 56, bottom: viewInsets.bottom),
      child: Material(
        color: surface,
        elevation: 12,
        clipBehavior: Clip.antiAlias,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Column(
          children: [
            _buildHeader(context),
            const Expanded(child: AssistantChatView()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 6, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: AppColors.brandGradient),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TrackMe CSR', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                Text('Online · replies instantly & logs expenses', style: TextStyle(fontSize: 11.5, color: Theme.of(context).textTheme.bodySmall!.color)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Expand to full screen',
            icon: const Icon(Icons.open_in_full),
            onPressed: () => appNavigatorKey.currentState?.pushReplacement(
              MaterialPageRoute(
                settings: const RouteSettings(name: AssistantScreen.routeName),
                builder: (_) => const AssistantScreen(),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}