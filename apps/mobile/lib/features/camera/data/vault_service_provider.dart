import 'package:path_provider/path_provider.dart';
import 'package:raro_mobile/features/camera/data/vault_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'vault_service_provider.g.dart';

@Riverpod(keepAlive: true)
Future<VaultService> vaultService(Ref ref) async {
  final dir = await getApplicationDocumentsDirectory();
  return VaultService(documentsDir: dir);
}
