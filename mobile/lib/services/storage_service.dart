import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// 本地持久化存储（SharedPreferences + SQLite）
/// 用于离线缓存和草稿保存
class StorageService {
  static const String _kOpenid = 'openid';
  static const String _kDraftTrip = 'draft_trip';
  static const String _kFishSpecies = 'fish_species';
  static const String _kRecentTrips = 'recent_trips';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ===========================
  // openid
  // ===========================

  String? getOpenid() => _prefs.getString(_kOpenid);
  Future<void> setOpenid(String openid) => _prefs.setString(_kOpenid, openid);
  Future<void> clearOpenid() => _prefs.remove(_kOpenid);

  // ===========================
  // 鱼种库缓存
  // ===========================

  Future<void> cacheFishSpecies(List<FishSpecies> species) async {
    final json = jsonEncode(species.map((e) => e.toJson()).toList());
    await _prefs.setString(_kFishSpecies, json);
  }

  List<FishSpecies> getCachedFishSpecies() {
    final raw = _prefs.getString(_kFishSpecies);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => FishSpecies.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ===========================
  // 最近出勤草稿（还没结束的）
  // ===========================

  Future<void> saveDraftTrip(Trip trip) async {
    await _prefs.setString(_kDraftTrip, jsonEncode(trip.toJson()));
  }

  Trip? getDraftTrip() {
    final raw = _prefs.getString(_kDraftTrip);
    if (raw == null) return null;
    return Trip.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> clearDraftTrip() => _prefs.remove(_kDraftTrip);

  // ===========================
  // 最近出勤列表缓存（离线看）
  // ===========================

  Future<void> cacheRecentTrips(List<Trip> trips) async {
    final json = jsonEncode(trips.map((e) => e.toJson()).toList());
    await _prefs.setString(_kRecentTrips, json);
  }

  List<Trip> getCachedTrips() {
    final raw = _prefs.getString(_kRecentTrips);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => Trip.fromJson(e as Map<String, dynamic>)).toList();
  }
}
