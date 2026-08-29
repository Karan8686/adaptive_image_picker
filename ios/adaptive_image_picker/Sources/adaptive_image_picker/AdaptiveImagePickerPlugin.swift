import Flutter
import UIKit
import PhotosUI
import MobileCoreServices
import UniformTypeIdentifiers

public class AdaptiveImagePickerPlugin: NSObject, FlutterPlugin, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate {
  private var pendingResult: FlutterResult?
  private var presentedPicker: UIViewController?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "adaptive_image_picker", binaryMessenger: registrar.messenger())
    let instance = AdaptiveImagePickerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)

    case "pickImages":
      if pendingResult != nil {
        result(FlutterError(code: "ALREADY_ACTIVE", message: "A media picking session is already in progress.", details: nil))
        return
      }

      guard let rootViewController = topViewController() else {
        result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "Cannot find root view controller.", details: nil))
        return
      }

      pendingResult = result
      let args = call.arguments as? [String: Any] ?? [:]
      let isMultiple = args["isMultiple"] as? Bool ?? false
      let maxCount = args["maxCount"] as? Int ?? 1
      let mediaType = args["mediaType"] as? String ?? "image"

      if #available(iOS 14, *) {
        var config = PHPickerConfiguration()
        config.selectionLimit = isMultiple ? maxCount : 1

        switch mediaType {
        case "video":
          config.filter = .videos
        case "all":
          config.filter = .any(of: [.images, .videos])
        default:
          config.filter = .images
        }

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        presentedPicker = picker
        rootViewController.present(picker, animated: true, completion: nil)
      } else {
        // Fallback for iOS 13
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        presentedPicker = picker
        rootViewController.present(picker, animated: true, completion: nil)
      }

    case "takePhoto":
      if pendingResult != nil {
        result(FlutterError(code: "ALREADY_ACTIVE", message: "A media session is already in progress.", details: nil))
        return
      }

      guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
        result(FlutterError(code: "CAMERA_UNAVAILABLE", message: "Device camera is not available.", details: nil))
        return
      }

      guard let rootViewController = topViewController() else {
        result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "Cannot find root view controller.", details: nil))
        return
      }

      pendingResult = result
      let args = call.arguments as? [String: Any] ?? [:]
      let preferredCamera = args["preferredCameraDevice"] as? String ?? "rear"

      let picker = UIImagePickerController()
      picker.delegate = self
      picker.sourceType = .camera
      if preferredCamera == "front" && UIImagePickerController.isCameraDeviceAvailable(.front) {
        picker.cameraDevice = .front
      } else {
        picker.cameraDevice = .rear
      }

      presentedPicker = picker
      rootViewController.present(picker, animated: true, completion: nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - PHPickerViewControllerDelegate (iOS 14+)
  @available(iOS 14, *)
  public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    picker.dismiss(animated: true, completion: nil)
    presentedPicker = nullPicker()

    guard !results.isEmpty else {
      pendingResult?([])
      pendingResult = nil
      return
    }

    let dispatchGroup = DispatchGroup()
    var pickedFiles: [[String: Any]] = []
    let serialQueue = DispatchQueue(label: "com.yourdomain.adaptive_image_picker.results")

    for result in results {
      let itemProvider = result.itemProvider
      dispatchGroup.enter()

      // Try loading file representation
      if itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
        itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { [weak self] (url, error) in
          defer { dispatchGroup.leave() }
          if let url = url, let tempInfo = self?.saveToTempDir(from: url) {
            serialQueue.async {
              pickedFiles.append(tempInfo)
            }
          }
        }
      } else if itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
        itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] (url, error) in
          defer { dispatchGroup.leave() }
          if let url = url, let tempInfo = self?.saveToTempDir(from: url) {
            serialQueue.async {
              pickedFiles.append(tempInfo)
            }
          }
        }
      } else {
        // Fallback UIImage load
        itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (object, error) in
          defer { dispatchGroup.leave() }
          if let image = object as? UIImage, let tempInfo = self?.saveImageToTemp(image: image) {
            serialQueue.async {
              pickedFiles.append(tempInfo)
            }
          }
        }
      }
    }

    dispatchGroup.notify(queue: .main) { [weak self] in
      self?.pendingResult?(pickedFiles)
      self?.pendingResult = nil
    }
  }

  // MARK: - UIImagePickerControllerDelegate
  public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    picker.dismiss(animated: true, completion: nil)
    presentedPicker = nullPicker()

    if let image = info[.originalImage] as? UIImage {
      if let fileInfo = saveImageToTemp(image: image) {
        if picker.sourceType == .camera {
          pendingResult?(fileInfo)
        } else {
          pendingResult?([fileInfo])
        }
      } else {
        pendingResult?(picker.sourceType == .camera ? nil : [])
      }
    } else if let mediaUrl = info[.mediaURL] as? URL {
      if let fileInfo = saveToTempDir(from: mediaUrl) {
        if picker.sourceType == .camera {
          pendingResult?(fileInfo)
        } else {
          pendingResult?([fileInfo])
        }
      } else {
        pendingResult?(picker.sourceType == .camera ? nil : [])
      }
    } else {
      pendingResult?(picker.sourceType == .camera ? nil : [])
    }
    pendingResult = nil
  }

  public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true, completion: nil)
    presentedPicker = nullPicker()
    pendingResult?(picker.sourceType == .camera ? nil : [])
    pendingResult = nil
  }

  // MARK: - Helpers
  private func nullPicker() -> UIViewController? {
    return nil
  }

  private func saveToTempDir(from originalUrl: URL) -> [String: Any]? {
    let tempDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("adaptive_picker")
    try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: nil)

    let fileName = UUID().uuidString + "_" + originalUrl.lastPathComponent
    let destinationUrl = tempDir.appendingPathComponent(fileName)

    do {
      if FileManager.default.fileExists(atPath: destinationUrl.path) {
        try FileManager.default.removeItem(at: destinationUrl)
      }
      try FileManager.default.copyItem(at: originalUrl, to: destinationUrl)

      let attributes = try FileManager.default.attributesOfItem(atPath: destinationUrl.path)
      let fileSize = attributes[.size] as? Int ?? 0

      return [
        "path": destinationUrl.path,
        "name": fileName,
        "size": fileSize,
        "mimeType": mimeTypeForPath(path: destinationUrl.path)
      ]
    } catch {
      return nil
    }
  }

  private func saveImageToTemp(image: UIImage) -> [String: Any]? {
    let tempDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("adaptive_picker")
    try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: nil)

    let fileName = "photo_\(UUID().uuidString).jpg"
    let fileUrl = tempDir.appendingPathComponent(fileName)

    guard let data = image.jpegData(compressionQuality: 0.95) else { return nil }

    do {
      try data.write(to: fileUrl)
      return [
        "path": fileUrl.path,
        "name": fileName,
        "size": data.count,
        "width": Int(image.size.width * image.scale),
        "height": Int(image.size.height * image.scale),
        "mimeType": "image/jpeg"
      ]
    } catch {
      return nil
    }
  }

  private func mimeTypeForPath(path: String) -> String {
    let ext = (path as NSString).pathExtension.lowercased()
    switch ext {
    case "jpg", "jpeg": return "image/jpeg"
    case "png": return "image/png"
    case "heic": return "image/heic"
    case "webp": return "image/webp"
    case "mov": return "video/quicktime"
    case "mp4": return "video/mp4"
    default: return "application/octet-stream"
    }
  }

  private func topViewController() -> UIViewController? {
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let window = windowScene.windows.first(where: { $0.isKeyWindow }),
          var top = window.rootViewController else {
      return UIApplication.shared.keyWindow?.rootViewController
    }

    while let presented = top.presentedViewController {
      top = presented
    }
    return top
  }
}
