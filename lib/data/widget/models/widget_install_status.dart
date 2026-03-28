class WidgetInstallStatus {
  const WidgetInstallStatus({
    required this.isInstalled,
    required this.isHeuristic,
    this.detectedAt,
    this.widgetCount,
  });

  final bool isInstalled;
  final bool isHeuristic;
  final DateTime? detectedAt;
  final int? widgetCount;

  factory WidgetInstallStatus.fromMap(Map<String, dynamic> map) {
    final detectedAtRaw = map['detectedAt'];
    final widgetCountRaw = map['widgetCount'];
    return WidgetInstallStatus(
      isInstalled: map['isInstalled'] == true,
      isHeuristic: map['isHeuristic'] == true,
      detectedAt: detectedAtRaw is String
          ? DateTime.tryParse(detectedAtRaw)
          : null,
      widgetCount: widgetCountRaw is int
          ? widgetCountRaw
          : widgetCountRaw is num
          ? widgetCountRaw.toInt()
          : null,
    );
  }
}
