@preconcurrency import AVFoundation
import Foundation
import os.log
import UIKit

private let thumbnailLog = OSLog(subsystem: "com.rarocamera", category: "thumbnail")

enum ThumbnailGeneratorError: Error {
  case assetUnreadable
  case encodingFailed
}

final class ThumbnailGenerator: @unchecked Sendable {
  static func makeThumbnailURL(for videoURL: URL) -> URL {
    videoURL.deletingPathExtension().appendingPathExtension("jpg")
  }

  func generate(
    videoPath: String,
    completion: @escaping (Result<String, Error>) -> Void
  ) {
    let videoURL = URL(fileURLWithPath: videoPath)
    let asset = AVURLAsset(url: videoURL)
    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true
    generator.requestedTimeToleranceBefore = .zero
    generator.requestedTimeToleranceAfter = .zero

    let time = CMTime.zero
    generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) {
      _, cgImage, _, result, error in
      if let error = error {
        os_log(
          "thumbnail failed: %{public}@",
          log: thumbnailLog, type: .error, error.localizedDescription
        )
        completion(.failure(error))
        return
      }
      guard result == .succeeded, let cgImage = cgImage else {
        os_log("thumbnail asset unreadable", log: thumbnailLog, type: .error)
        completion(.failure(ThumbnailGeneratorError.assetUnreadable))
        return
      }
      let image = UIImage(cgImage: cgImage)
      guard let data = image.jpegData(compressionQuality: 0.8) else {
        os_log("thumbnail jpeg encoding failed", log: thumbnailLog, type: .error)
        completion(.failure(ThumbnailGeneratorError.encodingFailed))
        return
      }
      let destURL = Self.makeThumbnailURL(for: videoURL)
      do {
        try data.write(to: destURL, options: .atomic)
        os_log(
          "thumbnail generated path=%{public}@",
          log: thumbnailLog, type: .info, destURL.path
        )
        completion(.success(destURL.path))
      } catch {
        os_log(
          "thumbnail write failed: %{public}@",
          log: thumbnailLog, type: .error, error.localizedDescription
        )
        completion(.failure(error))
      }
    }
  }
}
