abstract final class AnalyticsEvents {
  static const String appOpen = 'app_open';
  static const String onboardingStarted = 'onboarding_started';
  static const String onboardingCompleted = 'onboarding_completed';
  static const String permissionsGranted = 'permissions_granted';

  static const String recordingStarted = 'recording_started';
  static const String recordingEnded = 'recording_ended';
  static const String recordingFailed = 'recording_failed';

  static const String voiceWakeDetected = 'voice_wake_detected';
  static const String volumeTriggerUsed = 'volume_trigger_used';
  static const String lensSwitched = 'lens_switched';
  static const String resolutionChanged = 'resolution_changed';
  static const String fpsChanged = 'fps_changed';
  static const String bufferDurationChanged = 'buffer_duration_changed';
  static const String controlModeChanged = 'control_mode_changed';

  static const String lockEntered = 'lock_entered';
  static const String lockExited = 'lock_exited';

  static const String galleryOpened = 'gallery_opened';
  static const String videoShared = 'video_shared';
  static const String videoDeleted = 'video_deleted';

  static const String paywallShown = 'paywall_shown';
  static const String planSelected = 'plan_selected';
  static const String checkoutStarted = 'checkout_started';
  static const String subscriptionActivated = 'subscription_activated';
  static const String restorePurchases = 'restore_purchases';

  static const String languageChanged = 'language_changed';
  static const String xiaomiModalShown = 'xiaomi_modal_shown';
}
