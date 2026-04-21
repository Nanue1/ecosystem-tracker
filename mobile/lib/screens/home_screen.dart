import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/location_service.dart';
import 'active_trip_screen.dart';
import 'trip_detail_screen.dart';

/// 首页 — 出勤记录列表
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Trip> _trips = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });

    try {
      final api = context.read<ApiService>();
      final storage = context.read<StorageService>();

      // 优先从服务器加载，离线时用缓存
      try {
        final trips = await api.getMyTrips();
        await storage.cacheRecentTrips(trips);
        if (!mounted) return;
        setState(() => _trips = trips);
      } catch (e) {
        // 网络失败，用缓存
        if (!mounted) return;
        final cached = storage.getCachedTrips();
        setState(() {
          _trips = cached;
          _error = '离线模式，显示缓存数据';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// 开始新出勤
  Future<void> _startNewTrip() async {
    final api = context.read<ApiService>();
    if (api.openid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先登录微信')),
      );
      return;
    }

    _loading = true;
    try {
      final storage = context.read<StorageService>();
      final position = await LocationService().getCurrentPosition();

      final trip = Trip(
        openid: api.openid!,
        startTime: DateTime.now(),
        latitude: position.latitude,
        longitude: position.longitude,
        location: '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
      );

      final created = await api.createTrip(trip);
      await storage.saveDraftTrip(created);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ActiveTripScreen(trip: created),
        ),
      ).then((_) => _loadTrips());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('启动失败: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8), // 钓场沙土色
      appBar: AppBar(
        title: const Text('🎣 路亚生态追踪'),
        backgroundColor: const Color(0xFF2D5016), // 丛林绿
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTrips,
          ),
        ],
      ),
      body: _loading && _trips.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTrips,
              child: _trips.isEmpty
                  ? _buildEmpty()
                  : _buildTripList(accent),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startNewTrip,
        backgroundColor: const Color(0xFF2D5016),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('开始出勤'),
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      children: [
        const SizedBox(height: 100),
        Center(
          child: Column(
            children: [
              Icon(Icons.waves, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('还没有出勤记录', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
              const SizedBox(height: 8),
              Text('点击下方按钮开始记录你的第一次出勤', style: TextStyle(color: Colors.grey[500])),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTripList(Color accent) {
    final dateFormat = DateFormat('MM/dd HH:mm');
    final now = DateTime.now();
    final activeTrips = _trips.where((t) => t.endTime == null).toList();
    final pastTrips = _trips.where((t) => t.endTime != null).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_error != null)
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.cloud_off, size: 16),
                const SizedBox(width: 8),
                Text(_error!, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),

        if (activeTrips.isNotEmpty) ...[
          _sectionTitle('进行中', accent),
          ...activeTrips.map((t) => _tripCard(t, dateFormat, accent, isActive: true)),
          const SizedBox(height: 20),
        ],

        _sectionTitle('历史记录 (${pastTrips.length})', accent),
        if (pastTrips.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(child: Text('暂无历史记录', style: TextStyle(color: Colors.grey[500]))),
          )
        else
          ...pastTrips.map((t) => _tripCard(t, dateFormat, accent)),
      ],
    );
  }

  Widget _sectionTitle(String title, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _tripCard(Trip trip, DateFormat dateFormat, Color accent, {bool isActive = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: isActive ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isActive ? BorderSide(color: accent, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (isActive) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ActiveTripScreen(trip: trip)),
            ).then((_) => _loadTrips());
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip)),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isActive ? Icons.timer : Icons.check_circle,
                    color: isActive ? Colors.green : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dateFormat.format(trip.startTime),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '进行中',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                ],
              ),
              if (trip.location != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        trip.location!,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (trip.weather != null || trip.note != null) ...[
                const SizedBox(height: 4),
                Text(
                  [trip.weather, trip.note].whereType<String>().join(' · '),
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
