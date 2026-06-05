import 'dart:convert';
import 'dart:io';

import 'package:raro_mobile/features/camera/domain/recording_metadata.dart';
import 'package:raro_mobile/features/gallery/domain/video_entity.dart';

class VaultService {
  VaultService({required this.documentsDir});

  final Directory documentsDir;

  Directory get _vaultDir => Directory('${documentsDir.path}/vault');
  File _metaFile(String id) => File('${_vaultDir.path}/$id.json');
  File _videoFile(String id) => File('${_vaultDir.path}/$id.mp4');

  Future<VideoEntity> save(
    File source, {
    required RecordingMetadata metadata,
  }) async {
    await _vaultDir.create(recursive: true);
    final dest = _videoFile(metadata.id);
    await source.copy(dest.path);
    await _writeMetaAtomic(metadata.id, _encode(metadata));
    return _toEntity(metadata, dest.path);
  }

  Future<void> _writeMetaAtomic(String id, Map<String, Object?> json) async {
    final tmp = File('${_vaultDir.path}/$id.json.tmp');
    await tmp.writeAsString(jsonEncode(json), flush: true);
    await tmp.rename(_metaFile(id).path);
  }

  Future<void> attachThumbnail(String id, String thumbnailPath) async {
    final metaFile = _metaFile(id);
    if (!metaFile.existsSync()) return;
    final meta = _decode(
      jsonDecode(metaFile.readAsStringSync()) as Map<String, Object?>,
    );
    final updated = RecordingMetadata(
      id: meta.id,
      name: meta.name,
      duration: meta.duration,
      recordedAt: meta.recordedAt,
      isReplay: meta.isReplay,
      thumbnailHue: meta.thumbnailHue,
      thumbnailPath: thumbnailPath,
    );
    await _writeMetaAtomic(id, _encode(updated));
  }

  Future<List<VideoEntity>> listAll() async {
    if (!_vaultDir.existsSync()) return [];
    final metas =
        _vaultDir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.json'))
            .map(
              (f) => _decode(
                jsonDecode(f.readAsStringSync()) as Map<String, Object?>,
              ),
            )
            .toList()
          ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return metas.map((m) => _toEntity(m, _videoFile(m.id).path)).toList();
  }

  Future<void> delete(String id) async {
    final video = _videoFile(id);
    final meta = _metaFile(id);
    final thumb = _thumbFile(id);
    if (video.existsSync()) await video.delete();
    if (meta.existsSync()) await meta.delete();
    if (thumb.existsSync()) await thumb.delete();
  }

  File _thumbFile(String id) => File('${_vaultDir.path}/$id.jpg');

  VideoEntity _toEntity(RecordingMetadata m, String path) {
    final thumb = _thumbFile(m.id);
    return VideoEntity(
      id: m.id,
      name: m.name,
      duration: m.duration,
      recordedAt: m.recordedAt,
      isReplay: m.isReplay,
      thumbnailHue: m.thumbnailHue,
      filePath: path,
      thumbnailPath: thumb.existsSync() ? thumb.path : null,
    );
  }

  Map<String, Object?> _encode(RecordingMetadata m) => {
    'id': m.id,
    'name': m.name,
    'durationMs': m.duration.inMilliseconds,
    'recordedAt': m.recordedAt.toIso8601String(),
    'isReplay': m.isReplay,
    'thumbnailHue': m.thumbnailHue,
    if (m.thumbnailPath != null) 'thumbnailPath': m.thumbnailPath,
  };

  RecordingMetadata _decode(Map<String, Object?> j) => RecordingMetadata(
    id: j['id']! as String,
    name: j['name']! as String,
    duration: Duration(milliseconds: j['durationMs']! as int),
    recordedAt: DateTime.parse(j['recordedAt']! as String),
    isReplay: j['isReplay']! as bool,
    thumbnailHue: j['thumbnailHue']! as int,
    thumbnailPath: j['thumbnailPath'] as String?,
  );
}
