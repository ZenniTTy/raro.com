import 'package:raro_mobile/features/preview/data/share_gateway.dart';
import 'package:raro_mobile/features/preview/data/share_plus_gateway.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'share_gateway_provider.g.dart';

@Riverpod(keepAlive: true)
ShareGateway shareGateway(Ref ref) => SharePlusGateway();
