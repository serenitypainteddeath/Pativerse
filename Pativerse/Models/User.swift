import Foundation

struct User: Codable, Identifiable {
    let id: UUID
    let phone: String
    let email: String?
    let fullName: String
    let avatarUrl: String?
    let isPhoneVerified: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case phone
        case email
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
        case isPhoneVerified = "is_phone_verified"
        case createdAt = "created_at"
    }
} 