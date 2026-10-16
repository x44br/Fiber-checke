import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ont_reading.dart';

class OntService {
  Future<OntReading> readHuawei({
    String ip = '192.168.100.1',
    String user = 'telecomadmin',
    String pass = 'admintelecom',
  }) async {
    final client = http.Client();
    try {
      // 1) تسجيل الدخول
      final login = await client.post(
        Uri.parse('http://$ip/login.cgi'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'UserName': user,
          'PassWord': base64.encode(utf8.encode(pass)),
          'Language': 'english',
        },
      ).timeout(const Duration(seconds: 10));

      final cookie = login.headers['set-cookie'];
      if (cookie == null || cookie.isEmpty) {
        throw Exception('بيانات الدخول غير صحيحة');
      }

      // 2) جلب صفحات المعلومات
      final opticalHtml = await _tryUrls(client, ip, cookie, const [
        '/html/ssmp/optinfo/optinfo.asp',
        '/html/amp/opticalinfo/opticalinfo.asp',
        '/html/ssmp/opticalinfo/opticalinfo.asp',
        '/html/amp/deviceinfo/opticalinfo.asp',
      ]);

      final deviceHtml = await _tryUrls(client, ip, cookie, const [
        '/html/ssmp/deviceinfo/deviceinfo.asp',
        '/html/amp/deviceinfo/deviceinfo.asp',
      ]);

      final combined = '$opticalHtml\n$deviceHtml';

      if (combined.trim().isEmpty) {
        throw Exception('تعذر جلب بيانات الجهاز');
      }

      // 3) استخراج القيم
      double? extract(String label) {
        final patterns = [
          RegExp('$label[^0-9\\-+]{0,30}([\\-+]?\\d+\\.?\\d*)',
              caseSensitive: false),
        ];
        for (final p in patterns) {
          final m = p.firstMatch(combined);
          if (m != null) {
            final v = double.tryParse(m.group(1)!);
            if (v != null && v != 0) return v;
          }
        }
        return null;
      }

      final rxRaw = extract('RX Optical Power');
      final txRaw = extract('TX Optical Power');
      final voltRaw = extract('Working Voltage');
      final bias = extract('Bias Current');
      final temp = extract('Working Temperature');
      final cpu = extract('CPU Usage');
      final mem = extract('Memory Usage');

      final snMatch = RegExp(r'SN[^A-F0-9]{0,20}([A-F0-9]{16})',
              caseSensitive: false)
          .firstMatch(combined);
      final regMatch =
          RegExp(r'ONT Registration Status[^0-9]{0,10}(\d+)').firstMatch(combined);

      return OntReading(
        vendor: 'Huawei',
        model: 'HG8120C',
        serialNumber: snMatch?.group(1),
        rxPower: rxRaw,
        txPower: txRaw,
        temperature: temp,
        voltage: voltRaw != null ? voltRaw / 1000 : null,
        biasCurrent: bias,
        cpuUsage: cpu?.toInt(),
        memoryUsage: mem?.toInt(),
        registrationStatus: regMatch?.group(1),
        status: OntReading.interpretRx(rxRaw),
        readAt: DateTime.now(),
      );
    } finally {
      client.close();
    }
  }

  Future<String> _tryUrls(
      http.Client client, String ip, String cookie, List<String> urls) async {
    for (final path in urls) {
      try {
        final r = await client.get(
          Uri.parse('http://$ip$path'),
          headers: {'Cookie': cookie},
        ).timeout(const Duration(seconds: 6));
        if (r.statusCode == 200 && r.body.length > 100) {
          return r.body;
        }
      } catch (_) {
        continue;
      }
    }
    return '';
  }
}