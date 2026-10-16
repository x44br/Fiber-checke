enum LineStatus { ok, weakSignal, noSignal, los, unknown }

class OntReading {
  final String vendor;
  final String model;
  final String? serialNumber;
  final double? rxPower;
  final double? txPower;
  final double? temperature;
  final double? voltage;
  final double? biasCurrent;
  final int? cpuUsage;
  final int? memoryUsage;
  final String? registrationStatus;
  final LineStatus status;
  final DateTime readAt;

  const OntReading({
    required this.vendor,
    required this.model,
    this.serialNumber,
    this.rxPower,
    this.txPower,
    this.temperature,
    this.voltage,
    this.biasCurrent,
    this.cpuUsage,
    this.memoryUsage,
    this.registrationStatus,
    required this.status,
    required this.readAt,
  });

  static LineStatus interpretRx(double? rx) {
    if (rx == null) return LineStatus.los;
    if (rx >= -25) return LineStatus.ok;
    if (rx >= -27) return LineStatus.weakSignal;
    return LineStatus.noSignal;
  }

  String get statusArabic {
    switch (status) {
      case LineStatus.ok:         return 'الخط سليم';
      case LineStatus.weakSignal: return 'إشارة ضعيفة';
      case LineStatus.noSignal:   return 'إشارة مقطوعة';
      case LineStatus.los:        return 'لا توجد قراءة (LOS)';
      case LineStatus.unknown:    return 'غير معروف';
    }
  }
}