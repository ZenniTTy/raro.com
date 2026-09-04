import 'dart:ui';

import 'package:raro_mobile/features/preview/data/share_gateway.dart';

class FakeShareGateway implements ShareGateway {
  final List<String> shared = [];

  @override
  Future<void> shareFile(String path, {Rect? origin}) async {
    shared.add(path);
  }
}
