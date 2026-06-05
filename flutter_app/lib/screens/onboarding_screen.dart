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

/// Pure-form onboarding — no terminal, no TUI.
/// Select AI provider, enter API key, test connection, done.
///
/// Based on openclaw-termux (https://github.com/mithun50/openclaw-termux)
/// — MIT License. Modifications © 2026 66哥.
class OnboardingScreen extends StatefulWidget {
  final bool isFirstRun;

  const OnboardingScreen({super.key, this.isFirstRun = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _prefs = PreferencesService();

  // Available AI providers
  late List<AiProvider> _providers;
  late AiProvider _selectedProvider;
  late String? _selectedModel;

  // API key controller
  final _apiKeyController = TextEditingController();

  // Gateway binding
  bool _loopbackOnly = true;

  // State
  bool _testing = false;
  String? _testResult;
  bool _testPassed = false;
  bool _configSaved = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _prefs.init();
    _providers = AiProvider.all;
    _selectedProvider = _providers.first;
    _selectedModel = _selectedProvider.defaultModels.first;
    setState(() => _initialized = true);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  List<String> get _availableModels =>
      _selectedProvider.defaultModels;

  Future<void> _testConnection() async {
    if (_apiKeyController.text.trim().isEmpty) return;

    setState(() {
      _testing = true;
      _testResult = null;
      _testPassed = false;
    });

    try {
      final result = await ProviderConfigService.testConnection(
        providerId: _selectedProvider.id,
        apiKey: _apiKeyController.text.trim(),
        model: _selectedModel ?? _selectedProvider.defaultModels.first,
      );

      if (!mounted) return;
      setState(() {
        _testing = false;
        _testResult = result ? 'Connection successful!' : 'Connection failed';
        _testPassed = result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _testing = false;
        _testResult = 'Error: $e';
        _testPassed = false;
      });
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    // Save API key
    final apiKey = _apiKeyController.text.trim();
    await _prefs.setApiKey(_selectedProvider.id, apiKey);

    // Write openclaw.json config
    final config = {
      'models': {
        _selectedProvider.id: {
          'provider': _selectedProvider.id,
          'model': _selectedModel ?? _selectedProvider.defaultModels.first,
          'apiKey': apiKey,
          'baseUrl': _selectedProvider.baseUrl,
        },
      },
      'bind': _loopbackOnly ? '127.0.0.1' : '0.0.0.0',
      'port': 18789,
      'dataDir': '/root/.openclaw',
    };

    try {
      // Write config file inside proot
      final filesDir = await NativeBridge.getFilesDir();
      final configDir = '$filesDir/rootfs/ubuntu/root/.openclaw';
      Directory(configDir).createSync(recursive: true);
      File('$configDir/openclaw.json')
          .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(config));

      await _prefs.setStringList(
        'configured_providers',
        [_selectedProvider.id],
      );

      // Also save the config via provider_config_service
      await ProviderConfigService.saveProviderConfig(
        provider: _selectedProvider,
        apiKey: apiKey,
        model: _selectedModel ?? _selectedProvider.defaultModels.first,
      );

      if (!mounted) return;
      setState(() => _configSaved = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuration saved successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save config: $e'),
          backgroundColor: AppColors.statusRed,
        ),
      );
    }
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
        title: const Text('>> SYSTEM_CONFIG'),
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
                'DONE',
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
                _buildSectionLabel('AI PROVIDER'),
                const SizedBox(height: 8),
                _buildProviderSelector(),
                const SizedBox(height: 20),

                // Model selection
                _buildSectionLabel('MODEL'),
                const SizedBox(height: 8),
                _buildModelSelector(),
                const SizedBox(height: 20),

                // API Key
                _buildSectionLabel('API KEY'),
                const SizedBox(height: 8),
                _buildApiKeyField(),
                const SizedBox(height: 12),

                // Test connection button
                _buildTestButton(),
                const SizedBox(height: 20),

                // Binding option
                _buildSectionLabel('NETWORK BINDING'),
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
                          ? '>> CONFIG_SAVED'
                          : '>> SAVE_CONFIG',
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
        '> SYSTEM CONFIGURATION v${AppConstants.version}\n'
        '> Select your AI provider and enter API key.\n'
        '> TIP: Use Loopback (127.0.0.1) for local-only access.',
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
      '// ${label.padRight(24, '_')}',
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
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AiProvider>(
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
          },
        ),
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
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
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
      ),
    );
  }

  Widget _buildApiKeyField() {
    return TextFormField(
      controller: _apiKeyController,
      style: const TextStyle(
        color: AppColors.matrixGreen,
        fontSize: 13,
      ),
      decoration: const InputDecoration(
        hintText: 'sk-...',
        prefixIcon: Icon(
          Icons.vpn_key,
          color: AppColors.mutedText,
          size: 18,
        ),
      ),
      obscureText: true,
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'API key is required';
        return null;
      },
    );
  }

  Widget _buildTestButton() {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: _testing || _apiKeyController.text.trim().isEmpty
              ? null
              : _testConnection,
          icon: _testing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.matrixGreen,
                  ),
                )
              : const Icon(Icons.wifi_tethering, size: 18),
          label: Text(_testing ? 'TESTING...' : 'TEST CONNECTION'),
        ),
        if (_testResult != null) ...[
          const SizedBox(width: 12),
          Icon(
            _testPassed ? Icons.check_circle : Icons.error,
            color: _testPassed ? AppColors.statusGreen : AppColors.statusRed,
            size: 18,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _testResult!,
              style: TextStyle(
                color: _testPassed ? AppColors.statusGreen : AppColors.statusRed,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
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
          'Loopback only',
          style: TextStyle(
            color: AppColors.matrixGreen,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          _loopbackOnly ? '127.0.0.1 (recomended)' : '0.0.0.0 (all interfaces)',
          style: TextStyle(
            color: AppColors.mutedText,
            fontSize: 11,
          ),
        ),
        value: _loopbackOnly,
        onChanged: (v) => setState(() => _loopbackOnly = v),
        activeColor: AppColors.matrixGreen,
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Column(
        children: [
          Text(
            'Based on ${AppConstants.upstreamProject}',
            style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${AppConstants.upstreamUrl} · MIT License',
            style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}
