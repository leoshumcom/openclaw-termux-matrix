import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../app.dart';
import '../constants.dart';
import '../providers/gateway_provider.dart';
import '../providers/node_provider.dart';
import '../widgets/gateway_controls.dart';
import 'node_screen.dart';
import 'configure_screen.dart';
import 'onboarding_screen.dart';
import 'terminal_screen.dart';
import 'web_dashboard_screen.dart';
import 'logs_screen.dart';
import 'packages_screen.dart';
import 'providers_screen.dart';
import 'settings_screen.dart';
import 'ssh_screen.dart';

/// Matrix-themed dashboard.
///
/// Based on openclaw-termux (https://github.com/mithun50/openclaw-termux)
/// — MIT License. Modifications © 2026 66哥.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('>> DASHBOARD'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.mutedText),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gateway status controls
            const GatewayControls(),
            const SizedBox(height: 20),

            // Quick actions
            _buildSectionLabel('QUICK_ACTIONS'),
            const SizedBox(height: 8),

            _buildQuickActions(context),

            const SizedBox(height: 24),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        '// $label',
        style: const TextStyle(
          color: AppColors.mutedText,
          fontSize: 11,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        // Row 1: Terminal + Web Dashboard
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.terminal,
                label: 'TERMINAL',
                subtitle: 'Ubuntu shell',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TerminalScreen()),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Consumer<GatewayProvider>(
                builder: (context, provider, _) {
                  final url = provider.state.dashboardUrl;
                  final token = url != null
                      ? RegExp(r'#token=([0-9a-f]+)').firstMatch(url)?.group(1)
                      : null;
                  return _buildActionCard(
                    icon: Icons.dashboard,
                    label: 'DASHBOARD',
                    subtitle: provider.state.isRunning
                        ? (token != null
                            ? 'Token: ${token.substring(0, token.length > 8 ? 8 : token.length)}...'
                            : 'Web UI')
                        : 'Start gateway',
                    trailing: token != null
                        ? IconButton(
                            icon: const Icon(Icons.copy, color: AppColors.mutedText, size: 16),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: url!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('URL copied')),
                              );
                            },
                          )
                        : null,
                    onTap: provider.state.isRunning
                        ? () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => WebDashboardScreen(url: url),
                              ),
                            )
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Row 2: API Keys + AI Providers
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.vpn_key,
                label: 'API_KEYS',
                subtitle: 'Configure providers',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionCard(
                icon: Icons.model_training,
                label: 'PROVIDERS',
                subtitle: 'Models & settings',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProvidersScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Row 3: Configure + SSH
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.tune,
                label: 'CONFIGURE',
                subtitle: 'Gateway settings',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ConfigureScreen()),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionCard(
                icon: Icons.terminal,
                label: 'SSH',
                subtitle: 'Remote access',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SshScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Row 4: Logs + Packages
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.article_outlined,
                label: 'LOGS',
                subtitle: 'Gateway output',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LogsScreen()),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionCard(
                icon: Icons.extension,
                label: 'PACKAGES',
                subtitle: 'Go, Homebrew, SSH',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PackagesScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Row 5: Node + Settings
        Row(
          children: [
            Expanded(
              child: Consumer<NodeProvider>(
                builder: (context, nodeProvider, _) {
                  final ns = nodeProvider.state;
                  return _buildActionCard(
                    icon: Icons.devices,
                    label: 'NODE',
                    subtitle: ns.isPaired ? 'Connected' : ns.statusText,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NodeScreen()),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionCard(
                icon: Icons.backup,
                label: 'SNAPSHOT',
                subtitle: 'Backup & restore',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.matrixGreen, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.matrixGreen,
                      fontSize: 12,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
            if (trailing == null && onTap != null)
              const Icon(Icons.chevron_right, color: AppColors.mutedText, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Column(
        children: [
          Text(
            'OpenClaw Matrix v${AppConstants.version}',
            style: const TextStyle(color: AppColors.mutedText, fontSize: 10),
          ),
          const SizedBox(height: 2),
          Text(
            'Based on ${AppConstants.upstreamProject} — MIT',
            style: const TextStyle(color: AppColors.mutedText, fontSize: 9),
          ),
        ],
      ),
    );
  }
}
