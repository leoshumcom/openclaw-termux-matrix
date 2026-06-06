import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app.dart';
import '../constants.dart';
import '../models/ai_provider.dart';
import '../services/provider_config_service.dart';
import '../services/preferences_service.dart';
import '../services/native_bridge.dart';
import 'dashboard_screen.dart';
import 'setup_wizard_screen.dart';

/// 纯表单配置界面 — 无终端，无 TUI。
/// 选择 AI 服务商，填写 API Key，测试连接，完成。

class OnboardingScreen extends StatefulWidget {
  final bool isFirstRun;

  const OnboardingScreen({super.key, this.isFirstRun = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();

  final _prefs = PreferencesService();

  List<AiProvider> _providers = AiProvider.defaultProviders;
  late AiProvider _selectedProvider;
  String? _selectedModel;
  bool _testPassed = false;
  String? _testResult;
  bool _configSaved = false;
  bool _loopbackOnly = true;
  bool _initialized = false;
  bool _isTesting = false;

  List<String> get _availableModels {
    return _selectedProvider.models;
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _prefs.init();
    final savedProvider = _prefs.lastProvider;
    _selectedProvider = savedProvider != null
        ? _providers.firstWhere(
            (p) => p.id == savedProvider,
            orElse: () => _providers.first,
          )
        : _providers.first;
    _selectedModel = _selectedProvider.defaultModels.first;

    final savedKey = _prefs.getApiKey(_selectedProvider.id);
    if (savedKey != null) {
      _apiKeyController.text = savedKey;
    }

    setState(() => _initialized = true);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      setState(() {
        _testResult = '请先输入 API Key';
        _testPassed = false;
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _testResult = '测试中...';
      _testPassed = false;
    });

    try {
      final passed = await ProviderConfigService.testConnection(
        providerId: _selectedProvider.id,
        apiKey: apiKey,
        model: _selectedModel ?? _selectedProvider.defaultModels.first,
      );

      if (!mounted) return;
      setState(() {
        _isTesting = false;
        _testResult = passed ? '连接成功 ✓' : '连接失败';
        _testPassed = passed;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTesting = false;
        _testResult = '连接失败: $e';
        _testPassed = false;
      });
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    final apiKey = _apiKeyController.text.trim();

    // 保存到 SharedPreferences（此时 rootfs 还不存在，不能写文件）
    await _prefs.setApiKey(_selectedProvider.id, apiKey);
    await _prefs.setString('last_provider', _selectedProvider.id);
    await _prefs.setString('last_model', _selectedModel ?? _selectedProvider.defaultModels.first);
    await _prefs.setStringList('configured_providers', [_selectedProvider.id]);

    // 也保存到 ProviderConfigService
    try {
      await ProviderConfigService.saveProviderConfig(
        provider: _selectedProvider,
        apiKey: apiKey,
        model: _selectedModel ?? _selectedProvider.defaultModels.first,
      );
    } catch (_) {
      // 非致命错误，忽略
    }

    if (!mounted) return;
    setState(() => _configSaved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('配置已保存 ✓'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _finish() async {
    _prefs.setupComplete = true;
    _prefs.isFirstRun = false;
    await _prefs.save();

    if (!mounted) return;

    if (widget.isFirstRun) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SetupWizardScreen()),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.matrixGreen),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('>> 系统配置'),
        leading: widget.isFirstRun
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.matrixGreen),
                onPressed: () => Navigator.of(context).pop(),
              ),
        actions: [
          if (_configSaved)
            TextButton.icon(
              onPressed: _finish,
              icon: const Icon(Icons.check, color: AppColors.matrixGreen),
              label: const Text(
                '继续',
                style: TextStyle(
                  color: AppColors.matrixGreen,
                  letterSpacing: 2,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Matrix header
                _buildAsciiHeader(),
                const SizedBox(height: 24),

                // Provider selection
                _buildSectionLabel('AI 服务商'),
                const SizedBox(height: 8),
                _buildProviderSelector(),
                const SizedBox(height: 20),

                // Model selection
                _buildSectionLabel('模型'),
                const SizedBox(height: 8),
                _buildModelSelector(),
                const SizedBox(height: 20),

                // API Key
                _buildSectionLabel('API Key'),
                const SizedBox(height: 8),
                _buildApiKeyField(),
                const SizedBox(height: 12),

                // Test connection button
                _buildTestButton(),
                const SizedBox(height: 20),

                // Binding option
                _buildSectionLabel('网络绑定'),
                const SizedBox(height: 8),
                _buildBindingSelector(),
                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _configSaved ? null : _saveConfig,
                    icon: const Icon(Icons.save),
                    label: Text(
                      _configSaved
                          ? '>> 已保存'
                          : '>> 保存配置',
                      style: const TextStyle(letterSpacing: 2),
                    ),
                  ),
                ),

                // Footer
                const SizedBox(height: 32),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAsciiHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.matrixGreenDark.withAlpha(30),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '> OpenClaw Matrix 版 v${AppConstants.version}\n'
        '> 选择 AI 服务商并填写 API Key 即可开始。\n'
        '> 提示：选「仅本地」则只有本机可访问。',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      '// ${label.padRight(20, '_')}',
      style: const TextStyle(
        color: AppColors.mutedText,
        fontSize: 11,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildProviderSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButton<AiProvider>(
        underline: const SizedBox.shrink(),
        value: _selectedProvider,
        dropdownColor: AppColors.surface,
        isExpanded: true,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        style: const TextStyle(
          color: AppColors.matrixGreen,
          fontSize: 14,
        ),
        items: _providers.map((p) {
          return DropdownMenuItem(
            value: p,
            child: Row(
              children: [
                Icon(
                  p.icon,
                  size: 18,
                  color: _selectedProvider.id == p.id
                      ? AppColors.matrixGreen
                      : AppColors.mutedText,
                ),
                const SizedBox(width: 12),
                Text(p.name),
              ],
            ),
          );
        }).toList(),
        onChanged: (p) {
          if (p == null) return;
          setState(() {
            _selectedProvider = p;
            _selectedModel = p.defaultModels.first;
            _testResult = null;
            _testPassed = false;
            _configSaved = false;
          });

          // 如果之前保存过该供应商的 key，自动填入
          final savedKey = _prefs.getApiKey(p.id);
          if (savedKey != null) {
            _apiKeyController.text = savedKey;
          } else {
            _apiKeyController.clear();
          }
        },
      ),
    );
  }

  Widget _buildModelSelector() {
    final models = _availableModels;
    if (models.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButton<String>(
        underline: const SizedBox.shrink(),
        value: _selectedModel,
        dropdownColor: AppColors.surface,
        isExpanded: true,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        style: const TextStyle(
          color: AppColors.matrixGreen,
          fontSize: 14,
        ),
        items: models.map((m) {
          return DropdownMenuItem(
            value: m,
            child: Text(
              m,
              style: TextStyle(
                color: _selectedModel == m
                    ? AppColors.matrixGreen
                    : AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          );
        }).toList(),
        onChanged: (m) {
          if (m == null) return;
          setState(() {
            _selectedModel = m;
            _testResult = null;
            _testPassed = false;
            _configSaved = false;
          });
        },
      ),
    );
  }

  Widget _buildApiKeyField() {
    return TextFormField(
      controller: _apiKeyController,
      style: const TextStyle(
        color: AppColors.matrixGreen,
        fontSize: 13,
        fontFamily: AppConstants.monoFont,
      ),
      decoration: InputDecoration(
        hintText: '输入你的 API Key',
        hintStyle: TextStyle(color: AppColors.mutedText.withAlpha(100)),
        filled: true,
        fillColor: AppColors.surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(color: AppColors.matrixGreen, width: 1.5),
        ),
        suffixIcon: IconButton(
          icon: const Icon(Icons.paste, color: AppColors.mutedText, size: 18),
          onPressed: () async {
            final data = await Clipboard.getData(Clipboard.kTextPlain);
            if (data?.text != null) {
              _apiKeyController.text = data!.text!.trim();
            }
          },
        ),
      ),
      onChanged: (_) {
        if (_configSaved) {
          setState(() => _configSaved = false);
        }
      },
      validator: (v) {
        if (v == null || v.trim().isEmpty) return '请输入 API Key';
        return null;
      },
    );
  }

  Widget _buildTestButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: (_configSaved || _isTesting) ? null : _testConnection,
        icon: _isTesting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.matrixGreen,
                ),
              )
            : const Icon(Icons.wifi_tethering, size: 16),
        label: Text(
          _isTesting ? '测试中...' : '测试连接',
          style: const TextStyle(letterSpacing: 2),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.matrixGreen,
          side: const BorderSide(color: AppColors.border),
          disabledForegroundColor: AppColors.mutedText,
        ),
      ),
    );
  }

  Widget _buildBindingSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        border: Border.all(color: AppColors.border),
      ),
      child: SwitchListTile(
        title: const Text(
          '仅本地访问 (127.0.0.1)',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        subtitle: const Text(
          '开启后只允许本机连接（推荐）',
          style: TextStyle(
            color: AppColors.mutedText,
            fontSize: 11,
          ),
        ),
        value: _loopbackOnly,
        onChanged: (v) {
          if (_configSaved) {
            setState(() => _configSaved = false);
          }
          setState(() => _loopbackOnly = v);
        },
        activeColor: AppColors.matrixGreen,
        inactiveThumbColor: AppColors.mutedText,
        inactiveTrackColor: AppColors.surface,
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Text(
        '>> OpenClaw Matrix 版 <<',
        style: TextStyle(
          color: AppColors.mutedText.withAlpha(60),
          fontSize: 10,
        ),
      ),
    );
  }
}
