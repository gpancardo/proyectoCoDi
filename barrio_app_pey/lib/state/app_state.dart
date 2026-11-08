import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  AppState(SharedPreferences preferences)
      : _preferences = preferences,
        _isFirstVisit = !(preferences.getBool(_hasProfileKey) ?? false),
        _name = preferences.getString('profile_name') ?? '';

  static const _hasProfileKey = 'has_completed_onboarding';
  final SharedPreferences _preferences;
  bool _isFirstVisit;
  String _name;
  String get photoPath => _preferences.getString('profile_photo_path') ?? '';

  bool get isFirstVisit => _isFirstVisit;
  String get name => _name;
  String get zone => _preferences.getString('profile_zone') ?? '';
  String get neighborhood => _preferences.getString('profile_neighborhood') ?? '';

  Future<void> saveProfile({
    required String name,
    required String phone,
    required String zone,
    required String neighborhood,
    String photoPath = '',
  }) async {
    await _preferences.setString('profile_name', name.trim());
    await _preferences.setString('profile_phone', phone.trim());
    await _preferences.setString('profile_zone', zone);
    await _preferences.setString('profile_neighborhood', neighborhood.trim());
    if (photoPath.isNotEmpty) await _preferences.setString('profile_photo_path', photoPath);
    await _preferences.setBool(_hasProfileKey, true);
    _name = name.trim();
    _isFirstVisit = false;
    notifyListeners();
  }
}
