import 'dart:ui';

abstract interface class ShareGateway {
  Future<void> shareFile(String path, {Rect? origin});
}
