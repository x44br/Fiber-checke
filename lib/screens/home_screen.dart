import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/ont_reading.dart';
import '../services/ont_service.dart';
import '../widgets/metric_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _ipController = TextEditingController(text: '192.168.100.1');
  final _userController = TextEditingController(text: 'telecomadmin');
  final _passController = TextEditingController(text: 'admintelecom');

  final _service = OntService();
  bool _busy = false;
  OntReading? _reading;
  String _status = 'اضغط "فحص الآن" للبدء';

  @override
  void dispose() {
    _ipController.dispose();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    setState(() {
      _busy = true;
      _status = 'جاري الاتصال بالجهاز...';
      _reading = null;
    });

    try {
      final r = await _service.readHuawei(
        ip: _ipController.text.trim(),
        user: _userController.text.trim(),
        pass: _passController.text,
      );
      if (!mounted) return;
      setState(() {
        _reading = r;
        _status = r.statusArabic;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() =>
          _status = 'فشل: ${e.toString().replaceFirst('Exception: ', '')}');
      _toast(_status);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Color get _statusColor {
    final s = _reading?.status;
    if (s == LineStatus.ok) return green;
    if (s == LineStatus.weakSignal) return amber;
    if (s == LineStatus.noSignal || s == LineStatus.los) return red;
    return muted;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(Icons.settings_input_antenna, color: green),
              SizedBox(width: 8),
              Text('FiberCheck',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _statusBanner(),
            const SizedBox(height: 16),
            _connectionCard(),
            const SizedBox(height: 16),
            if (_reading != null) ...[
              const Text('القراءات الضوئية',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _metricsGrid(),
              const SizedBox(height: 16),
              const Text('معلومات النظام',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _systemInfo(),
            ],
            const SizedBox(height: 24),
            const Text('FiberCheck • v1.0',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _statusBanner() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_statusColor.withOpacity(0.15), panel],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _statusColor.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Icon(
              _reading == null
                  ? Icons.info_outline
                  : (_reading!.status == LineStatus.ok
                      ? Icons.check_circle
                      : Icons.warning_amber),
              color: _statusColor,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(_status,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ),
            if (_busy)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      );

  Widget _connectionCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('بيانات الاتصال بالجهاز',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            TextField(
              controller: _ipController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'عنوان IP',
                prefixIcon: Icon(Icons.router, color: cyan),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _userController,
              decoration: const InputDecoration(
                labelText: 'اسم المستخدم',
                prefixIcon: Icon(Icons.person_outline, color: cyan),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور',
                prefixIcon: Icon(Icons.lock_outline, color: cyan),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : _scan,
                icon: const Icon(Icons.search),
                label: Text(_busy ? 'جاري الفحص...' : 'فحص الآن'),
              ),
            ),
          ],
        ),
      );

  Widget _metricsGrid() {
    final r = _reading!;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: 'RX Power',
                value: r.rxPower?.toStringAsFixed(2) ?? '--',
                unit: 'dBm',
                icon: Icons.south_west,
                color: cyan,
                isGood: (r.rxPower ?? -99) >= -25,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricCard(
                title: 'TX Power',
                value: r.txPower?.toStringAsFixed(2) ?? '--',
                unit: 'dBm',
                icon: Icons.north_east,
                color: green,
                isGood: (r.txPower ?? 0) >= 0.5 && (r.txPower ?? 0) <= 5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: 'الحرارة',
                value: r.temperature?.toStringAsFixed(0) ?? '--',
                unit: '°C',
                icon: Icons.thermostat,
                color: amber,
                isGood: (r.temperature ?? 100) < 60,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricCard(
                title: 'الجهد',
                value: r.voltage?.toStringAsFixed(2) ?? '--',
                unit: 'V',
                icon: Icons.bolt,
                color: amber,
                isGood: (r.voltage ?? 0) >= 3.1 && (r.voltage ?? 0) <= 3.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _systemInfo() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            _infoRow('الطراز', _reading!.model),
            _infoRow('الرقم التسلسلي', _reading!.serialNumber ?? '—'),
            _infoRow('حالة التسجيل', _reading!.registrationStatus ?? '—'),
            _infoRow('CPU', '${_reading!.cpuUsage ?? '—'} %'),
            _infoRow('الذاكرة', '${_reading!.memoryUsage ?? '—'} %'),
          ],
        ),
      );

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              child: Text(label,
                  style: const TextStyle(color: muted, fontSize: 13)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ],
        ),
      );
}