class SystemInfo {
  final String cpuModel;
  final int cpuCores;
  final String governor;
  final double totalRamGb;
  final double freeRamGb;
  final double totalSwapGb;
  final double usedSwapGb;
  final double storageTotalGb;
  final double storageFreeGb;
  final String uptime;
  final String kernel;
  final List<ServiceStatus> services;

  SystemInfo({
    required this.cpuModel,
    required this.cpuCores,
    required this.governor,
    required this.totalRamGb,
    required this.freeRamGb,
    required this.totalSwapGb,
    required this.usedSwapGb,
    required this.storageTotalGb,
    required this.storageFreeGb,
    required this.uptime,
    required this.kernel,
    required this.services,
  });

  factory SystemInfo.empty() => SystemInfo(
    cpuModel: '—',
    cpuCores: 0,
    governor: '—',
    totalRamGb: 0,
    freeRamGb: 0,
    totalSwapGb: 0,
    usedSwapGb: 0,
    storageTotalGb: 0,
    storageFreeGb: 0,
    uptime: '—',
    kernel: '—',
    services: [],
  );

  factory SystemInfo.fromJson(Map<String, dynamic> json) {
    final cpu = json['cpu'] as Map<String, dynamic>? ?? {};
    final mem = json['memory'] as Map<String, dynamic>? ?? {};
    final storage = json['storage'] as Map<String, dynamic>? ?? {};
    final svcs = json['services'] as List? ?? [];

    return SystemInfo(
      cpuModel: cpu['model'] as String? ?? '—',
      cpuCores: (cpu['cores'] as num?)?.toInt() ?? 0,
      governor: cpu['governor'] as String? ?? '—',
      totalRamGb: ((mem['totalKb'] as num?)?.toDouble() ?? 0) / 1048576,
      freeRamGb: ((mem['availableKb'] as num?)?.toDouble() ?? 0) / 1048576,
      totalSwapGb: ((mem['swapTotalKb'] as num?)?.toDouble() ?? 0) / 1048576,
      usedSwapGb: ((mem['swapUsedKb'] as num?)?.toDouble() ?? 0) / 1048576,
      storageTotalGb: ((storage['totalBytes'] as num?)?.toDouble() ?? 0) / 1073741824,
      storageFreeGb: ((storage['freeBytes'] as num?)?.toDouble() ?? 0) / 1073741824,
      uptime: json['uptime'] as String? ?? '—',
      kernel: json['kernel'] as String? ?? '—',
      services: svcs
        .map((s) => ServiceStatus.fromJson(s as Map<String, dynamic>))
        .toList(),
    );
  }

  bool get isAvailable => cpuCores > 0;

  double get ramUsagePercent =>
    totalRamGb > 0 ? ((totalRamGb - freeRamGb) / totalRamGb * 100) : 0;

  double get swapUsagePercent =>
    totalSwapGb > 0 ? (usedSwapGb / totalSwapGb * 100) : 0;

  double get storageUsagePercent =>
    storageTotalGb > 0 ? ((storageTotalGb - storageFreeGb) / storageTotalGb * 100) : 0;
}

class ServiceStatus {
  final String name;
  final String status;
  final int? pid;
  final String? endpoint;

  ServiceStatus({
    required this.name,
    required this.status,
    this.pid,
    this.endpoint,
  });

  factory ServiceStatus.fromJson(Map<String, dynamic> json) => ServiceStatus(
    name: json['name'] as String? ?? '?',
    status: json['status'] as String? ?? 'stopped',
    pid: json['pid'] as int?,
    endpoint: json['endpoint'] as String?,
  );
}
