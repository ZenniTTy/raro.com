String previewResolutionFromSize(double width, double height) {
  final longSide = width > height ? width : height;
  if (longSide >= 3200) return '4K';
  if (longSide >= 1600) return '1080p';
  if (longSide >= 1000) return '720p';
  return '${longSide.round()}p';
}

String previewInfoBadge({
  double? width,
  double? height,
  String? storedResolution,
  String? storedFps,
  String? storedLens,
}) {
  final hasSize = width != null && height != null && width > 0 && height > 0;
  final resolution = storedResolution != null && storedResolution.isNotEmpty
      ? storedResolution
      : hasSize
      ? previewResolutionFromSize(width, height)
      : null;
  final lens = storedLens != null && storedLens.isNotEmpty ? storedLens : '1×';
  if (resolution == null || resolution.isEmpty) return lens;
  final fps = storedFps;
  if (fps == null || fps.isEmpty) return '$resolution · $lens';
  return '$resolution · $fps · $lens';
}
