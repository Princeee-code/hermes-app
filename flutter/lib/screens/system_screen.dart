import 'package:flutter/material.dart';
import '../services/system_service.dart';
import '../theme/app_theme.dart';

class SystemScreen extends StatefulWidget {
  final SystemService service;

  const SystemScreen({super.key, required this.service});

  @override
  State<SystemScreen> createState() => _SystemScreenState();
}

class _SystemScreenState extends State<SystemScreen> {
  SystemInfo? _info;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final info = await widget.service.getStatus();
    if (mounted) setState(() { _info = info; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _refresh,
          ),
        ],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.accentGold))
        : _info == null || _info!.cpuModel == '—'
          ? _buildUnavailable()
          : _buildContent(),
    );
  }

  Widget _buildUnavailable() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, size: 64,
            color: AppTheme.textSecondary.withAlpha(80)),
          const SizedBox(height: 16),
          const Text(
            'System info unavailable',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Make sure the Hermes backend is running\non port 9091.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGold,
              foregroundColor: AppTheme.bg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final i = _info!;
    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppTheme.accentGold,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('CPU', [
            _row('Model', i.cpuModel),
            _row('Cores', '${i.cpuCores}'),
            _row('Governor', i.governor),
          ]),
          const SizedBox(height: 12),
          _buildSection('Memory', [
            _row('RAM', '${i.freeRamGb.toStringAsFixed(1)} GB free / ${i.totalRamGb.toStringAsFixed(1)} GB total'),
            _buildBar(i.ramUsagePercent),
            _row('Swap', '${i.usedSwapGb.toStringAsFixed(1)} GB used / ${i.totalSwapGb.toStringAsFixed(1)} GB total'),
            _buildBar(i.swapUsagePercent, color: AppTheme.accentPurple),
          ]),
          const SizedBox(height: 12),
          _buildSection('Storage', [
            _row('Internal', '${i.storageFreeGb.toStringAsFixed(1)} GB free / ${i.storageTotalGb.toStringAsFixed(1)} GB total'),
            _buildBar(i.storageUsagePercent, color: AppTheme.accentPurple),
          ]),
          const SizedBox(height: 12),
          _buildSection('System', [
            _row('Kernel', i.kernel),
            _row('Uptime', i.uptime),
          ]),
          if (i.services.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSection('Services', i.services.map((s) => _row(s.name, s.status)).toList()),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surface2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(
            color: AppTheme.accentGold,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          )),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
          )),
          Text(value, style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          )),
        ],
      ),
    );
  }

  Widget _buildBar(double percent, {Color color = AppTheme.accentGold}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: percent / 100,
          backgroundColor: AppTheme.surface2,
          valueColor: AlwaysStoppedAnimation(color),
          minHeight: 6,
        ),
      ),
    );
  }
}
