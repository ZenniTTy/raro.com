import 'package:raro_shared/raro_shared.dart';
import 'package:test/test.dart';

void main() {
  group('Family 1 — Identity', () {
    test('display name is "Raro Camera"', () {
      expect(AppIdentity.displayName, 'Raro Camera');
    });

    test('bundle id is com.rarocamera', () {
      expect(AppIdentity.bundleId, 'com.rarocamera');
    });

    test('application id matches bundle id', () {
      expect(AppIdentity.applicationId, AppIdentity.bundleId);
    });
  });

  group('Family 2 — Invariants', () {
    test('wake word is "Raro" (never "OkCamera")', () {
      expect(VoiceConfig.wakeWord, 'Raro');
    });

    test('free trial is 30 days', () {
      expect(SubscriptionConfig.freeTrialDays, 30);
    });

    test('monthly SKU matches Blueprint 2.4', () {
      expect(SubscriptionSkus.monthly, 'raro_premium_monthly_BRL_9_90');
    });

    test('yearly SKU matches Blueprint 2.4', () {
      expect(SubscriptionSkus.yearly, 'raro_premium_yearly_BRL_89_90');
    });

    test('entitlement is "premium"', () {
      expect(SubscriptionConfig.entitlement, 'premium');
    });

    test('monthly display price is R\$ 9,90 (ADR-0010)', () {
      expect(PlanPricing.monthlyBRL, 9.90);
    });

    test('yearly display price is R\$ 89,90 (ADR-0010)', () {
      expect(PlanPricing.yearlyBRL, 89.90);
    });

    test('yearly monthly-equivalent is R\$ 7,49 (ADR-0010)', () {
      expect(PlanPricing.yearlyMonthlyEquivalentBRL, 7.49);
    });
  });

  group('Family 5 — Domain enums', () {
    test('Lens has ultraWide and wide', () {
      expect(Lens.values, [Lens.ultraWide, Lens.wide]);
      expect(Lens.ultraWide.label, '0.5x');
      expect(Lens.wide.label, '1x');
    });

    test('Fps has 30 and 60', () {
      expect(Fps.values.map((f) => f.value), [30, 60]);
    });

    test('Resolution has 4 levels', () {
      expect(Resolution.values.length, 4);
    });

    test('BufferDuration has 15s and 30s', () {
      expect(BufferDuration.values.map((b) => b.value), [15, 30]);
    });

    test('ControlMode has voice and volume', () {
      expect(ControlMode.values, [ControlMode.voice, ControlMode.volume]);
    });

    test('AppLanguage has pt-BR, en, es', () {
      expect(AppLanguage.values.map((l) => l.tag), ['pt-BR', 'en', 'es']);
    });
  });

  group('Family 6 — Analytics event names', () {
    test('event names follow snake_case pattern', () {
      const names = [
        AnalyticsEvents.appOpen,
        AnalyticsEvents.recordingStarted,
        AnalyticsEvents.planSelected,
        AnalyticsEvents.subscriptionActivated,
      ];
      for (final n in names) {
        expect(n, matches(RegExp(r'^[a-z][a-z0-9_]+$')));
      }
    });
  });

  group('Family 7 — Analytics payloads', () {
    test('RecordingStartedPayload.toMap returns expected keys/values', () {
      const p = RecordingStartedPayload(
        lens: Lens.wide,
        resolution: Resolution.fullHd1080,
        fps: Fps.fps60,
        trigger: ControlMode.voice,
        bufferDuration: BufferDuration.seconds15,
      );
      expect(p.toMap(), {
        'lens': '1x',
        'resolution': '1080p',
        'fps': 60,
        'trigger': 'voice',
        'buffer_duration': 15,
      });
    });

    test('PlanSelectedPayload.toMap returns sku key', () {
      const p = PlanSelectedPayload(sku: SubscriptionSkus.monthly);
      expect(p.toMap(), {'sku': 'raro_premium_monthly_BRL_9_90'});
    });

    test('LensSwitchedPayload.toMap returns from/to', () {
      const p = LensSwitchedPayload(from: Lens.ultraWide, to: Lens.wide);
      expect(p.toMap(), {'from': '0.5x', 'to': '1x'});
    });
  });

  group('Family 8 — AppScreen + AppModal', () {
    test('AppScreen paths are unique', () {
      final paths = AppScreen.values.map((s) => s.path).toList();
      expect(paths.toSet().length, paths.length, reason: 'duplicate path');
    });

    test('AppScreen analyticsNames are unique', () {
      final names = AppScreen.values.map((s) => s.analyticsName).toList();
      expect(
        names.toSet().length,
        names.length,
        reason: 'duplicate analyticsName',
      );
    });

    test('AppModal analyticsNames are unique', () {
      final names = AppModal.values.map((m) => m.analyticsName).toList();
      expect(names.toSet().length, names.length);
    });

    test('AppScreen has 13 entries (Blueprint Seção 5)', () {
      expect(AppScreen.values.length, 13);
    });

    test('AppModal has 3 entries', () {
      expect(AppModal.values.length, 3);
    });
  });

  group('Family 9 — StorageKeys', () {
    test('all keys follow raro.<domain>.<key>', () {
      const keys = [
        StorageKeys.onboardingCompleted,
        StorageKeys.selectedLanguage,
        StorageKeys.preferredResolution,
        StorageKeys.preferredFps,
        StorageKeys.preferredBufferDuration,
        StorageKeys.preferredControlMode,
        StorageKeys.xiaomiGuideShown,
        StorageKeys.firstLaunchAt,
        StorageKeys.lastLanguageDetected,
        StorageKeys.subscriptionActive,
        StorageKeys.trialStartedAt,
      ];
      for (final k in keys) {
        expect(k, matches(RegExp(r'^raro\.[a-z_]+\.[a-z_]+$')));
      }
    });
  });

  group('Family 3 — BridgeChannels', () {
    test('all channels start with com.rarocamera/', () {
      const channels = [
        BridgeChannels.camera,
        BridgeChannels.replayBuffer,
        BridgeChannels.voice,
        BridgeChannels.volume,
        BridgeChannels.gallery,
      ];
      for (final c in channels) {
        expect(c, startsWith('com.rarocamera/'));
      }
    });
  });

  group('Family 10 — PermissionsContract', () {
    test('iOS keys present', () {
      expect(
        PermissionsContract.ios.containsKey('NSCameraUsageDescription'),
        isTrue,
      );
      expect(
        PermissionsContract.ios.containsKey('NSMicrophoneUsageDescription'),
        isTrue,
      );
      expect(
        PermissionsContract.ios.containsKey(
          'NSSpeechRecognitionUsageDescription',
        ),
        isTrue,
      );
      expect(
        PermissionsContract.ios.containsKey(
          'NSPhotoLibraryAddUsageDescription',
        ),
        isTrue,
      );
    });

    test('Android permissions present', () {
      expect(
        PermissionsContract.android,
        contains('android.permission.CAMERA'),
      );
      expect(
        PermissionsContract.android,
        contains('android.permission.RECORD_AUDIO'),
      );
      expect(
        PermissionsContract.android,
        contains('android.permission.WRITE_EXTERNAL_STORAGE'),
      );
    });
  });

  group('Family 2/12 — ForbiddenTerms', () {
    test('contains forbidden variants', () {
      expect(ForbiddenTerms.all.length, greaterThanOrEqualTo(3));
      expect(
        ForbiddenTerms.all.any((t) => t.toLowerCase().contains('camera')),
        isTrue,
      );
    });
  });
}
