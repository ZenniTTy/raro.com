import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var cameraHostApi: CameraHostApiImpl?
  private var replayBufferHostApi: ReplayBufferHostApiImpl?
  private var voiceHostApi: VoiceHostApiImpl?
  private var volumeHostApi: VolumeHostApiImpl?
  private var galleryHostApi: GalleryHostApiImpl?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "com.rarocamera/camera_preview")
    guard let registrar = registrar else { return }
    let messenger = registrar.messenger()
    let hostApi = CameraHostApiImpl(messenger: messenger)
    self.cameraHostApi = hostApi
    CameraHostApiSetup.setUp(binaryMessenger: messenger, api: hostApi)

    let factory = CameraPlatformViewFactory(hostApi: hostApi)
    hostApi.platformViewFactory = factory
    registrar.register(factory, withId: "com.rarocamera/camera_preview")

    let replayApi = ReplayBufferHostApiImpl(manager: hostApi.cameraManager, messenger: messenger)
    self.replayBufferHostApi = replayApi
    ReplayBufferHostApiSetup.setUp(binaryMessenger: messenger, api: replayApi)

    let voiceFlutterApi = VoiceFlutterApi(binaryMessenger: messenger)
    let voiceManager = VoiceManager(wakeWord: "Raro")
    voiceManager.isRecordingActive = { [weak hostApi] in hostApi?.cameraManager.isRecording ?? false }
    voiceManager.isCameraAudioActive = { [weak hostApi] in hostApi?.cameraManager.isSessionRunning ?? false }
    hostApi.cameraManager.onCaptureAudioSample = { [weak voiceManager] buffer in
      voiceManager?.appendCaptureAudio(buffer)
    }
    hostApi.cameraManager.onSessionStateChanged = { [weak voiceManager] in
      voiceManager?.cameraAudioStateChanged()
    }
    let voiceApi = VoiceHostApiImpl(manager: voiceManager, flutterApi: voiceFlutterApi)
    self.voiceHostApi = voiceApi
    VoiceHostApiSetup.setUp(binaryMessenger: messenger, api: voiceApi)

    let galleryApi = GalleryHostApiImpl()
    self.galleryHostApi = galleryApi
    GalleryHostApiSetup.setUp(binaryMessenger: messenger, api: galleryApi)

    let volumeApi = VolumeHostApiImpl(flutterApi: VolumeFlutterApi(binaryMessenger: messenger))
    self.volumeHostApi = volumeApi
    VolumeHostApiSetup.setUp(binaryMessenger: messenger, api: volumeApi)
  }
}
