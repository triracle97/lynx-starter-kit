import UIKit
import Lynx

final class ViewController: UIViewController, LynxViewLifecycle {
  // Physical device dev: change "localhost" to the IP printed by `pnpm dev:ip`.
  private static let devHost = "localhost"
  private static let devPort = 3000

  private var lynxView: LynxView!
  private var bundleURL: String = ""

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white

    #if DEBUG
    bundleURL = "http://\(Self.devHost):\(Self.devPort)/main.lynx.bundle"
    #else
    bundleURL = "embedded://main.lynx.bundle"
    #endif

    lynxView = LynxView { builder in
      builder.enableGenericResourceFetcher = LynxBooleanOption.`true`
      builder.templateResourceFetcher = TemplateProvider()
      builder.frame = self.view.bounds
    }
    lynxView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    lynxView.addLifecycleClient(self)
    view.addSubview(lynxView)
    loadBundle()

    #if DEBUG
    installReloadButton()
    #endif
  }

  private func loadBundle() {
    NSLog("[Lynx] loadTemplate url=\(bundleURL)")
    lynxView.loadTemplate(fromURL: bundleURL, initData: nil)
  }

  // MARK: - Reload (DEBUG only)

  #if DEBUG
  private func installReloadButton() {
    let btn = UIButton(type: .system)
    btn.setTitle("↻", for: .normal)
    btn.titleLabel?.font = .systemFont(ofSize: 22, weight: .semibold)
    btn.backgroundColor = UIColor.black.withAlphaComponent(0.55)
    btn.setTitleColor(.white, for: .normal)
    btn.layer.cornerRadius = 22
    btn.translatesAutoresizingMaskIntoConstraints = false
    btn.addTarget(self, action: #selector(handleReloadTap), for: .touchUpInside)
    view.addSubview(btn)
    NSLayoutConstraint.activate([
      btn.widthAnchor.constraint(equalToConstant: 44),
      btn.heightAnchor.constraint(equalToConstant: 44),
      btn.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
      btn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
    ])
  }

  @objc private func handleReloadTap() {
    reloadApp()
  }

  override var canBecomeFirstResponder: Bool { true }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    becomeFirstResponder()
  }

  // Shake to reload (device + simulator "Device → Shake")
  override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
    if motion == .motionShake { reloadApp() }
  }

  // Cmd+R to reload (simulator keyboard)
  override var keyCommands: [UIKeyCommand]? {
    [UIKeyCommand(input: "r", modifierFlags: .command, action: #selector(handleReloadTap))]
  }

  private func reloadApp() {
    NSLog("[Lynx] reload requested")
    lynxView.removeFromSuperview()
    lynxView = LynxView { builder in
      builder.enableGenericResourceFetcher = LynxBooleanOption.`true`
      builder.templateResourceFetcher = TemplateProvider()
      builder.frame = self.view.bounds
    }
    lynxView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    lynxView.addLifecycleClient(self)
    view.insertSubview(lynxView, at: 0)
    loadBundle()
  }
  #endif

  // MARK: - LynxViewLifecycle

  func lynxView(_ view: LynxView!, didRecieveError error: Error!) {
    NSLog("[Lynx] didRecieveError: \(String(describing: error))")
  }

  func lynxViewDidStartLoading(_ view: LynxView!) {
    NSLog("[Lynx] start loading")
  }

  func lynxViewDidFirstScreen(_ view: LynxView!) {
    NSLog("[Lynx] first screen")
  }

  func lynxViewDidPageUpdate(_ view: LynxView!) {
    NSLog("[Lynx] page update")
  }

  func lynxView(_ view: LynxView!, didLoadFinishedWithUrl url: String!) {
    NSLog("[Lynx] load finished url=\(url ?? "nil")")
  }
}
