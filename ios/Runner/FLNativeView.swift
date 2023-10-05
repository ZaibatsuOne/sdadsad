import Flutter
import UIKit
import WebKit

class FLNativeViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        if #available(iOS 13.0.0, *) {
            return FLNativeView(
                frame: frame,
                viewIdentifier: viewId,
                arguments: args,
                binaryMessenger: messenger)
        } else {
            let mes = "123"
            return mes as! FlutterPlatformView
        }
    }

    /// Implementing this method is only necessary when the `arguments` in `createWithFrame` is not `nil`.
    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
          return FlutterStandardMessageCodec.sharedInstance()
    }
}

@available(iOS 13.0.0, *)
class FLNativeView: NSObject, FlutterPlatformView, WKNavigationDelegate {
    private var _view: UIView
    private var webView: WKWebView
    let validator = CertificateValidator()

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        let fullHeight = UIScreen.main.bounds.height
        let fullWidth = UIScreen.main.bounds.width
        _view = UIView()
        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: fullWidth, height: fullHeight))
        super.init()

        // iOS views can be created here
        createNativeView(view: _view)
    }

    func view() -> UIView {
        return _view
    }

    func createNativeView(view _view: UIView){
        
        webView.navigationDelegate = self

        Task {
            let names = ["Russian Trusted Root CA",
                                    "Russian Trusted Sub CA"]
                   await validator.prepareCertificates(names)}
        let url = URL(string: "https://securepayments.sberbank.ru/")!
                webView.load(URLRequest(url: url))
        
        _view.addSubview(webView)
    }
    
    func webView(
            _ webView: WKWebView,
            didReceive challenge: URLAuthenticationChallenge,
            completionHandler: @escaping (URLSession.AuthChallengeDisposition,
                                          URLCredential?) -> Void
        ) {
            guard let serverTrust = challenge.protectionSpace.serverTrust
            else { return completionHandler(.performDefaultHandling, nil) }
            
            if #available(iOS 13.0, *) {
                Task.detached(priority: .userInitiated) {
                    if await self.validator.checkValidity(of: serverTrust) {
                        // Allow our sertificate
                        let cred = URLCredential(trust: serverTrust)
                        completionHandler(.useCredential, cred)
                    } else {
                        // Default check for another connections
                        completionHandler(.performDefaultHandling, nil)
                    }
                }
            } else {
                // Fallback on earlier versions
            }
        }
}
