import SwiftUI

struct StoryDetailView: View {
    let story: Story
    @State private var showPlayer = false

    var body: some View {
        VStack(spacing: 16) {
            Image(story.coverImageName)
                .resizable()
                .scaledToFit()
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

            Text(story.title)
                .font(.title).bold()
            Text("Yazar: \(story.author)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(story.summary)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Dinlemeye Başla") { showPlayer = true }
                .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPlayer) {
            ListeningPlayerView(story: story)
        }
    }
}
