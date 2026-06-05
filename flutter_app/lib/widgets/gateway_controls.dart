import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../app.dart';
import '../constants.dart';
import '../models/gateway_state.dart';
import '../providers/gateway_provider.dart';
import '../screens/logs_screen.dart';
import '../screens/web_dashboard_screen.dart';

/// Matrix-themed gateway controls.
///
/// Based on openclaw-termux (https://github.com/mithun50/openclaw-termux)
/// — MIT License.
class GatewayControls extends StatelessWidget {
  const GatewayControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GatewayProvider>(
      builder: (context, provider, _) {
        final state = provider.state;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.dns, color: AppColors.matrixGreen, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    '服务状态',
                    style: TextStyle(
                      color: AppColors.matrixGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
                  const Spacer(),
                  _statusBadge(state.status),
                ],
              ),
              const SizedBox(height: 12),

              // URL display
              if (state.isRunning) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.matrixGreenDark.withAlpha(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.link, color: AppColors.mutedText, size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => WebDashboardScreen(
                                  url: state.dashboardUrl,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            state.dashboardUrl ?? AppConstants.gatewayUrl,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontFamily: 'monospace',
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, color: AppColors.mutedText, size: 16),
                        onPressed: () {
                          final url = state.dashboardUrl ?? AppConstants.gatewayUrl;
                          Clipboard.setData(ClipboardData(text: url));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('URL copied')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],

              if (state.errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  '> err: ${state.errorMessage}',
                  style: const TextStyle(
                    color: AppColors.statusRed,
                    fontSize: 11,
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Action buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (state.isStopped || state.status == GatewayStatus.error)
                    FilledButton.icon(
                      onPressed: () => provider.start(),
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text(
                        '>> 启动',
                        style: TextStyle(letterSpacing: 1, fontSize: 12),
                      ),
                    ),
                  if (state.isRunning || state.status == GatewayStatus.starting)
                    OutlinedButton.icon(
                      onPressed: () => provider.stop(),
                      icon: const Icon(Icons.stop, size: 16),
                      label: const Text(
                        '>> 停止',
                        style: TextStyle(letterSpacing: 1, fontSize: 12),
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LogsScreen()),
                    ),
                    icon: const Icon(Icons.article_outlined, size: 16),
                    label: const Text(
                      '>> 日志',
                      style: TextStyle(letterSpacing: 1, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statusBadge(GatewayStatus status) {
    Color color;
    String label;
    String icon;

    switch (status) {
      case GatewayStatus.running:
        color = AppColors.statusGreen;
        label = '运行中';
        icon = '●';
      case GatewayStatus.starting:
        color = AppColors.statusAmber;
        label = '启动中';
        icon = '◐';
      case GatewayStatus.error:
        color = AppColors.statusRed;
        label = '错误';
        icon = '●';
      case GatewayStatus.stopped:
        color = AppColors.statusGrey;
        label = '已停止';
        icon = '○';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            icon,
            style: TextStyle(color: color, fontSize: 12),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
