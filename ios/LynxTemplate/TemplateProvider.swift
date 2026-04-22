import Foundation
import Lynx

final class TemplateProvider: NSObject, LynxTemplateResourceFetcher {
  func fetchTemplate(
    _ request: LynxResourceRequest,
    onComplete callback: @escaping LynxTemplateResourceCompletionBlock
  ) {
    let url = request.url
    if let remote = URL(string: url), let scheme = remote.scheme, scheme.hasPrefix("http") {
      URLSession.shared.dataTask(with: remote) { data, _, err in
        if let data = data {
          callback(LynxTemplateResource(nsData: data), nil)
        } else {
          callback(nil, err ?? NSError(domain: "TemplateProvider", code: -1))
        }
      }.resume()
      return
    }

    let requestedName = URL(string: url)?.lastPathComponent ?? "main.lynx.bundle"
    let base = (requestedName as NSString).deletingPathExtension
    let ext  = (requestedName as NSString).pathExtension.isEmpty ? "bundle" : (requestedName as NSString).pathExtension
    if let local = Bundle.main.url(forResource: base, withExtension: ext),
       let data = try? Data(contentsOf: local) {
      callback(LynxTemplateResource(nsData: data), nil)
    } else {
      callback(nil, NSError(domain: "TemplateProvider", code: -2,
                            userInfo: [NSLocalizedDescriptionKey: "bundle not found: \(requestedName)"]))
    }
  }

  func fetchSSRData(
    _ request: LynxResourceRequest,
    onComplete callback: @escaping LynxSSRResourceCompletionBlock
  ) {
    callback(nil, NSError(domain: "TemplateProvider", code: -3,
                          userInfo: [NSLocalizedDescriptionKey: "SSR not supported"]))
  }
}
