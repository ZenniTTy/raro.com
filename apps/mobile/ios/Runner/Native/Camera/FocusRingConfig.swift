import UIKit

enum FocusRingConfig {
  static let color: UIColor = .white
  static let strokeWidth: CGFloat = 1.5
  static let duration: CFTimeInterval = 1.2
  static let scaleFrom: CGFloat = 1.4
  static let scaleTo: CGFloat = 1.0
  static let radius: CGFloat = 32.0
  static let opacityKeyframes: [NSNumber] = [0.0, 1.0, 0.0]
  static let opacityKeyTimes: [NSNumber] = [0.0, 0.2, 1.0]
}
