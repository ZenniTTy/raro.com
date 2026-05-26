enum AppScreen {
  p01Splash('/splash', 'splash'),
  p02Onboarding1('/onboarding/1', 'onboarding_1'),
  p03Onboarding2('/onboarding/2', 'onboarding_2'),
  p04Permissions('/permissions', 'permissions'),
  p05Camera('/camera', 'camera'),
  p05aLockMode('/camera/lock', 'lock_mode'),
  p06Settings('/settings', 'settings'),
  p07Gallery('/gallery', 'gallery'),
  p08Preview('/preview', 'preview'),
  p09Paywall('/paywall', 'paywall'),
  p10Checkout('/checkout', 'checkout'),
  p11Terms('/terms', 'terms'),
  p12Privacy('/privacy', 'privacy');

  const AppScreen(this.path, this.analyticsName);

  final String path;
  final String analyticsName;
}

enum AppModal {
  m01SubscriptionPopup('subscription_popup'),
  m02XiaomiGuide('xiaomi_guide'),
  m03BluetoothControlDetected('bluetooth_control_detected');

  const AppModal(this.analyticsName);

  final String analyticsName;
}
