import Foundation

struct GiphyResponse: Decodable {
    let data: [Gif]
}

struct Gif: Decodable, Identifiable {
    let id: String
    let title: String
    let images: GifImages

    var previewURL: URL? { URL(string: images.fixedWidth.url) }
    var fullURL: URL? { URL(string: images.original.url) }
}

struct GifImages: Decodable {
    let original: GifImage
    let fixedWidth: GifImage

    enum CodingKeys: String, CodingKey {
        case original
        case fixedWidth = "fixed_width"
    }
}

struct GifImage: Decodable {
    let url: String
    let width: String
    let height: String
}
