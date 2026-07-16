import Foundation
import os.log
import OnnxRuntimeBindings

enum OnnxExecutionProvider {
  case cpu
  case coreML
}

final class OnnxModelSession {
  enum LoadError: Error { case modelNotFoundInBundle(String) }

  private static let env: ORTEnv = {
    return try! ORTEnv(loggingLevel: .warning)
  }()
  private static let log = OSLog(subsystem: "com.rarocamera/voice", category: "onnx")

  private let session: ORTSession

  init(modelName: String, executionProvider: OnnxExecutionProvider) throws {
    guard let url = Bundle.main.url(forResource: modelName, withExtension: "onnx") else {
      throw LoadError.modelNotFoundInBundle(modelName)
    }
    let options = try ORTSessionOptions()
    if executionProvider == .coreML {
      do {
        try options.appendCoreMLExecutionProvider(with: ORTCoreMLExecutionProviderOptions())
      } catch {
        os_log("CoreML EP unavailable for %{public}@, falling back to CPU: %{public}@",
               log: Self.log, type: .info, modelName, error.localizedDescription)
      }
    }
    session = try ORTSession(env: Self.env, modelPath: url.path, sessionOptions: options)
  }

  func run(input: [Float], inputName: String, shape: [NSNumber], outputName: String) throws -> [Float] {
    let data = input.withUnsafeBufferPointer { Data(buffer: $0) }
    let value = try ORTValue(tensorData: NSMutableData(data: data),
                             elementType: .float, shape: shape)
    let outputs = try session.run(withInputs: [inputName: value],
                                  outputNames: Set([outputName]),
                                  runOptions: ORTRunOptions())
    guard let out = outputs[outputName] else { return [] }
    let outData = try out.tensorData() as Data
    return outData.withUnsafeBytes { Array($0.bindMemory(to: Float.self)) }
  }
}
