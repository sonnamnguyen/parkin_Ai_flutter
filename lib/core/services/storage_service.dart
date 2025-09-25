import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Token management
  Future<void> saveToken(String token) async {
    await _prefs?.setString(AppConstants.userTokenKey, token);
  }

  String? getToken() {
    return _prefs?.getString(AppConstants.userTokenKey);
  }

  Future<void> removeToken() async {
    await _prefs?.remove(AppConstants.userTokenKey);
  }

  // User data management
  Future<void> saveUserData(String userData) async {
    await _prefs?.setString(AppConstants.userDataKey, userData);
  }

  String? getUserData() {
    return _prefs?.getString(AppConstants.userDataKey);
  }

  Future<void> removeUserData() async {
    await _prefs?.remove(AppConstants.userDataKey);
  }

  // First launch management
  Future<bool> isFirstLaunch() async {
    return _prefs?.getBool(AppConstants.isFirstLaunchKey) ?? true;
  }

  Future<void> setFirstLaunchCompleted() async {
    await _prefs?.setBool(AppConstants.isFirstLaunchKey, false);
  }

  // Recent searches
  List<String> getRecentSearches() {
    return _prefs?.getStringList(AppConstants.recentSearchesKey) ?? <String>[];
  }

  Future<void> saveRecentSearches(List<String> items) async {
    await _prefs?.setStringList(AppConstants.recentSearchesKey, items);
  }

  // Clear all data
  Future<void> clearAll() async {
    await _prefs?.clear();
  }
}
