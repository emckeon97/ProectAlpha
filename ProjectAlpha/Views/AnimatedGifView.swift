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
        <html><body style="margin:0;background:#000">
        <img src="\(url.absoluteString)" style="width:100vw;height:100vh;object-fit:cover;display:block">
        </body></html>
        """
        uiView.loadHTMLString(html, baseURL: nil)
    }
}
