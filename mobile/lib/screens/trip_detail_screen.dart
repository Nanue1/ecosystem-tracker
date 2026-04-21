import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';

/// 历史出勤详情页
class TripDetailScreen extends StatefulWidget {
  final Trip trip;
  const TripDetailScreen({super.key, required this.trip});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  Trip? _trip;
  List<Catch> _catches = [];
  bool _loading = true;

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
      if (_trip!.id != null) {
        final catches = await api.getCatches(_trip!.id!);
        if (mounted) setState(() => _catches = catches);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final duration = _trip!.endTime != null
        ? _trip!.endTime!.difference(_trip!.startTime)
        : Duration.zero;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      appBar: AppBar(
        title: Text(dateFormat.format(_trip!.startTime)),
        backgroundColor: const Color(0xFF2D5016),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 基本信息卡片
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow(Icons.timer, '出勤时长', _formatDuration(duration)),
                        if (_trip!.location != null)
                          _infoRow(Icons.location_on, '位置', _trip!.location!),
                        if (_trip!.weather != null)
                          _infoRow(Icons.wb_sunny, '天气', _trip!.weather!),
                        if (_trip!.tide != null)
                          _infoRow(Icons.waves, '潮汐', _trip!.tide!),
                        if (_trip!.note != null)
                          _infoRow(Icons.note, '备注', _trip!.note!),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 鱼货统计
                Row(
                  children: [
                    const Text(
                      '🐟 鱼货记录',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D5016),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_catches.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_catches.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text('暂无鱼货记录', style: TextStyle(color: Colors.grey[500])),
                      ),
                    ),
                  )
                else ...[
                  // 鱼种统计
                  _buildSpeciesStats(),
                  const SizedBox(height: 12),
                  ..._catches.map((c) => _catchCard(c)),
                ],
              ],
            ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeciesStats() {
    // 按鱼种分组统计
    final stats = <String, int>{};
    for (final c in _catches) {
      final name = c.fishSpeciesName ?? '未知';
      stats[name] = (stats[name] ?? 0) + 1;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: stats.entries.map((e) {
            return Chip(
              avatar: CircleAvatar(
                backgroundColor: const Color(0xFF2D5016),
                child: Text(
                  '${e.value}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              label: Text(e.key),
            );
          }).toList(),
        ),
      ),
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
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}小时${m}分钟';
    return '${m}分钟';
  }
}
