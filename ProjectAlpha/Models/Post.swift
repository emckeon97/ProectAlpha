import Foundation

struct Post: Identifiable, Codable {
    let id: String
    let imageFileName: String
    let caption: String
    let createdAt: Date
    var likeCount: Int
}
