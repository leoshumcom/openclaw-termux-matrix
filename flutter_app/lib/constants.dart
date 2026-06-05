/// Application constants — modified for Matrix Edition.
///
/// Based on openclaw-termux (https://github.com/mithun50/openclaw-termux)
/// — MIT License. Modifications © 2026 66哥.
class AppConstants {
  static const String appName = 'OpenClaw Matrix';
  static const String version = '1.0.0';
  static const String packageName = 'com.openclaw.matrix';

  /// Matches ANSI escape sequences.
  static final ansiEscape = RegExp(r'\x1b\[[0-9;]*[a-zA-Z]');

  // --- Upstream attribution ---
  static const String upstreamProject = 'openclaw-termux';
  static const String upstreamUrl =
      'https://github.com/mithun50/openclaw-termux';
  static const String upstreamLicense = 'MIT';

  // --- Author info ---
  static const String authorName = '66哥';
  static const String authorEmail = '';
  static const String githubUrl = 'https://github.com/leoshumcom/openclaw-termux-matrix';
  static const String license = 'MIT';

  static const String githubApiLatestRelease =
      'https://api.github.com/repos/leoshumcom/openclaw-termux-matrix/releases/latest';

  // --- Gateway ---
  static const String gatewayHost = '127.0.0.1';
  static const int gatewayPort = 18789;
  static const String gatewayUrl = 'http://$gatewayHost:$gatewayPort';

  // --- Ubuntu rootfs (mirror.tuna.tsinghua.edu.cn for CN users) ---
  static const String ubuntuRootfsUrl =
      'https://mirrors.tuna.tsinghua.edu.cn/ubuntu-cdimage/ubuntu-base/releases/24.04/release/ubuntu-base-24.04.3-base-';
  static const String rootfsArm64 = '${ubuntuRootfsUrl}arm64.tar.gz';
  static const String rootfsArmhf = '${ubuntuRootfsUrl}armhf.tar.gz';
  static const String rootfsAmd64 = '${ubuntuRootfsUrl}amd64.tar.gz';

  // --- Node.js binary tarball (npmmirror.com for CN users) ---
  static const String nodeVersion = '22.14.0';
  static const String nodeBaseUrl =
      'https://npmmirror.com/mirrors/node/v$nodeVersion/node-v$nodeVersion-linux-';

  static String getNodeTarballUrl(String arch) {
    switch (arch) {
      case 'aarch64':
        return '${nodeBaseUrl}arm64.tar.xz';
      case 'arm':
        return '${nodeBaseUrl}armv7l.tar.xz';
      case 'x86_64':
        return '${nodeBaseUrl}x64.tar.xz';
      default:
        return '${nodeBaseUrl}arm64.tar.xz';
    }
  }

  static const int healthCheckIntervalMs = 5000;
  static const int maxAutoRestarts = 5;

  // --- Node constants ---
  static const int wsReconnectBaseMs = 350;
  static const double wsReconnectMultiplier = 1.7;
  static const int wsReconnectCapMs = 8000;
  static const String nodeRole = 'node';
  static const int pairingTimeoutMs = 300000;

  static const String channelName = 'com.openclaw.matrix/native';
  static const String eventChannelName = 'com.openclaw.matrix/gateway_logs';

  static String getRootfsUrl(String arch) {
    switch (arch) {
      case 'aarch64':
        return rootfsArm64;
      case 'arm':
        return rootfsArmhf;
      case 'x86_64':
        return rootfsAmd64;
      default:
        return rootfsArm64;
    }
  }
}
