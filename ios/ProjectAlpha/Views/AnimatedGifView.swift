import SwiftUI
import WebKit

/// Renders an animated GIF with zero third-party dependencies.
struct AnimatedGifView: UIViewRepresentable {
    let url: URL?

    func makeUIView(context: Context) -> WKWebView {
        let view = WKWebView()
        view.scrollView.isScrollEnabled = false
        view.isOpaque = false
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let url else { return }
        let html = """
        <html><body style="margin:0;background:transparent;display:flex;align-items:center;justify-content:center;height:100vh">
        <img src="\(url.absoluteString)" style="max-width:100%;max-height:100vh;object-fit:contain">
        </body></html>
        """
        uiView.loadHTMLString(html, baseURL: nil)
    }
}
