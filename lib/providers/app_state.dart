import 'dart:convert';

import 'package:crypto/crypto.dart';
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

  // Security state.
  bool _pinEnabled = false;
  String? _pinHash;
  bool _unlocked = true;
  bool _hideBalances = false;

  AppUser get user => _user;
  bool get darkMode => _darkMode;
  bool get initialized => _initialized;
  int get unreadNotifications => _unreadNotifications;
  List<AppNotification> get notifications => _notifications;
  String get currencyCode => _user.preferredCurrency;
  int get dataVersion => _dataVersion;

  bool get pinEnabled => _pinEnabled;
  bool get requiresLock => _pinEnabled && !_unlocked;
  bool get hideBalances => _hideBalances;

  void bumpData() {
    _dataVersion++;
    notifyListeners();
  }

  Future<void> init() async {
    _user = await _repository.getUser();
    _darkMode = await _loadDarkPref();
    await _loadSecuritySettings();
    try {
      await _repository.generateLoanDueNotifications();
    } catch (_) {}
    _initialized = true;
    notifyListeners();
  }

  Future<void> _loadSecuritySettings() async {
    try {
      final s = await _repository.getSecuritySettings();
      _pinEnabled = s['pin_enabled'] == true;
      _pinHash = s['pin_hash'] as String?;
      _hideBalances = s['hide_balances'] == true;
      _unlocked = !_pinEnabled;
    } catch (_) {}
  }

  String hashPin(String pin) =>
      sha256.convert(utf8.encode('trackme:$pin')).toString();

  /// Enables the app lock with the given numeric PIN.
  Future<void> setPin(String pin) async {
    _pinHash = hashPin(pin);
    _pinEnabled = true;
    _unlocked = true;
    await _repository.saveSecuritySettings(pinEnabled: true, pinHash: _pinHash);
    notifyListeners();
  }

  Future<void> disablePin() async {
    _pinEnabled = false;
    _pinHash = null;
    _unlocked = true;
    await _repository.saveSecuritySettings(pinEnabled: false, pinHash: null);
    notifyListeners();
  }

  bool checkPin(String pin) =>
      _pinEnabled && _pinHash != null && hashPin(pin) == _pinHash;

  void unlock() {
    _unlocked = true;
    notifyListeners();
  }

  void lock() {
    if (_pinEnabled) {
      _unlocked = false;
      notifyListeners();
    }
  }

  /// Locks on app resume when a PIN is enabled.
  void lockIfEnabled() {
    if (_pinEnabled) lock();
  }

  Future<void> setHideBalances(bool value) async {
    _hideBalances = value;
    await _repository.saveSecuritySettings(hideBalances: value);
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