import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app.dart';
import '../constants.dart';
import '../models/setup_state.dart';
import '../models/optional_package.dart';
import '../providers/setup_provider.dart';
import '../services/package_service.dart';
import '../widgets/progress_step.dart';
import 'onboarding_screen.dart';
import 'package_install_screen.dart';

/// Setup wizard — Matrix-themed, pure progress bar, no terminal.
///
/// Based on openclaw-termux (https://github.com/mithun50/openclaw-termux)
/// — MIT License. Modifications © 2026 66哥.
class SetupWizardScreen extends StatefulWidget {
  const SetupWizardScreen({super.key});

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  bool _started = false;
  Map<String, bool> _pkgStatuses = {};

  Future<void> _refreshPkgStatuses() async {
    final statuses = await PackageService.checkAllStatuses();
    if (mounted) setState(() => _pkgStatuses = statuses);
  }

  Future<void> _installPackage(OptionalPackage package) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PackageInstallScreen(package: package),
      ),
    );
    if (result == true) _refreshPkgStatuses();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Consumer<SetupProvider>(
          builder: (context, provider, _) {
            final state = provider.state;

            // Load package statuses once setup completes
            if (state.isComplete && _pkgStatuses.isEmpty) {
              _refreshPkgStatuses();
            }

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  // Matrix-style header
                  _buildHeader(),
                  const SizedBox(height: 8),
                  _buildSubtitle(state),
                  const SizedBox(height: 32),
                  Expanded(child: _buildSteps(state)),
                  if (state.hasError) _buildError(state),
                  if (state.isComplete)
                    _buildActionButton(state)
                  else if (!_started || state.hasError)
                    _buildStartButton(provider, state),
                  const SizedBox(height: 16),
                  _buildFooter(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.matrixGreen.withAlpha(80)),
            color: AppColors.matrixGreenDark.withAlpha(30),
          ),
          child: const Center(
            child: Text(
              '>>',
              style: TextStyle(
                color: AppColors.matrixGreen,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '> SYSTEM_INIT',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppColors.matrixGreen,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
            Text(
              'v${AppConstants.version}',
              style: const TextStyle(
                color: AppColors.mutedText,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubtitle(SetupState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.matrixGreenDark.withAlpha(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.terminal, color: AppColors.mutedText, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _started && !state.isComplete
                  ? '> ${state.message}'
                  : '> awating_init...',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSteps(SetupState state) {
    final steps = [
      (1, 'DOWNLOAD_ROOTFS', SetupStep.downloadingRootfs),
      (2, 'EXTRACT_ROOTFS', SetupStep.extractingRootfs),
      (3, 'INSTALL_NODEJS', SetupStep.installingNode),
      (4, 'INSTALL_OPENCLAW', SetupStep.installingOpenClaw),
      (5, 'CONFIGURE_SYSTEM', SetupStep.configuringBypass),
    ];

    return ListView(
      children: [
        ...steps.map((s) => _buildStepTile(s.$1, s.$2, s.$3, state)),
        if (state.isComplete) ...[
          const SizedBox(height: 12),
          _buildStepTile(6, 'SETUP_COMPLETE', null, state),
          const SizedBox(height: 24),
          // Optional packages section
          _buildSectionLabel('OPTIONAL_PACKAGES'),
          const SizedBox(height: 8),
          for (final pkg in OptionalPackage.all)
            _buildPackageTile(pkg),
        ],
      ],
    );
  }

  Widget _buildStepTile(int num, String label, SetupStep? step, SetupState state) {
    final isActive = step != null && state.step == step;
    final isComplete = step != null && (state.stepNumber > step.index || state.isComplete);
    final hasError = state.hasError && step != null && state.step == step;
    final isFinal = step == null;

    Color indicatorColor;
    String indicator;

    if (isFinal && state.isComplete) {
      indicatorColor = AppColors.matrixGreen;
      indicator = '✓';
    } else if (hasError) {
      indicatorColor = AppColors.statusRed;
      indicator = '!';
    } else if (isComplete) {
      indicatorColor = AppColors.matrixGreen;
      indicator = '✓';
    } else if (isActive) {
      indicatorColor = AppColors.matrixGreen;
      indicator = '>';
    } else {
      indicatorColor = AppColors.statusGrey;
      indicator = '·';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step indicator
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              border: Border.all(color: indicatorColor),
              color: isActive ? AppColors.matrixGreen.withAlpha(30) : Colors.transparent,
            ),
            child: Center(
              child: Text(
                indicator,
                style: TextStyle(
                  color: indicatorColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Step content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isActive || isComplete ? AppColors.matrixGreen : AppColors.mutedText,
                    fontSize: 13,
                    letterSpacing: 1,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (isActive && state.progress != null) ...[
                  const SizedBox(height: 4),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: state.progress!),
                    duration: const Duration(milliseconds: 300),
                    builder: (context, value, _) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: value,
                          backgroundColor: AppColors.border,
                          color: AppColors.matrixGreen,
                          minHeight: 4,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(state.progress! * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
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

  Widget _buildPackageTile(OptionalPackage package) {
    final installed = _pkgStatuses[package.id] ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          package.icon,
          color: installed ? AppColors.matrixGreen : AppColors.mutedText,
          size: 20,
        ),
        title: Text(
          package.name,
          style: const TextStyle(
            color: AppColors.matrixGreen,
            fontSize: 13,
          ),
        ),
        subtitle: Text(
          '${package.description} (${package.estimatedSize})',
          style: const TextStyle(
            color: AppColors.mutedText,
            fontSize: 11,
          ),
        ),
        trailing: installed
            ? const Icon(Icons.check_circle, color: AppColors.matrixGreen, size: 20)
            : SizedBox(
                height: 28,
                child: OutlinedButton(
                  onPressed: () => _installPackage(package),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: const TextStyle(fontSize: 11),
                  ),
                  child: const Text('INSTALL'),
                ),
              ),
      ),
    );
  }

  Widget _buildError(SetupState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.statusRed.withAlpha(20),
        border: Border.all(color: AppColors.statusRed.withAlpha(80)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.statusRed, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              state.error ?? 'ERR_UNKNOWN',
              style: const TextStyle(color: AppColors.statusRed, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(SetupProvider provider, SetupState state) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: provider.isRunning
            ? null
            : () {
                setState(() => _started = true);
                provider.runSetup();
              },
        icon: Icon(
          state.hasError ? Icons.refresh : Icons.download,
          size: 18,
        ),
        label: Text(
          state.hasError ? '>> RETRY_SETUP' : '>> BEGIN_SETUP',
          style: const TextStyle(letterSpacing: 2),
        ),
      ),
    );
  }

  Widget _buildActionButton(SetupState state) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => _goToOnboarding(context),
        icon: const Icon(Icons.settings, size: 18),
        label: const Text(
          '>> CONFIGURE_API',
          style: TextStyle(letterSpacing: 2),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Column(
        children: [
          Text(
            'Based on ${AppConstants.upstreamProject}',
            style: const TextStyle(color: AppColors.mutedText, fontSize: 10),
          ),
          const SizedBox(height: 4),
          Text(
            AppConstants.upstreamUrl,
            style: const TextStyle(color: AppColors.mutedText, fontSize: 9),
          ),
        ],
      ),
    );
  }

  void _goToOnboarding(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const OnboardingScreen(isFirstRun: true),
      ),
    );
  }
}
