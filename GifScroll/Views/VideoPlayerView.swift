import SwiftUI
import AVKit

/// Full-screen looping video page. Tap toggles mute.
struct VideoPlayerView: View {
    let url: URL
    @StateObject private var model = VideoPlayerModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let player = model.player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: model.muted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .foregroundColor(.white.opacity(0.85))
                        .padding(10)
                        .background(Color.black.opacity(0.55))
                        .clipShape(Circle())
                        .padding(.trailing, 16)
                        .padding(.bottom, 170)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { model.toggleMute() }
        .onAppear { model.play(url: url) }
        .onDisappear { model.pause() }
    }
}

@MainActor
final class VideoPlayerModel: ObservableObject {
    @Published var player: AVPlayer?
    @Published var muted = false
    private var endObserver: NSObjectProtocol?

    func play(url: URL) {
        if player == nil {
            let p = AVPlayer(url: url)
            p.isMuted = muted
            player = p
            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: p.currentItem,
                queue: .main
            ) { [weak p] _ in
                p?.seek(to: .zero)
                p?.play()
            }
        }
        player?.play()
    }

    func pause() {
        player?.pause()
    }

    func toggleMute() {
        muted.toggle()
        player?.isMuted = muted
    }

    deinit {
        if let observer = endObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
