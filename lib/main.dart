import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:track_me/core/app_strings.dart';
import 'package:track_me/core/theme.dart';
import 'package:track_me/data/app_repository.dart';
import 'package:track_me/providers/app_state.dart';
import 'package:track_me/screens/splash_screen.dart';
import 'package:track_me/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  final appState = AppState(AppRepository.instance);
  await appState.init();
  runApp(ExpenseTrackerApp(appState: appState));
}

class ExpenseTrackerApp extends StatelessWidget {
  final AppState appState;

  const ExpenseTrackerApp({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: appState,
      child: Consumer<AppState>(
        builder: (context, state, _) {
          return MaterialApp(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: state.darkMode ? ThemeMode.dark : ThemeMode.light,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}