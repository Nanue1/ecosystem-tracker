import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

/// 添加鱼货记录页面
class CatchEntryScreen extends StatefulWidget {
  final int tripId;
  const CatchEntryScreen({super.key, required this.tripId});

  @override
  State<CatchEntryScreen> createState() => _CatchEntryScreenState();
}

class _CatchEntryScreenState extends State<CatchEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightCtrl = TextEditingController();
  final _lengthCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  File? _photo;
  FishSpecies? _selectedSpecies;
  List<FishSpecies> _species = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSpecies();
  }

  Future<void> _loadSpecies() async {
    final api = context.read<ApiService>();
    final storage = context.read<StorageService>();

    // 优先用缓存
    final cached = storage.getCachedFishSpecies();
    if (cached.isNotEmpty) {
      setState(() => _species = cached);
    }

    try {
      final list = await api.getFishSpecies();
      await storage.cacheFishSpecies(list);
      if (mounted) setState(() => _species = list);
    } catch (e) {
      // 保持用缓存
    }
  }

  /// 拍照
  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (xFile != null) {
      setState(() => _photo = File(xFile.path));
    }
  }

  /// 从相册选
  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (xFile != null) {
      setState(() => _photo = File(xFile.path));
    }
  }

  /// 保存
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final api = context.read<ApiService>();

      String? photoUrl;
      if (_photo != null) {
        photoUrl = await api.uploadPhoto(_photo!);
      }

      final cat = Catch(
        tripId: widget.tripId,
        fishSpeciesId: _selectedSpecies?.id,
        fishSpeciesName: _selectedSpecies?.displayName,
        weight: _weightCtrl.text.isNotEmpty
            ? (double.parse(_weightCtrl.text) * 1000).round()
            : null,
        length: _lengthCtrl.text.isNotEmpty
            ? double.parse(_lengthCtrl.text).round()
            : null,
        photoPath: _photo?.path,
        photoUrl: photoUrl,
        caughtAt: DateTime.now(),
        note: _noteCtrl.text.isNotEmpty ? _noteCtrl.text : null,
      );

      final created = await api.createCatch(cat);
      if (!mounted) return;
      Navigator.pop(context, created);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      appBar: AppBar(
        title: const Text('记录鱼货'),
        backgroundColor: const Color(0xFF2D5016),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 照片区
            _photoSection(),
            const SizedBox(height: 20),

            // 鱼种选择
            _speciesSelector(),
            const SizedBox(height: 16),

            // 重量 + 长度
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _weightCtrl,
                    decoration: const InputDecoration(
                      labelText: '重量 (kg)',
                      prefixIcon: Icon(Icons.scale),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v != null && v.isNotEmpty) {
                        final n = double.tryParse(v);
                        if (n == null || n <= 0) return '请输入有效数值';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lengthCtrl,
                    decoration: const InputDecoration(
                      labelText: '长度 (cm)',
                      prefixIcon: Icon(Icons.straighten),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v != null && v.isNotEmpty) {
                        final n = double.tryParse(v);
                        if (n == null || n <= 0) return '请输入有效数值';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 备注
            TextFormField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                labelText: '备注（可选）',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
                hintText: '例如：水温、天气、使用的假饵',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // 保存按钮
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2D5016),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              label: Text(_saving ? '保存中...' : '保存记录'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📷 鱼货照片',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_photo != null) ...[
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _photo!,
                  width: double.infinity,
                  height: 240,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filled(
                  onPressed: () => setState(() => _photo = null),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('拍照'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.photo_library),
                label: const Text('相册'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _speciesSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🐟 鱼种',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _showSpeciesPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedSpecies?.displayName ?? '点击选择鱼种（必填）',
                    style: TextStyle(
                      color: _selectedSpecies != null ? Colors.black : Colors.grey[500],
                      fontSize: 16,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showSpeciesPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    '选择鱼种',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showAddNewSpeciesDialog();
                    },
                    child: const Text('添加新鱼种'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                itemCount: _species.length,
                itemBuilder: (_, i) {
                  final sp = _species[i];
                  return ListTile(
                    leading: const Icon(Icons.set_meal),
                    title: Text(sp.displayName),
                    subtitle: sp.category != null ? Text(sp.category!) : null,
                    onTap: () {
                      setState(() => _selectedSpecies = sp);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddNewSpeciesDialog() {
    final nameCtrl = TextEditingController();
    final cnCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加新鱼种'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: '学名/英文名',
                hintText: '例如：Micropterus salmoides',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: cnCtrl,
              decoration: const InputDecoration(
                labelText: '中文名',
                hintText: '例如：大口黑鲈',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty && cnCtrl.text.isEmpty) return;
              try {
                final api = context.read<ApiService>();
                final sp = FishSpecies(
                  id: 0,
                  name: nameCtrl.text,
                  chineseName: cnCtrl.text.isNotEmpty ? cnCtrl.text : null,
                );
                final created = await api.addFishSpecies(sp);
                if (!mounted) return;
                setState(() => _species.add(created));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('已添加: ${created.displayName}')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('添加失败: $e')),
                );
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}
