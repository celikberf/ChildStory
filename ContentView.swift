import SwiftUI

struct ContentView: View {
    @State private var stories: [Story] = []

    private let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                // Arka plan
                LinearGradient(
                    colors: [Color.purple.opacity(0.7), Color.pink.opacity(0.7), Color.orange.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack {
                    Text("📚 Çocuk Hikâyeleri")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.25), radius: 4, x: 2, y: 2)
                        .padding(.top, 30)

                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(stories) { story in
                                NavigationLink(value: story) {
                                    StoryCard(story: story)
                                }
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationDestination(for: Story.self) { story in
                AudioPlayerView(story: story)
            }

        }
        .task { await loadStories() }
    }

    private func loadStories() async {
        guard let url = Bundle.main.url(forResource: "stories", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let payload = try? JSONDecoder().decode(StoriesPayload.self, from: data) else {
            print("stories.json yüklenemedi veya çözümlenemedi")
            return
        }
        stories = payload.stories
    }
}

struct StoryCard: View {
    let story: Story
    var body: some View {
        VStack(spacing: 10) {
            Image(story.coverImageName)
                .resizable()
                .scaledToFill()
                .frame(width: 130, height: 130)
                .clipShape(Circle()) // oval/yuvarlak kapak
                .overlay(Circle().stroke(Color.white, lineWidth: 3))
                .shadow(radius: 6)

            Text(story.title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding()
        .background(Color.white.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.25), radius: 5, x: 2, y: 2)
    }
}
