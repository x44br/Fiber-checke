import 'dart:io';

import 'package:flutter/material.dart';

void main() {
  runApp(const FiberCheckApp());
}

const Color background = Color(0xFF0B1120);
const Color surface = Color(0xFF1E293B);
const Color cyan = Color(0xFF38BDF8);
const Color green = Color(0xFF4ADEB0);
const Color secondaryText = Color(0xFF94A3B8);

class FiberCheckApp extends StatelessWidget {
  const FiberCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FiberCheck',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: cyan,
          brightness: Brightness.dark,
        ),
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final TextEditingController ipController =
      TextEditingController(text: '192.168.100.1');

  String connectionType = 'Telnet';
  String status = 'غير متصل';
  int selectedTab = 0;
  bool isScanning = false;
  List<String> scanResults = [];

  @override
  void dispose() {
    ipController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.right),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> scanDevice() async {
    final host = ipController.text.trim();
    final address = InternetAddress.tryParse(host);

    if (address == null) {
      showMessage('أدخل عنوان IP صحيحاً، مثل 192.168.100.1');
      return;
    }

    setState(() {
      isScanning = true;
      scanResults = [];
      status = 'جاري فحص المنافذ';
    });

    const ports = <int, String>{
      80: 'HTTP',
      443: 'HTTPS',
      22: 'SSH',
      23: 'Telnet',
      8080: 'HTTP بديل',
      8443: 'HTTPS بديل',
    };

    final found = <String>[];

    try {
      for (final entry in ports.entries) {
        Socket? socket;
        try {
          socket = await Socket.connect(
            host,
            entry.key,
            timeout: const Duration(milliseconds: 1200),
          );
          found.add('${entry.value}: المنفذ ${entry.key} مفتوح');
        } on SocketException {
          // المنفذ مغلق أو غير متاح من الشبكة الحالية.
        } on IOException {
          // خطأ اتصال؛ نواصل فحص بقية المنافذ.
        } finally {
          socket?.destroy();
        }

        if (!mounted) return;
      }

      setState(() {
        scanResults = found;
        status = found.isEmpty
            ? 'لم يُكتشف منفذ إدارة من المنافذ المفحوصة'
            : 'اكتمل فحص المنافذ';
      });

      showMessage(
        found.isEmpty
            ? 'لم يُكتشف منفذ مفتوح. هذا لا يعني بالضرورة أن الجهاز غير متصل.'
            : 'اكتمل الفحص: عُثر على ${found.length} منفذ متاح',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => status = 'تعذر إكمال الفحص');
      showMessage('تعذر إكمال الفحص: $e');
    } finally {
      if (mounted) {
        setState(() => isScanning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: background,
          title: const Row(
            children: [
              Icon(Icons.settings_input_antenna, color: green, size: 28),
              SizedBox(width: 10),
              Text(
                'FiberCheck',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () => showMessage(
                'إعدادات التطبيق ستضاف لاحقاً',
              ),
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
        body: IndexedStack(
          index: selectedTab,
          children: [
            buildDashboard(),
            buildDiagnostics(),
            buildSettings(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          backgroundColor: surface,
          indicatorColor: cyan.withOpacity(0.15),
          selectedIndex: selectedTab,
          onDestinationSelected: (index) {
            setState(() => selectedTab = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard, color: cyan),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: Icon(Icons.monitor_heart_outlined),
              selectedIcon: Icon(Icons.monitor_heart, color: cyan),
              label: 'التشخيص',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings, color: cyan),
              label: 'الإعدادات',
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDashboard() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFF173B56), Color(0xFF172033)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            border: Border.all(color: cyan.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'التشخيص الضوئي',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'مراقبة جهاز ONU/ONT',
                style: TextStyle(color: secondaryText),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Icon(
                    Icons.circle,
                    color: status == 'متصل' || status == 'اكتمل فحص المنافذ'
                        ? green
                        : Colors.orangeAccent,
                    size: 12,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      status,
                      style: TextStyle(
                        color: status == 'متصل' ||
                                status == 'اكتمل فحص المنافذ'
                            ? green
                            : Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(Icons.router, color: cyan, size: 34),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const SectionTitle(title: 'القراءات الضوئية'),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(
              child: MetricCard(
                icon: Icons.south_west,
                title: 'Rx Power',
                value: '--',
                unit: 'dBm',
                color: cyan,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                icon: Icons.north_east,
                title: 'Tx Power',
                value: '--',
                unit: 'dBm',
                color: green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(
              child: MetricCard(
                icon: Icons.thermostat,
                title: 'الحرارة',
                value: '--',
                unit: '°C',
                color: Colors.orangeAccent,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                icon: Icons.bolt,
                title: 'الجهد',
                value: '--',
                unit: 'V',
                color: Colors.amber,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const SectionTitle(title: 'الاتصال بالجهاز'),
        const SizedBox(height: 12),
        buildConnectionCard(),
        const SizedBox(height: 24),
        const SectionTitle(title: 'أدوات سريعة'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: QuickAction(
                icon: Icons.network_ping,
                title: 'فحص Ping',
                onTap: () => setState(() => selectedTab = 1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: QuickAction(
                icon: Icons.receipt_long,
                title: 'التقارير',
                onTap: () => showMessage('قسم التقارير قيد التطوير'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: QuickAction(
                icon: Icons.memory,
                title: 'معلومات النظام',
                onTap: () => showMessage(
                  'قراءات النظام ستظهر بعد ربط واجهة إدارة الجهاز',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: QuickAction(
                icon: Icons.health_and_safety_outlined,
                title: 'صحة الجهاز',
                onTap: () => setState(() => selectedTab = 1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Center(
          child: Text(
            'FiberCheck • إصدار تجريبي',
            style: TextStyle(color: secondaryText, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget buildConnectionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'عنوان IP للجهاز',
            style: TextStyle(color: secondaryText),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: ipController,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.router, color: cyan),
              filled: true,
              fillColor: background,
              hintText: '192.168.100.1',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'طريقة الاتصال',
            style: TextStyle(color: secondaryText),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: connectionType,
            decoration: InputDecoration(
              filled: true,
              fillColor: background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'Telnet', child: Text('Telnet')),
              DropdownMenuItem(value: 'SSH', child: Text('SSH')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => connectionType = value);
              }
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: isScanning ? null : scanDevice,
              icon: isScanning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.travel_explore),
              label: Text(isScanning ? 'جاري فحص المنافذ...' : 'فحص الجهاز'),
              style: FilledButton.styleFrom(
                backgroundColor: green,
                foregroundColor: background,
              ),
            ),
          ),
          if (isScanning) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
          if (scanResults.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'المنافذ المكتشفة',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...scanResults.map(
              (result) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: green, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(result)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          const Text(
            'فحص المنافذ لا يسجّل الدخول إلى الجهاز ولا يقرأ بياناته الداخلية.',
            style: TextStyle(color: secondaryText, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget buildDiagnostics() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        SectionTitle(title: 'تشخيص الجهاز'),
        SizedBox(height: 12),
        InfoTile(
          icon: Icons.network_ping,
          title: 'Ping',
          description: 'قياس زمن الاستجابة وفقدان الحزم - لم يُربط بعد',
        ),
        InfoTile(
          icon: Icons.lan_outlined,
          title: 'منافذ LAN',
          description: 'تحتاج إلى واجهة إدارة الجهاز',
        ),
        InfoTile(
          icon: Icons.memory,
          title: 'RAM وCPU',
          description: 'تحتاج إلى دعم من واجهة الجهاز',
        ),
        InfoTile(
          icon: Icons.warning_amber_outlined,
          title: 'الإنذارات',
          description: 'تحتاج إلى بيانات من الجهاز',
        ),
        InfoTile(
          icon: Icons.cable,
          title: 'حالة GPON',
          description: 'تحتاج إلى واجهة الإدارة وصلاحية الوصول',
        ),
        InfoTile(
          icon: Icons.settings_ethernet,
          title: 'WAN وPPPoE',
          description: 'تحتاج إلى واجهة الإدارة وصلاحية الوصول',
        ),
      ],
    );
  }

  Widget buildSettings() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        SectionTitle(title: 'الإعدادات'),
        SizedBox(height: 12),
        InfoTile(
          icon: Icons.language,
          title: 'اللغة',
          description: 'الواجهة الحالية باللغة العربية',
        ),
        InfoTile(
          icon: Icons.palette_outlined,
          title: 'المظهر',
          description: 'الوضع الداكن',
        ),
        InfoTile(
          icon: Icons.info_outline,
          title: 'حول التطبيق',
          description: 'FiberCheck Reborn',
        ),
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
    );
  }
}

class MetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String unit;
  final Color color;

  const MetricCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(color: secondaryText, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: const TextStyle(color: secondaryText, fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const QuickAction({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: cyan, size: 30),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const InfoTile({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: cyan, size: 27),
        title: Text(title),
        subtitle: Text(
          description,
          style: const TextStyle(color: secondaryText, fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_left, color: secondaryText),
      ),
    );
  }
}