import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var cameraHostApi: CameraHostApiImpl?
  private var replayBufferHostApi: ReplayBufferHostApiImpl?
  private var voiceHostApi: VoiceHostApiImpl?

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
    let voiceApi = VoiceHostApiImpl(manager: voiceManager, flutterApi: voiceFlutterApi)
    self.voiceHostApi = voiceApi
    VoiceHostApiSetup.setUp(binaryMessenger: messenger, api: voiceApi)
  }
}
