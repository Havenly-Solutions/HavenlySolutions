import 'env.dart';

const bool kIsProduction = true; // flip to true before flutter build --release

class AppConfig {
  static const String baseUrl = Env.apiBaseUrl;

  static String get wsUrl => baseUrl
      .replaceFirst('https://', 'wss://')
      .replaceFirst('http://', 'ws://');

  static const String appName = 'Havenly Solutions';
  static const String slogan = 'Your Haven. Your Community. Always On.';
  static const String packageName = 'com.theblacksheep.havenly';
  static const String supportEmail = 'vusimbele@havenly.solutions';

  // SSL pinning — fill in after first production deploy
  static const String sslPinSha256 = 'REPLACE_AFTER_FIRST_DEPLOY';

  // Feature flags
  static const bool kUseMockData =
      true; // KEEP TRUE FOR OFFLINE-FIRST LOCAL TESTING
  static const bool kEnableUSSD = true;
  static const bool kEnableBTMesh = true;
  static const bool kEnableDirectSMS = true;
}
