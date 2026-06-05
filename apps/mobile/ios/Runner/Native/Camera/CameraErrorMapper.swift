import AVFoundation
import Foundation

enum CameraNativeError: Error {
  case permissionDenied
  case deviceUnavailable
  case lensUnavailable
  case formatUnsupported
  case sessionFailed(String)
  case alreadyRunning
  case notRunning
  case sessionInterrupted
}

extension CameraNativeError {
  var code: CameraErrorCode {
    switch self {
    case .permissionDenied: return .permissionDenied
    case .deviceUnavailable: return .deviceUnavailable
    case .lensUnavailable: return .lensUnavailable
    case .formatUnsupported: return .formatUnsupported
    case .sessionFailed: return .sessionFailed
    case .alreadyRunning: return .alreadyRunning
    case .notRunning: return .notRunning
    case .sessionInterrupted: return .sessionInterrupted
    }
  }

  var message: String? {
    if case let .sessionFailed(msg) = self { return msg }
    return nil
  }
}
