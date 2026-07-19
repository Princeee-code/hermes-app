import 'package:flutter/material.dart';
import '../models/system_info.dart';
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
    if (mounted) {
      setState(() {
        _info = info;
        _loading = false;
      });
    }
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
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.accentGold),
              )
            : _info == null || !_info!.isAvailable
                ? _buildUnavailable()
                : _buildContent(),
      ),
    );
  }

  Widget _buildUnavailable() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off,
            size: 64,
            color: AppTheme.textSecondary.withAlpha(80),
          ),
          const SizedBox(height: 16),
          const Text(
            'System info unavailable',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Make sure the Hermes backend is running\non port 9091.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        children: [
          // Metrics overview row
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'CPU',
                  value: '${i.ramUsagePercent.toStringAsFixed(0)}%',
                  icon: Icons.memory,
                  color: AppTheme.accentGold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricTile(
                  label: 'RAM',
                  value: '${i.freeRamGb.toStringAsFixed(1)}GB',
                  icon: Icons.chip,
                  color: AppTheme.accentPurple,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricTile(
                  label: 'Storage',
                  value: '${i.storageFreeGb.toStringAsFixed(0)}GB',
                  icon: Icons.storage,
                  color: AppTheme.accentBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // CPU section
          _GlassSection(
            title: 'CPU',
            icon: Icons.memory,
            children: [
              _infoRow('Model', i.cpuModel),
              _infoRow('Cores', '${i.cpuCores}'),
              _infoRow('Governor', i.governor),
              const SizedBox(height: 8),
              _UsageBar(
                label: 'Load (1m)',
                percent: i.ramUsagePercent,
                color: AppTheme.accentGold,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Memory section
          _GlassSection(
            title: 'Memory',
            icon: Icons.chip,
            children: [
              _infoRow(
                'RAM',
                '${i.freeRamGb.toStringAsFixed(1)} GB free / '
                '${i.totalRamGb.toStringAsFixed(1)} GB total',
              ),
              const SizedBox(height: 8),
              _UsageBar(
                label: 'RAM Usage',
                percent: i.ramUsagePercent,
                color: AppTheme.accentGold,
              ),
              const SizedBox(height: 12),
              _infoRow(
                'Swap',
                '${i.usedSwapGb.toStringAsFixed(1)} GB used / '
                '${i.totalSwapGb.toStringAsFixed(1)} GB total',
              ),
              const SizedBox(height: 8),
              _UsageBar(
                label: 'Swap Usage',
                percent: i.swapUsagePercent,
                color: AppTheme.accentPurple,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Storage section
          _GlassSection(
            title: 'Storage',
            icon: Icons.storage,
            children: [
              _infoRow(
                'Internal',
                '${i.storageFreeGb.toStringAsFixed(1)} GB free / '
                '${i.storageTotalGb.toStringAsFixed(1)} GB total',
              ),
              const SizedBox(height: 8),
              _UsageBar(
                label: 'Storage Usage',
                percent: i.storageUsagePercent,
                color: AppTheme.accentBlue,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // System section
          _GlassSection(
            title: 'System',
            icon: Icons.info_outline,
            children: [
              _infoRow('Kernel', i.kernel),
              _infoRow('Uptime', i.uptime),
            ],
          ),

          // Services section
          if (i.services.isNotEmpty) ...[
            const SizedBox(height: 12),
            _GlassSection(
              title: 'Services',
              icon: Icons.miscellaneous_services,
              children: i.services
                  .map((s) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: s.status == 'running'
                                    ? AppTheme.accentEmerald
                                    : AppTheme.danger,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              s.name,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              s.status,
                              style: TextStyle(
                                color: s.status == 'running'
                                    ? AppTheme.accentEmerald
                                    : AppTheme.danger,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: color.withAlpha(40),
          width: 1,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textTertiary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _GlassSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: AppTheme.surface3.withAlpha(60),
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.accentGold, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.accentGold,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _UsageBar extends StatelessWidget {
  final String label;
  final double percent;
  final Color color;

  const _UsageBar({
    required this.label,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textTertiary,
                fontSize: 11,
              ),
            ),
            Text(
              '${percent.toStringAsFixed(1)}%',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (percent / 100).clamp(0.0, 1.0),
            backgroundColor: AppTheme.surface3.withAlpha(80),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
