import SwiftUI

struct StoryPlayerView: View {
    let story: Story

    @State private var index: Int = 0            // kaçıncı sesli sayfa
    @State private var isPlaying: Bool = false
    @State private var currentTime: Double = 0
    @State private var duration: Double = 1
    @State private var volume: Double = 1.0

    // Zaman takibi
    private let timer = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()

    private var currentFile: String? {
        guard story.pages.indices.contains(index) else { return nil }
        return story.pages[index].audioFileName
    }

    var body: some View {
        VStack(spacing: 20) {
            // Kapak ve başlık
            VStack(spacing: 8) {
                Image(story.coverImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

                Text(story.title)
                    .font(.title).bold()

                Text("Yazar: \(story.author)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top)

            // Sadece Dinle butonu (ilk etkileşim)
            Button(isPlaying ? "Duraklat" : "Dinle") {
                if isPlaying {
                    AudioManager.shared.pause()
                    isPlaying = false
                } else {
                    startOrResume()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(currentFile == nil)

            // İlerleme çubuğu + süreler
            VStack(spacing: 6) {
                Slider(value: Binding(
                    get: { duration > 0 ? currentTime : 0 },
                    set: { newVal in
                        AudioManager.shared.seek(to: newVal)
                        currentTime = newVal
                    }
                ), in: 0...max(duration, 1))

                HStack {
                    Text(timeString(currentTime)).font(.caption).monospacedDigit()
                    Spacer()
                    Text(timeString(duration)).font(.caption).monospacedDigit()
                }
            }
            .padding(.horizontal)

            // Kontroller: geri/ileri sar + durdur
            HStack(spacing: 24) {
                Button {
                    // 15 sn geri
                    let t = max(currentTime - 15, 0)
                    AudioManager.shared.seek(to: t)
                    currentTime = t
                } label: {
                    Label("Geri", systemImage: "gobackward.15")
                }

                Button {
                    if isPlaying {
                        AudioManager.shared.pause()
                        isPlaying = false
                    } else {
                        startOrResume()
                    }
                } label: {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 44))
                }
                .disabled(currentFile == nil)

                Button {
                    // 15 sn ileri
                    let t = min(currentTime + 15, duration)
                    AudioManager.shared.seek(to: t)
                    currentTime = t
                } label: {
                    Label("İleri", systemImage: "goforward.15")
                }

                Button {
                    AudioManager.shared.stop()
                    isPlaying = false
                    currentTime = 0
                } label: {
                    Label("Durdur", systemImage: "stop.fill")
                }
            }

            // Ses (volume)
            VStack(spacing: 6) {
                HStack {
                    Image(systemName: "speaker.fill")
                    Slider(value: Binding(
                        get: { volume },
                        set: { v in
                            volume = v
                            AudioManager.shared.setVolume(Float(v))
                        }
                    ), in: 0...1)
                    Image(systemName: "speaker.wave.3.fill")
                }
                Text("Ses").font(.caption).foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
        .navigationTitle("Dinle")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Parça bitince sıradaki sesli sayfaya otomatik geç
            AudioManager.shared.onFinish = {
                advanceToNextAudioOrStop()
            }
        }
        .onDisappear {
            AudioManager.shared.stop()
            isPlaying = false
        }
        .onReceive(timer) { _ in
            currentTime = AudioManager.shared.currentTime
            duration = max(AudioManager.shared.duration, 1)
        }
        .onChange(of: index) { _ in
            // sayfa değişince yeniden başlat
            if isPlaying { startOrResume(forceRestart: true) }
        }
    }

    // MARK: - Helpers

    private func firstAudioIndex() -> Int? {
        story.pages.firstIndex { $0.audioFileName != nil }
    }

    private func startOrResume(forceRestart: Bool = false) {
        if forceRestart == false, AudioManager.shared.isPlaying == false, currentTime > 0, let file = currentFile {
            // mevcut dosyadan devam
            AudioManager.shared.togglePlayPause(fileName: file)
            isPlaying = true
            return
        }
        // ilk sesli sayfadan veya mevcut index'ten başlat
        if currentFile == nil, let start = firstAudioIndex() {
            index = start
        }
        guard let file = currentFile else { return }
        AudioManager.shared.play(fileName: file)
        AudioManager.shared.setVolume(Float(volume))
        isPlaying = true
    }

    private func advanceToNextAudioOrStop() {
        var next = index + 1
        while next < story.pages.count, story.pages[next].audioFileName == nil {
            next += 1
        }
        if next < story.pages.count {
            index = next
            startOrResume(forceRestart: true)
        } else {
            AudioManager.shared.stop()
            isPlaying = false
            currentTime = 0
        }
    }

    private func timeString(_ t: Double) -> String {
        let total = Int(t)
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }
}
