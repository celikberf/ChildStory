import SwiftUI

struct ListeningPlayerView: View {
    let story: Story

    @State private var index: Int = 0
    @State private var isPlaying: Bool = false
    @State private var currentTime: Double = 0
    @State private var duration: Double = 1

    // Zamanı periyodik güncellemek için
    private let timer = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()

    private var currentPage: StoryPage? {
        guard story.pages.indices.contains(index) else { return nil }
        return story.pages[index]
    }

    var body: some View {
        VStack(spacing: 0) {
            // Başlık / Kapak
            HStack(spacing: 12) {
                Image(story.coverImageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.6), lineWidth: 1))
                    .shadow(radius: 3, y: 2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(story.title)
                        .font(.headline)
                    Text(story.author)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding()
            .background(.ultraThinMaterial)

            // Parça listesi
            List {
                ForEach(Array(story.pages.enumerated()), id: \.offset) { i, page in
                    Button {
                        selectAndPlay(i)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(page.title ?? "Bölüm \(i+1)")
                                    .font(.body)
                                if let name = page.audioFileName {
                                    Text(name).font(.caption2).foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if i == index && isPlaying {
                                Image(systemName: "waveform.circle.fill")
                            } else {
                                Image(systemName: "play.circle")
                            }
                        }
                    }
                    .disabled(page.audioFileName == nil)
                }
            }
            .listStyle(.plain)

            // Mini oynatıcı
            VStack(spacing: 10) {
                // İlerleme
                VStack(spacing: 6) {
                    Slider(value: Binding(
                        get: { duration > 0 ? currentTime : 0 },
                        set: { newVal in seek(to: newVal) }
                    ), in: 0...max(duration, 1))
                    HStack {
                        Text(timeString(currentTime)).font(.caption).monospacedDigit()
                        Spacer()
                        Text(timeString(duration)).font(.caption).monospacedDigit()
                    }
                }

                // Kontroller
                HStack(spacing: 20) {
                    Button {
                        previous()
                    } label: {
                        Image(systemName: "backward.fill").font(.title2)
                    }
                    .disabled(index == 0)

                    Button {
                        toggle()
                    } label: {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 44))
                    }
                    .disabled(currentPage?.audioFileName == nil)

                    Button {
                        next()
                    } label: {
                        Image(systemName: "forward.fill").font(.title2)
                    }
                    .disabled(index >= story.pages.count - 1)

                    Button {
                        stop()
                    } label: {
                        Image(systemName: "stop.fill").font(.title3)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(radius: 3, y: 2)
            .padding()
        }
        .onAppear {
            AudioManager.shared.onFinish = {
                next(autoFromFinish: true)
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
        .navigationTitle("Dinle")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Actions

    private func selectAndPlay(_ i: Int) {
        index = i
        guard let file = currentPage?.audioFileName else { return }
        AudioManager.shared.play(fileName: file)
        isPlaying = true
    }

    private func toggle() {
        guard let file = currentPage?.audioFileName else { return }
        AudioManager.shared.togglePlayPause(fileName: file)
        isPlaying.toggle()
    }

    private func stop() {
        AudioManager.shared.stop()
        isPlaying = false
        currentTime = 0
    }

    private func next(autoFromFinish: Bool = false) {
        guard index < story.pages.count - 1 else {
            // son parça bitti
            isPlaying = false
            return
        }
        index += 1
        if let file = currentPage?.audioFileName {
            AudioManager.shared.play(fileName: file)
            isPlaying = true
        } else if !autoFromFinish {
            isPlaying = false
        }
    }

    private func previous() {
        guard index > 0 else { return }
        index -= 1
        if let file = currentPage?.audioFileName {
            AudioManager.shared.play(fileName: file)
            isPlaying = true
        }
    }

    private func seek(to value: Double) {
        AudioManager.shared.seek(to: value)
        currentTime = value
    }

    private func timeString(_ t: Double) -> String {
        let total = Int(t)
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }
}
