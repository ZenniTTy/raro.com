import 'package:raro_shared/raro_shared.dart';

String captureResolutionLabel(Resolution resolution) {
  switch (resolution) {
    case Resolution.hd720:
      return '720p';
    case Resolution.fullHd1080:
      return '1080p';
    case Resolution.uhd4k:
    case Resolution.uhd4k60:
      return '4K';
  }
}

String captureFpsLabel(Fps fps) {
  switch (fps) {
    case Fps.fps30:
      return '30FPS';
    case Fps.fps60:
      return '60FPS';
  }
}
