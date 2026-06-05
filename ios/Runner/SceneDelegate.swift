import Flutter
import AVFoundation
import AVKit
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  private var nativeVideoChannel: FlutterMethodChannel?

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    registerNativeVideoChannel()
  }

  private func registerNativeVideoChannel() {
    guard nativeVideoChannel == nil,
          let controller = window?.rootViewController as? FlutterViewController else {
      return
    }

    let channel = FlutterMethodChannel(
      name: "dimensional/native_video",
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "openVideo" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let arguments = call.arguments as? [String: Any],
            let url = arguments["url"] as? String,
            !url.isEmpty else {
        result(FlutterError(code: "INVALID_URL", message: "Video url is empty", details: nil))
        return
      }
      let title = arguments["title"] as? String ?? "Video"
      let audioUrl = arguments["audioUrl"] as? String
      self?.presentNativeVideo(url: url, title: title, audioUrl: audioUrl)
      result(true)
    }
    nativeVideoChannel = channel
  }

  private func presentNativeVideo(url: String, title: String, audioUrl: String?) {
    guard let presenter = window?.rootViewController,
          let videoURL = URL(string: url) else {
      return
    }
    let player = SyncedVideoViewController(videoURL: videoURL, audioURL: audioUrl.flatMap(URL.init(string:)))
    player.modalPresentationStyle = .fullScreen
    presenter.present(player, animated: true)
  }
}

final class SyncedVideoViewController: UIViewController {
  private let videoURL: URL
  private let audioURL: URL?
  private let videoPlayer: AVPlayer
  private let playerViewController = AVPlayerViewController()
  private var audioPlayer: AVPlayer?
  private var videoReady = false
  private var audioReady = false
  private var videoStatusObservation: NSKeyValueObservation?
  private var audioStatusObservation: NSKeyValueObservation?

  init(videoURL: URL, audioURL: URL?) {
    self.videoURL = videoURL
    self.audioURL = audioURL
    self.videoPlayer = AVPlayer(url: videoURL)
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    nil
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .black

    if audioURL != nil {
      videoPlayer.isMuted = true
    }
    playerViewController.player = videoPlayer
    playerViewController.showsPlaybackControls = true
    addChild(playerViewController)
    view.addSubview(playerViewController.view)
    playerViewController.view.frame = view.bounds
    playerViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    playerViewController.didMove(toParent: self)

    let closeButton = UIButton(type: .system)
    closeButton.setTitle("Close", for: .normal)
    closeButton.setTitleColor(.white, for: .normal)
    closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.45)
    closeButton.layer.cornerRadius = 16
    closeButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)
    closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
    closeButton.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(closeButton)
    NSLayoutConstraint.activate([
      closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
      closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
    ])

    configurePlayers()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    videoPlayer.pause()
    audioPlayer?.pause()
  }

  private func configurePlayers() {
    videoStatusObservation = videoPlayer.currentItem?.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
      guard let self else { return }
      if item.status == .readyToPlay {
        self.videoReady = true
        self.startWhenReady()
      } else if item.status == .failed {
        self.showError(item.error?.localizedDescription ?? "Video loading failed")
      }
    }

    if let audioURL {
      let player = AVPlayer(url: audioURL)
      audioPlayer = player
      audioStatusObservation = player.currentItem?.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
        guard let self else { return }
        if item.status == .readyToPlay {
          self.audioReady = true
          self.startWhenReady()
        } else if item.status == .failed {
          self.audioPlayer = nil
          self.audioReady = true
          self.videoPlayer.isMuted = false
          self.startWhenReady()
        }
      }
    } else {
      audioReady = true
    }
  }

  private func startWhenReady() {
    guard videoReady, audioReady else { return }
    videoPlayer.play()
    audioPlayer?.play()
  }

  private func showError(_ message: String) {
    let alert = UIAlertController(title: "Playback failed", message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Close", style: .default) { [weak self] _ in
      self?.dismiss(animated: true)
    })
    present(alert, animated: true)
  }

  @objc private func close() {
    dismiss(animated: true)
  }
}
