import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/features/camera/domain/camera_error_message.dart';

void main() {
  group('cameraErrorMessage', () {
    test('sessionInterrupted retorna mensagem distinta e acionável', () {
      expect(
        cameraErrorMessage(CameraErrorCode.sessionInterrupted),
        'Câmera interrompida. Tente novamente.',
      );
    });

    test('sessionFailed retorna a falha genérica de gravação', () {
      expect(
        cameraErrorMessage(CameraErrorCode.sessionFailed),
        'Falha ao gravar',
      );
    });

    test('null (erro não-mapeado) cai na falha genérica de gravação', () {
      expect(cameraErrorMessage(null), 'Falha ao gravar');
    });

    test('formatUnsupported reporta resolução indisponível', () {
      expect(
        cameraErrorMessage(CameraErrorCode.formatUnsupported),
        'Resolução indisponível neste aparelho.',
      );
    });
  });
}
