import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app.dart';
import '../constants.dart';
import '../services/native_bridge.dart';
import '../services/preferences_service.dart';
import 'setup_wizard_screen.dart';
import 'dashboard_screen.dart';

/// Splash screen — Matrix hacker-style.
///
/// Based on openclaw-termux (https://github.com/mithun50/openclaw-termux)
/// — MIT License. Modifications © 2026 66哥.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  String _status = '> 加载中...';
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
    _checkAndRoute();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _checkAndRoute() async {
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      setState(() => _status = '> 检查系统...');

      try { await NativeBridge.setupDirs(); } catch (_) {}
      try { await NativeBridge.writeResolv(); } catch (_) {}

      try {
        final filesDir = await NativeBridge.getFilesDir();
        const resolvContent = 'nameserver 8.8.8.8\nnameserver 8.8.4.4\n';
        final configDir = '$filesDir/config';
        final resolvFile = File('$configDir/resolv.conf');
        if (!resolvFile.existsSync()) {
          Directory(configDir).createSync(recursive: true);
          resolvFile.writeAsStringSync(resolvContent);
        }
        final rootfsResolv = File('$filesDir/rootfs/ubuntu/etc/resolv.conf');
        if (!rootfsResolv.existsSync()) {
          rootfsResolv.parent.createSync(recursive: true);
          rootfsResolv.writeAsStringSync(resolvContent);
        }
      } catch (_) {}

      final prefs = PreferencesService();
      await prefs.init();

      // Auto-export snapshot when app version changes
      try {
        final oldVersion = prefs.lastAppVersion;
        if (oldVersion != null && oldVersion != AppConstants.version) {
          final hasPermission = await NativeBridge.hasStoragePermission();
          if (hasPermission) {
            final sdcard = await NativeBridge.getExternalStoragePath();
            final downloadDir = Directory('$sdcard/Download');
            if (!await downloadDir.exists()) {
              await downloadDir.create(recursive: true);
            }
            final snapshotPath = '$sdcard/Download/openclaw-snapshot-$oldVersion.json';
            final openclawJson = await NativeBridge.readRootfsFile('root/.openclaw/openclaw.json');
            final snapshot = {
              'version': oldVersion,
              'timestamp': DateTime.now().toIso8601String(),
              'openclawConfig': openclawJson,
              'dashboardUrl': prefs.dashboardUrl,
              'autoStart': prefs.autoStartGateway,
              'nodeEnabled': prefs.nodeEnabled,
              'nodeDeviceToken': prefs.nodeDeviceToken,
              'nodeGatewayHost': prefs.nodeGatewayHost,
              'nodeGatewayPort': prefs.nodeGatewayPort,
              'nodeGatewayToken': prefs.nodeGatewayToken,
            };
            await File(snapshotPath).writeAsString(
              const JsonEncoder.withIndent('  ').convert(snapshot),
            );
          }
        }
        prefs.lastAppVersion = AppConstants.version;
      } catch (_) {}

      bool setupComplete;
      try {
        setupComplete = await NativeBridge.isBootstrapComplete();
      } catch (_) {
        setupComplete = false;
      }

      if (!setupComplete) {
        try {
          final status = await NativeBridge.getBootstrapStatus();
          final rootfsOk = status['rootfsExists'] == true;
          final bashOk = status['binBashExists'] == true;
          final nodeOk = status['nodeInstalled'] == true;
          final openclawOk = status['openclawInstalled'] == true;
          final bypassOk = status['bypassInstalled'] == true;

          if (rootfsOk && bashOk) {
            if (!bypassOk) {
              setState(() => _status = '> 修复系统组件...');
              await NativeBridge.installBionicBypass();
            }
            if (!nodeOk) {
              setState(() => _status = '> 重新安装 Node.js...');
              try {
                final arch = await NativeBridge.getArch();
                final nodeTarUrl = AppConstants.getNodeTarballUrl(arch);
                final filesDir = await NativeBridge.getFilesDir();
                final nodeTarPath = '$filesDir/tmp/nodejs.tar.xz';
                final dio = Dio();
                await dio.download(nodeTarUrl, nodeTarPath);
                await NativeBridge.extractNodeTarball(nodeTarPath);
              } catch (_) {}
            }
            if (!openclawOk && nodeOk) {
              setState(() => _status = '> 重新安装 OpenClaw...');
              try {
                const wrapper = '/root/.openclaw/node-wrapper.js';
                const nodeRun = 'node $wrapper';
                const npmCli = '/usr/local/lib/node_modules/npm/bin/npm-cli.js';
                await NativeBridge.runInProot(
                  '$nodeRun $npmCli install -g openclaw',
                  timeout: 1800,
                );
                await NativeBridge.createBinWrappers('openclaw');
              } catch (_) {}
            }
            setupComplete = await NativeBridge.isBootstrapComplete();
          }
        } catch (_) {}
      }

      if (!mounted) return;

      if (setupComplete) {
        prefs.setupComplete = true;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SetupWizardScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _status = '> 错误: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Matrix-style boot logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.matrixGreen, width: 1),
                  color: AppColors.matrixGreenDark.withAlpha(40),
                ),
                child: Center(
                  child: Text(
                    '[]',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 32,
                      color: AppColors.matrixGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '_OPENCLAW_MATRIX_',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4,
                  color: AppColors.matrixGreen,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'v${AppConstants.version}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  color: AppColors.mutedText,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '基于 ${AppConstants.upstreamProject}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  color: AppColors.mutedText.withAlpha(100),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 200,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: const LinearProgressIndicator(
                    backgroundColor: AppColors.border,
                    color: AppColors.matrixGreen,
                    minHeight: 2,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _status,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
