import UIKit
import WebKit
import UniformTypeIdentifiers

private final class PomoBundleSchemeHandler: NSObject, WKURLSchemeHandler {
    private let publicRoot: URL

    override init() {
        guard let root = Bundle.main.resourceURL?.appendingPathComponent("public", isDirectory: true) else {
            fatalError("Missing app resource directory")
        }
        publicRoot = root.standardizedFileURL
        super.init()
    }

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let requestURL = urlSchemeTask.request.url,
              requestURL.scheme == "capacitor",
              requestURL.host == "localhost" else {
            fail(urlSchemeTask, code: 404)
            return
        }

        var relative = requestURL.path
        if relative.isEmpty || relative == "/" { relative = "/index.html" }
        while relative.hasPrefix("/") { relative.removeFirst() }

        let fileURL = publicRoot.appendingPathComponent(relative).standardizedFileURL
        guard fileURL.path.hasPrefix(publicRoot.path + "/"),
              FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL) else {
            fail(urlSchemeTask, code: 404)
            return
        }

        let ext = fileURL.pathExtension.lowercased()
        let mime: String
        switch ext {
        case "html": mime = "text/html"
        case "js", "mjs": mime = "text/javascript"
        case "css": mime = "text/css"
        case "json": mime = "application/json"
        case "svg": mime = "image/svg+xml"
        case "png": mime = "image/png"
        case "jpg", "jpeg": mime = "image/jpeg"
        case "webp": mime = "image/webp"
        case "wav": mime = "audio/wav"
        case "mp3": mime = "audio/mpeg"
        default:
            if let type = UTType(filenameExtension: ext), let preferred = type.preferredMIMEType {
                mime = preferred
            } else {
                mime = "application/octet-stream"
            }
        }

        let response = URLResponse(
            url: requestURL,
            mimeType: mime,
            expectedContentLength: data.count,
            textEncodingName: mime.hasPrefix("text/") || mime == "application/json" ? "utf-8" : nil
        )
        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(data)
        urlSchemeTask.didFinish()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}

    private func fail(_ task: WKURLSchemeTask, code: Int) {
        task.didFailWithError(NSError(domain: NSURLErrorDomain, code: code == 404 ? NSURLErrorFileDoesNotExist : NSURLErrorUnknown))
    }
}

final class PomoViewController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate {
    private var webView: WKWebView!
    private let schemeHandler = PomoBundleSchemeHandler()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.93, green: 0.88, blue: 0.95, alpha: 1)

        let controller = WKUserContentController()
        controller.add(self, name: "grove")

        let raw = PomoNativeCoordinator.shared.savedState()
        let encoded: String
        if let raw,
           let data = try? JSONEncoder().encode(raw),
           let literal = String(data: data, encoding: .utf8) {
            encoded = literal
        } else {
            encoded = "null"
        }

        controller.addUserScript(WKUserScript(
            source: "window.__POMOLAND_NATIVE_SAVE__ = \(encoded);",
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        ))

        let config = WKWebViewConfiguration()
        config.userContentController = controller
        config.websiteDataStore = .default()
        config.preferences.javaScriptCanOpenWindowsAutomatically = false
        config.setURLSchemeHandler(schemeHandler, forURLScheme: "capacitor")

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        NotificationCenter.default.addObserver(self, selector: #selector(appBecameActive), name: .pomoLandDidBecomeActive, object: nil)
        webView.load(URLRequest(url: URL(string: "capacitor://localhost/")!))
    }

    deinit {
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: "grove")
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func appBecameActive() {
        webView?.evaluateJavaScript("window.dispatchEvent(new Event('grove-resume'));")
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "grove",
              let payload = message.body as? [String: Any],
              let action = payload["action"] as? String else { return }

        switch action {
        case "save":
            if let rawState = payload["state"] {
                if let state = normalizedDictionary(rawState) {
                    PomoNativeCoordinator.shared.persistAndSync(state: state)
                }
            }
        case "prepare":
            PomoNativeCoordinator.shared.prepareNotifications()
        case "liveDebug":
            sendLiveDiagnostic(PomoLiveActivityManager.shared.diagnostics())
        case "liveTest":
            Task { [weak self] in
                let result = await PomoLiveActivityManager.shared.startDiagnosticActivity()
                await MainActor.run { self?.sendLiveDiagnostic(result) }
            }
        case "liveEnd":
            Task { [weak self] in
                let result = await PomoLiveActivityManager.shared.endDiagnosticActivities()
                await MainActor.run { self?.sendLiveDiagnostic(result) }
            }
        default:
            break
        }
    }

    // WKScriptMessage values can arrive as nested Foundation collection types.
    // Round-tripping through JSON guarantees state.active is a native Swift dictionary,
    // so a real Pomodoro reaches PomoLiveActivityManager just like the diagnostic test.
    private func normalizedDictionary(_ value: Any) -> [String: Any]? {
        guard JSONSerialization.isValidJSONObject(value),
              let data = try? JSONSerialization.data(withJSONObject: value),
              let object = try? JSONSerialization.jsonObject(with: data),
              let dictionary = object as? [String: Any] else { return nil }
        return dictionary
    }

    private func sendLiveDiagnostic(_ payload: [String: Any]) {
        guard JSONSerialization.isValidJSONObject(payload),
              let data = try? JSONSerialization.data(withJSONObject: payload),
              let json = String(data: data, encoding: .utf8) else { return }
        webView?.evaluateJavaScript("window.__POMOLAND_LIVE_DIAGNOSTIC__ && window.__POMOLAND_LIVE_DIAGNOSTIC__(\(json));")
    }
}
