import 'dart:ui';

import 'package:raro_mobile/features/preview/data/share_gateway.dart';
import 'package:share_plus/share_plus.dart';

class SharePlusGateway implements ShareGateway {
  @override
  Future<void> shareFile(String path, {Rect? origin}) {
    return SharePlus.instance.share(
      ShareParams(files: [XFile(path)], sharePositionOrigin: origin),
    );
  }
}
