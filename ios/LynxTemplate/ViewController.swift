import UIKit
import Lynx

final class ViewController: UIViewController {
  // Physical device dev: change "localhost" to the IP printed by `pnpm dev:ip`.
  private static let devHost = "localhost"
  private static let devPort = 3000

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white

    #if DEBUG
    let url = "http://\(Self.devHost):\(Self.devPort)/main.lynx.bundle"
    #else
    let url = "embedded://main.lynx.bundle"
    #endif

    let lynxView = LynxView { builder in
      builder.templateResourceFetcher = TemplateProvider()
      builder.frame = self.view.bounds
    }
    lynxView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.addSubview(lynxView)
    lynxView.loadTemplate(fromURL: url, initData: nil)
  }
}
