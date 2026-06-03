import Foundation

struct Story: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let author: String
    let coverImageName: String
    let locale: String
    let summary: String
    let pages: [StoryPage]
}

struct StoriesPayload: Codable {
    let stories: [Story]
}

// Dinleme odaklı: metin kullanmasak da opsiyonel dursun; parça adı için "title" ekledik
struct StoryPage: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    let title: String?          // Parça adı (ör. "Bölüm 1")
    let text: String?           // Kullanmayacağız (opsiyonel)
    let audioFileName: String?  // ZORUNLU: m4a/mp3
    private enum CodingKeys: String, CodingKey { case title, text, audioFileName }
}
