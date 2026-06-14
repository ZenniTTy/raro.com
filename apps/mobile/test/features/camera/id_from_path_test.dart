import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/features/camera/application/camera_flutter_api_provider.dart';

void main() {
  test('idFromPath extrai uuid puro do novo nome raro_<uuid>.mp4', () {
    expect(idFromPathForTest('/x/raro_ABC123.mp4'), 'ABC123');
  });
  test('idFromPath sem prefixo retorna o stem', () {
    expect(idFromPathForTest('/x/ABC123.mp4'), 'ABC123');
  });
}
