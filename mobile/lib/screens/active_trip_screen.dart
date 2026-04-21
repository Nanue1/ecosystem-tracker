import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/location_service.dart';
import 'catch_entry_screen.dart';

/// 进行中出勤页面
class ActiveTripScreen extends StatefulWidget {
  final Trip trip;
  const ActiveTripScreen({super.key, required this.trip});

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  late Trip _trip;
  List<Catch> _catches = [];
  Weather? _weather;
  List<Tide> _tides = [];
  Position? _currentPos;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final api = context.read<ApiService>();

      // 并行加载天气、潮汐、鱼货记录
      final futures = <Future>[];
      futures.add(_loadWeather());
      futures.add(_loadTides());
      futures.add(_loadCatches());
      futures.add(_updateLocation());

      await Future.wait(futures);

      // 更新草稿
      final storage = context.read<StorageService>();
      await storage.saveDraftTrip(_trip);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadWeather() async {
    if (_trip.latitude == null || _trip.longitude == null) return;
    try {
      final api = context.read<ApiService>();
      final w = await api.getWeather(_trip.latitude!, _trip.longitude!);
      if (mounted) setState(() => _weather = w);
    } catch (_) {}
  }

  Future<void> _loadTides() async {
    if (_trip.latitude == null || _trip.longitude == null) return;
    try {
      final api = context.read<ApiService>();
      final tides = await api.getTide(_trip.latitude!, _trip.longitude!);
      if (mounted) setState(() => _tides = tides.take(3).toList());
    } catch (_) {}
  }

  Future<void> _loadCatches() async {
    if (_trip.id == null) return;
    try {
      final api = context.read<ApiService>();
      final catches = await api.getCatches(_trip.id!);
      if (mounted) setState(() => _catches = catches);
    } catch (_) {}
  }

  Future<void> _updateLocation() async {
    try {
      final loc = context.read<LocationService>();
      final pos = await loc.getCurrentPosition();
      if (mounted) {
        setState(() => _currentPos = pos);
        _trip = _trip.copyWith(
          latitude: pos.latitude,
          longitude: pos.longitude,
          location: '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}',
        );
      }
    } catch (_) {}
  }

  /// 添加鱼货记录
  Future<void> _addCatch() async {
    if (!mounted) return;
    final result = await Navigator.push<Catch>(
      context,
      MaterialPageRoute(
        builder: (_) => CatchEntryScreen(tripId: _trip.id!),
      ),
    );
    if (result != null) {
      setState(() => _catches.add(result));
    }
  }

  /// 结束出勤
  Future<void> _endTrip() async {
    final note = await _showEndTripDialog();
    if (note == null) return;

    setState(() => _loading = true);
    try {
      final api = context.read<ApiService>();
      await api.endTrip(_trip.id!, note: note);
      final storage = context.read<StorageService>();
      await storage.clearDraftTrip();
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('结束失败: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String?> _showEndTripDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('结束出勤'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '备注（可选）',
            hintText: '今天钓得怎么样？',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('确认结束'),
          ),
        ],
      ),
    );
  }

  /// 添加 GPS 标记点
  Future<void> _addWaypoint() async {
    if (!mounted || _trip.id == null) return;
    final name = await _showWaypointNameDialog();
    if (name == null || _currentPos == null) return;

    try {
      final api = context.read<ApiService>();
      await api.createWaypoint(Waypoint(
        tripId: _trip.id!,
        name: name,
        latitude: _currentPos!.latitude,
        longitude: _currentPos!.longitude,
      ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ 标记 "$name" 已保存')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('标记失败: $e')),
      );
    }
  }

  Future<String?> _showWaypointNameDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加位置标记'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '标记名称',
            hintText: '例如：经典标点、藏鱼结构',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final duration = DateTime.now().difference(_trip.startTime);
    final durationStr = _formatDuration(duration);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      appBar: AppBar(
        title: Text('出勤中 · $durationStr'),
        backgroundColor: const Color(0xFF2D5016),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on),
            onPressed: _addWaypoint,
            tooltip: '添加位置标记',
          ),
          IconButton(
            icon: const Icon(Icons.stop_circle),
            onPressed: _endTrip,
            tooltip: '结束出勤',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 天气 + 潮汐卡片
            _buildInfoCards(),
            const SizedBox(height: 16),

            // 当前 GPS
            if (_currentPos != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.my_location, color: Color(0xFF2D5016)),
                  title: const Text('当前位置'),
                  subtitle: Text(
                    '${_currentPos!.latitude.toStringAsFixed(5)}, ${_currentPos!.longitude.toStringAsFixed(5)}',
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: _updateLocation,
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // 鱼货记录
            _buildCatchesSection(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCatch,
        backgroundColor: const Color(0xFF2D5016),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_a_photo),
        label: const Text('记录鱼货'),
      ),
    );
  }

  Widget _buildInfoCards() {
    return Row(
      children: [
        Expanded(child: _weatherCard()),
        const SizedBox(width: 12),
        Expanded(child: _tideCard()),
      ],
    );
  }

  Widget _weatherCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.wb_sunny, size: 18, color: Colors.orange),
                const SizedBox(width: 6),
                const Text('天气', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            if (_weather != null) ...[
              Text(
                _weather!.condition,
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                '${_weather!.temperature.toStringAsFixed(1)}°C',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              if (_weather!.windSpeed != null)
                Text('风 ${_weather!.windSpeed!.toStringAsFixed(1)} m/s',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ] else
              const Text('加载中...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _tideCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.waves, size: 18, color: Colors.blue),
                const SizedBox(width: 6),
                const Text('潮汐', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            if (_tides.isNotEmpty) ...[
              ..._tides.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    Icon(
                      t.type == 'high' ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 14,
                      color: t.type == 'high' ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${DateFormat('HH:mm').format(t.time)} ${t.type == 'high' ? '涨潮' : '退潮'}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              )),
            ] else
              const Text('加载中...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildCatchesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🐟 鱼货记录 (${_catches.length})',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (_catches.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.set_meal, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Text('还没记录到鱼', style: TextStyle(color: Colors.grey[500])),
                    const SizedBox(height: 4),
                    Text(
                      '点击下方按钮拍照记录鱼货',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ..._catches.map((c) => _catchCard(c)),
      ],
    );
  }

  Widget _catchCard(Catch cat) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: cat.photoUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  cat.photoUrl!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 56,
                    height: 56,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported, size: 24),
                  ),
                ),
              )
            : Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.set_meal, color: Colors.grey),
              ),
        title: Text(cat.fishSpeciesName ?? '未知鱼种'),
        subtitle: Text([
          if (cat.weight != null) '${(cat.weight! / 1000).toStringAsFixed(2)}kg',
          if (cat.length != null) '${cat.length}cm',
          DateFormat('HH:mm').format(cat.caughtAt),
        ].join(' · ')),
        trailing: cat.note != null
            ? Tooltip(message: cat.note!, child: const Icon(Icons.note, size: 18))
            : null,
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}
