# Privacy Policy — Raro Camera

Last updated: 4 September 2026.

This text describes what the **Raro Camera** app (iOS and Android, identifier `com.rarocamera`) does with data. It is not legal advice.

## 1. Who is responsible

The controller of personal data is:

**Vitor Autorino Lopes (Raro Camera)**

To exercise your rights or ask a question: **rarocan1@gmail.com**.

Public version of this text: [https://rarocamera.com.br/en/privacy](https://rarocamera.com.br/en/privacy).

We do not ask for a sign-up, login, name, or email inside the app. We do not run our own server (there is no API or video cloud of ours).

These website pages are static files. **We do not use cookies or analytics on this site.**

## 2. Summary

Raro Camera records video on the device, with an optional on-device voice command (“Raro gravar” / “Raro parar”) and a local replay buffer. Files stay on the device. What leaves the device without your export or share action is only usage telemetry, crash reports, and — if you subscribe — the store receipt handled by RevenueCat and the App Store or Google Play.

## 3. What we do not ask for and do not send

The app does **not**:

- create an account, profile, or password;
- ask for email, phone, tax ID, or address;
- read your contacts, calendar, or location;
- read your camera roll (on iOS it only **adds** a video when you choose to save);
- send the video file or the recording audio to us;
- send a transcript of your speech to us or to a server of ours;
- show third-party ads.

## 4. What stays only on the device

### 4.1 Video, audio, and thumbnail

Clips (MP4), embedded audio, the thumbnail, and a sidecar file (duration, date, resolution, fps, lens, whether it came from replay) stay in the app’s private space.

There is no automatic cloud copy. There is no sync between an iPhone and an Android. If you delete the app, that sandbox library goes with it.

Permanently saving the clip (app vault + system gallery) and sharing it require an active subscription. Without a subscription you can still record and watch the result on the preview screen; declining the subscription discards that recording’s temporary file. Videos already in the vault stay on the device.

Deleting a clip in the app removes it from the vault. It does **not** remove a copy you already exported to Photos / the Android gallery.

### 4.2 Preferences

In local system storage the app keeps only what it needs to run: onboarding done, language, resolution, fps, buffer length, control mode, whether the Xiaomi notice was shown, first-launch date, and a local cache of subscription state. That is not an account.

### 4.3 Voice

Speech recognition runs **on the device**:

- **Android:** Vosk, on the phone, including in the background via a microphone foreground service.
- **iOS:** speech recognition with processing **required to stay on-device**.

Voice audio is **not sent** to a server of ours. Technical logs record only whether the recognized command was start or stop — **not** the spoken text.

You can refuse the microphone. Without it there is no voice command and no sound on the clip; the video camera can still be used if camera permission is granted.

## 5. What leaves the device

### 5.1 Firebase Analytics (Google)

We use Firebase Analytics to know whether the app opens, whether the camera starts, and whether a camera error occurred.

In this version, the custom events our code fires are:

- `camera_started` — active lens, resolution, and fps;
- `camera_error` — error code and, if present, the technical message.

The product has a longer list of planned event names (for example open, paywall, plan selected, lens switch). Those names exist in code; most are not sent yet. The Firebase SDK also records automatic events (first open, session, app update).

We do not attach these events to an email or a name. We do not send video or speech.

The Firebase SDK, unless turned off separately, may collect device identifiers and, on Android, the advertising identifier. Raro Camera does **not** use that identifier for ads. We do not request Apple’s tracking permission (ATT). There is **no** in-app Analytics toggle today.

Google’s policy: [https://policies.google.com/privacy](https://policies.google.com/privacy)

### 5.2 Firebase Crashlytics (Google)

If the app quits or throws an uncaught error, Crashlytics receives the stack, app version, and the device/OS data the SDK includes by default. That is for fixing the app. We do not attach your name or email.

### 5.3 Subscription — RevenueCat, Apple, and Google

We do not process cards. The purchase goes through the **App Store** (iOS) or **Google Play** (Android).

RevenueCat receives an anonymous SDK user identifier (we do not log in) and the store receipt, so it can tell whether the premium benefit is active and until when. That unlocks save and share, and the “Restore purchases” button.

Apple or Google charges you, stores the payment method, and authenticates you with the account already on the phone. There is no automatic subscription share between iPhone and Android: they are different stores.

- RevenueCat: [https://www.revenuecat.com/privacy](https://www.revenuecat.com/privacy)
- Apple: [https://www.apple.com/legal/privacy/](https://www.apple.com/legal/privacy/)
- Google Play: [https://policies.google.com/privacy](https://policies.google.com/privacy)

### 5.4 Export and share (you choose)

If you have a subscription and tap save, the app writes the MP4 to the system gallery (on iOS, add-only; on Android, `Movies/Raro Camera/`). From then on the file also follows the gallery’s rules.

If you tap share, the system opens the native sheet. The destination (WhatsApp, Files, AirDrop, etc.) is your choice. That destination is no longer our processing.

### 5.5 Internet

The app asks for network access for Analytics, Crashlytics, and subscription. Recording and watching clips already in the vault does **not** require internet.

## 6. System permissions

| Permission | Why | Can you refuse? |
|---|---|---|
| Camera | Preview and recording | Yes. Without camera the app does not record video |
| Microphone | Clip audio and voice command | Yes. Without microphone there is no voice and no sound on the video |
| Speech recognition (iOS) | Understand “Raro gravar” / “Raro parar” on-device | Yes. Without it iOS voice command does not work |
| Add to gallery (iOS) / legacy storage (Android 9 and below) | Only when you ask to save the clip | Yes. The clip can stay only in the app vault (if the subscription allows persist) |
| Notifications (Android) | Notice for the background microphone service | Yes. The system may limit the background service |
| Foreground service / microphone (Android) | Keep voice listening while the app is in the background | Without it Android background voice does not start |
| Internet | Analytics, crashes, subscription | Without network those parts stay silent; local camera still works |

None of these permissions is used to read your camera roll or to track ads.

## 7. Purposes

We process the minimum the app needs to:

- do what you asked (record, save, share, subscribe, restore a purchase);
- improve stability and usage (Analytics and Crashlytics, without camera content);
- meet store and legal rules (subscription receipt, answering your request).

We do not sell data. We do not make an automated decision with legal effect beyond “premium is on or off”, and that comes from the store receipt.

## 8. Your rights

You may email **rarocan1@gmail.com** to ask for confirmation of processing, access, correction, anonymization, portability where it applies, information about sharing, and withdrawal of system permissions (those are also withdrawn in iOS Settings / Android Settings).

Practical paths without waiting for email:

- **Vault videos:** delete them in the app or uninstall the app.
- **System gallery copy:** delete it in Photos / Gallery — Raro Camera does not touch it on delete.
- **Permissions:** the device settings.
- **Subscription:** cancel in the App Store or Google Play; RevenueCat will stop seeing an active receipt.
- **Anonymous RevenueCat identifier / crash and analytics data:** ask via the email above. We do not have an account for you; the request will be sent to the processor where we can identify a record.

If you are in Brazil, the ANPD is the supervisory authority.

## 9. How long it stays

| Data | Retention |
|---|---|
| Clip and sidecar in the vault | Until you delete it or uninstall the app |
| System gallery copy | Until you delete it in the gallery; it does not follow in-app delete |
| Local preferences | Until you clear app data or uninstall |
| Analytics / crash events | Firebase project default retention |
| Receipt / entitlement in RevenueCat | While the store and RevenueCat keep that anonymous identifier |

## 10. Transfer outside Brazil

Google (Firebase) and RevenueCat process data outside Brazil, generally in the United States, under their contracts with the app publisher. We do not host our video in another country because **we do not host video**.

## 11. Children

The app does not ask for age and has no children’s area. It is not made for children. If you are responsible for a minor and want us to delete what we can identify at the processors, write to **rarocan1@gmail.com**.

Store age ratings are set in App Store Connect and Play Console at publish time.

## 12. Changes

If the app starts collecting something new (login, cloud, another SDK), this policy must be rewritten **before** that change. The date at the top changes. The canonical URL keeps pointing at the current text.

## 13. Contact

Vitor Autorino Lopes (Raro Camera)  
Email: rarocan1@gmail.com  
Document: [https://rarocamera.com.br/en/privacy](https://rarocamera.com.br/en/privacy)
