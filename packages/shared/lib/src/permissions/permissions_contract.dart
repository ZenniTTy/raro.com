class PermissionMessage {
  const PermissionMessage({
    required this.ptBr,
    required this.en,
    required this.es,
  });

  final String ptBr;
  final String en;
  final String es;
}

abstract final class PermissionsContract {
  static const Map<String, PermissionMessage> ios = {
    'NSCameraUsageDescription': PermissionMessage(
      ptBr: 'A Raro Camera precisa da câmera para gravar vídeos.',
      en: 'Raro Camera needs the camera to record videos.',
      es: 'Raro Camera necesita la cámara para grabar videos.',
    ),
    'NSMicrophoneUsageDescription': PermissionMessage(
      ptBr: 'A Raro Camera precisa do microfone para capturar áudio.',
      en: 'Raro Camera needs the microphone to capture audio.',
      es: 'Raro Camera necesita el micrófono para capturar audio.',
    ),
    'NSSpeechRecognitionUsageDescription': PermissionMessage(
      ptBr:
          'A Raro Camera usa reconhecimento de voz no dispositivo para detectar "Raro".',
      en: 'Raro Camera uses on-device speech recognition to detect "Raro".',
      es: 'Raro Camera usa reconocimiento de voz en el dispositivo para detectar "Raro".',
    ),
    'NSPhotoLibraryAddUsageDescription': PermissionMessage(
      ptBr:
          'A Raro Camera salva os vídeos na galeria do celular quando você escolhe guardar.',
      en: 'Raro Camera saves videos to your photo library when you choose to keep them.',
      es: 'Raro Camera guarda los videos en la galería cuando eliges conservarlos.',
    ),
  };

  static const List<String> android = [
    'android.permission.CAMERA',
    'android.permission.RECORD_AUDIO',
    'android.permission.WRITE_EXTERNAL_STORAGE',
  ];
}
