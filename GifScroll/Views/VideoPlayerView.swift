import AVKit
import SwiftUI

struct VideoPlayerView: View {
    let url: URL
    @State private var player: AVPlayer

    init(url: URL) {
        self.url = url
        _player = State(initialValue: AVPlayer(url: url))
    }

    var body: some View {
        VideoPlayer(player: player)
            .ignoresSafeArea()
            .onAppear {
                // TikTok-style: video audio plays automatically,
                // even with the silent switch on.
                try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try? AVAudioSession.sharedInstance().setActive(true)
                player.isMuted = false
                player.play()
            }
            .onDisappear {
                player.pause()
            }
    }
}
