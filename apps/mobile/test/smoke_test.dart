import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:raro_mobile/app.dart';

void main() {
  testWidgets('RaroApp boots and shows wordmark', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: RaroApp()));
    expect(find.text('RARO'), findsOneWidget);
  });
}
