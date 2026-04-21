import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/models.dart';

/// API 服务层 — 复用 Flask 后端
class ApiService {
  // TODO: 部署后替换为你的服务器地址
  // 开发阶段使用本地地址，App 在手机上需要改成实际服务器 IP/域名
  static const String _baseUrl = 'http://YOUR_SERVER_IP:5000/api';

  String? _openid;

  void setOpenid(String openid) => _openid = openid;
  String? get openid => _openid;

  // ===========================
  // 通用请求方法
  // ===========================

  Future<Map<String, dynamic>> _get(String path) async {
    final resp = await http.get(Uri.parse('$_baseUrl$path'));
    _check(resp);
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  Future<List<dynamic>> _getList(String path) async {
    final resp = await http.get(Uri.parse('$_baseUrl$path'));
    _check(resp);
    return jsonDecode(resp.body) as List<dynamic>;
  }

  Future<Map<String, dynamic>> _post(
      String path, Map<String, dynamic> data) async {
    final resp = await http.post(
      Uri.parse('$_baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    _check(resp);
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  void _check(http.Response resp) {
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw ApiException(resp.statusCode, resp.body);
    }
  }

  // ===========================
  // 出勤记录
  // ===========================

  /// 创建出勤记录
  Future<Trip> createTrip(Trip trip) async {
    final data = await _post('/trips', trip.toJson());
    return Trip.fromJson(data);
  }

  /// 获取我的所有出勤记录
  Future<List<Trip>> getMyTrips() async {
    final list = await _getList('/trips?openid=$_openid');
    return list.map((e) => Trip.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 结束出勤（更新结束时间）
  Future<Trip> endTrip(int tripId, {String? note}) async {
    final resp = await http.put(
      Uri.parse('$_baseUrl/trips/$tripId/end'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'note': note, 'openid': _openid}),
    );
    _check(resp);
    return Trip.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  // ===========================
  // GPS 标记点
  // ===========================

  Future<Waypoint> createWaypoint(Waypoint wp) async {
    final data = await _post('/waypoints', wp.toJson());
    return Waypoint.fromJson(data);
  }

  Future<List<Waypoint>> getWaypoints(int tripId) async {
    final list = await _getList('/waypoints?trip_id=$tripId');
    return list
        .map((e) => Waypoint.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ===========================
  // 鱼货记录
  // ===========================

  Future<Catch> createCatch(Catch cat) async {
    final data = await _post('/catches', cat.toJson());
    return Catch.fromJson(data);
  }

  Future<List<Catch>> getCatches(int tripId) async {
    final list = await _getList('/catches/$tripId');
    return list
        .map((e) => Catch.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ===========================
  // 图片上传
  // ===========================

  /// 上传图片，返回服务器上的 URL
  Future<String> uploadPhoto(File file) async {
    final req = http.MultipartRequest('POST', Uri.parse('$_baseUrl/upload'));
    req.files.add(await http.MultipartFile.fromPath('file', file.path));
    if (_openid != null) req.fields['openid'] = _openid!;

    final streamed = await req.send();
    final resp = await http.Response.fromStream(streamed);
    _check(resp);
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    return body['url'] as String;
  }

  // ===========================
  // 鱼种库
  // ===========================

  Future<List<FishSpecies>> getFishSpecies() async {
    final list = await _getList('/fish-species');
    return list
        .map((e) => FishSpecies.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<FishSpecies> addFishSpecies(FishSpecies species) async {
    final data = await _post('/fish-species', species.toJson());
    return FishSpecies.fromJson(data);
  }

  // ===========================
  // 天气 & 潮汐
  // ===========================

  Future<Weather> getWeather(double lat, double lon) async {
    final data = await _get('/weather?lat=$lat&lon=$lon');
    return Weather.fromJson(data);
  }

  Future<List<Tide>> getTide(double lat, double lon) async {
    final list = await _getList('/tide?lat=$lat&lon=$lon');
    return list
        .map((e) => Tide.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ===========================
  // 登录（微信）
  // ===========================

  /// 用微信 code 换 openid
  Future<String> loginWithWechat(String code) async {
    final data = await _post('/login', {'code': code});
    _openid = data['openid'] as String;
    return _openid!;
  }
}

/// API 异常
class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.body)
      : message = 'API Error $statusCode: $body';

  @override
  String toString() => message;
}
