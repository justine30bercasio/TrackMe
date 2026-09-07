import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import 'package:track_me/data/app_repository.dart';
import 'package:track_me/data/database_helper.dart';
import 'package:track_me/data/models.dart';

class AppState extends ChangeNotifier {
  AppState(this._repository);

  final AppRepository _repository;

  AppUser _user = AppUser();
  bool _darkMode = false;
  bool _initialized = false;
  int _unreadNotifications = 0;
  List<AppNotification> _notifications = [];
  int _dataVersion = 0;

  AppUser get user => _user;
  bool get darkMode => _darkMode;
  bool get initialized => _initialized;
  int get unreadNotifications => _unreadNotifications;
  List<AppNotification> get notifications => _notifications;
  String get currencyCode => _user.preferredCurrency;
  int get dataVersion => _dataVersion;

  void bumpData() {
    _dataVersion++;
    notifyListeners();
  }

  Future<void> init() async {
    _user = await _repository.getUser();
    _darkMode = await _loadDarkPref();
    try {
      await _repository.generateLoanDueNotifications();
    } catch (_) {}
    _initialized = true;
    notifyListeners();
  }

  Future<bool> _loadDarkPref() async {
    try {
      final database = await DatabaseHelper.instance.database;
      final rows = await database.query('app_settings', where: 'key = ?', whereArgs: ['theme'], limit: 1);
      if (rows.isEmpty) return false;
      return rows.first['value'] == 'dark';
    } catch (_) {
      return false;
    }
  }

  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    final database = await DatabaseHelper.instance.database;
    await database.insert('app_settings', {
      'key': 'theme',
      'value': value ? 'dark' : 'light',
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    notifyListeners();
  }

  Future<void> reloadUser() async {
    _user = await _repository.getUser();
    notifyListeners();
  }

  Future<void> refreshNotifications() async {
    _unreadNotifications = await _repository.unreadNotifications();
    _notifications = await _repository.getNotifications();
    notifyListeners();
  }

  Future<void> setUser(AppUser user) async {
    _user = user;
    await _repository.saveUser(user);
    notifyListeners();
  }
}