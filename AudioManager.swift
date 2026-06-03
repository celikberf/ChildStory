import AVFoundation

final class AudioManager: NSObject, AVAudioPlayerDelegate {
    static let shared = AudioManager()
    private var player: AVAudioPlayer?
    var onFinish: (() -> Void)?   // Parça bitince çağrılır

    private override init() { super.init() }

    private func prepareSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
        } catch {
            print("Audio session error:", error)
        }
    }

    func play(fileName: String) {
        prepareSession()
        guard let url = Bundle.main.url(forResource: fileName, withExtension: nil) else {
            print("Audio not found:", fileName)
            return
        }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.prepareToPlay()
            player?.play()
        } catch {
            print("Audio error:", error)
        }
    }

    func togglePlayPause(fileName: String) {
        if let p = player, let currentURL = p.url,
           currentURL.lastPathComponent == fileName {
            if p.isPlaying { p.pause() } else { p.play() }
        } else {
            play(fileName: fileName)
        }
    }

    func stop() {
        player?.stop()
        player = nil
    }

    func pause() { player?.pause() }

    func seek(to time: TimeInterval) {
        guard let p = player else { return }
        let clamped = min(max(0, time), p.duration)
        p.currentTime = clamped
    }

    func setVolume(_ value: Float) {
        player?.volume = min(max(0, value), 1)
    }

    var isPlaying: Bool { player?.isPlaying ?? false }
    var currentTime: TimeInterval { player?.currentTime ?? 0 }
    var duration: TimeInterval { player?.duration ?? 0 }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish?()
    }
}
