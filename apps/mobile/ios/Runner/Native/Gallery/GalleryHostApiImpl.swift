import Foundation
import Photos
import os.log

private let galleryLog = OSLog(subsystem: "com.rarocamera", category: "gallery")

final class GalleryHostApiImpl: GalleryHostApi {
  func saveVideoToSystemGallery(
    videoPath: String,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    let url = URL(fileURLWithPath: videoPath)
    guard FileManager.default.fileExists(atPath: videoPath) else {
      os_log("gallery missing file", log: galleryLog, type: .error)
      self.finish(
        completion,
        .failure(GalleryPigeonError(code: "saveFailed", message: "missing video file", details: nil))
      )
      return
    }

    PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
      guard status == .authorized else {
        os_log("gallery add-only denied status=%d", log: galleryLog, type: .error, status.rawValue)
        self.finish(
          completion,
          .failure(
            GalleryPigeonError(
              code: "permissionDenied",
              message: "addOnly not authorized",
              details: nil
            )
          )
        )
        return
      }

      PHPhotoLibrary.shared().performChanges({
        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
      }) { success, error in
        if let error {
          os_log(
            "gallery performChanges error=%{public}@",
            log: galleryLog,
            type: .error,
            error.localizedDescription
          )
          self.finish(
            completion,
            .failure(
              GalleryPigeonError(
                code: "saveFailed",
                message: error.localizedDescription,
                details: nil
              )
            )
          )
          return
        }
        if success {
          self.finish(completion, .success(()))
          return
        }
        os_log("gallery performChanges returned false", log: galleryLog, type: .error)
        self.finish(
          completion,
          .failure(GalleryPigeonError(code: "saveFailed", message: "not saved", details: nil))
        )
      }
    }
  }

  private func finish(
    _ completion: @escaping (Result<Void, Error>) -> Void,
    _ result: Result<Void, Error>
  ) {
    DispatchQueue.main.async { completion(result) }
  }
}
