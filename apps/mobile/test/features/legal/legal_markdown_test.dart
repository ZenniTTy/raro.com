import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/features/legal/domain/legal_markdown.dart';

void main() {
  test('legalMarkdownToPlain remove heading, bold e link', () {
    const source = '''
# Política de Privacidade — Raro Camera

O controlador é **Vitor Autorino Lopes (Raro Camera)**.

Versão pública: [https://rarocamera.com.br/privacidade](https://rarocamera.com.br/privacidade).
''';
    final plain = legalMarkdownToPlain(source);
    expect(plain, contains('Política de Privacidade — Raro Camera'));
    expect(plain, contains('Vitor Autorino Lopes (Raro Camera)'));
    expect(plain, contains('https://rarocamera.com.br/privacidade'));
    expect(plain, isNot(contains('##')));
    expect(plain, isNot(contains('**')));
    expect(plain, isNot(contains('](')));
  });
}
