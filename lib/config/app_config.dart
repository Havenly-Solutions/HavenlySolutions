const bool kIsProduction = false; // flip to true before flutter build --release

class AppConfig {
  static const String baseUrl = kIsProduction
      ? 'https://api.havenly.solutions'
      : 'http://10.0.2.2:5000';

  static const String wsUrl = kIsProduction
      ? 'wss://api.havenly.solutions'
      : 'ws://10.0.2.2:5000';

  static const String appName = 'Havenly Solutions';
  static const String slogan = 'Your Haven. Your Community. Always On.';
  static const String packageName = 'com.theblacksheep.havenly';
  static const String supportEmail = 'vusimbele@havenly.solutions';

  // SSL pinning — fill in after first production deploy
  static const String sslPinSha256 = 'REPLACE_AFTER_FIRST_DEPLOY';

  // Feature flags
  static const bool kUseMockData = true; // set false when backend is live
  static const bool kEnableUSSD = true;
  static const bool kEnableBTMesh = true;
  static const bool kEnableDirectSMS = true;
}
