import Foundation

struct AdoptionPost: Identifiable, Decodable {
    let id: UUID
    let userId: UUID
    let title: String
    let description: String
    let petType: PetType
    let breed: String?
    let age: PetAge
    let gender: PetGender
    let size: PetSize?
    let color: String?
    let vaccinations: [String]?
    let isNeutered: Bool
    let hasPassport: Bool
    let hasChip: Bool
    let medicalConditions: [String]?
    let medications: [String]?
    let specialNeeds: String?
    let city: String
    let district: String
    let showPhone: Bool
    let media: [MediaItem]
    let status: PostStatus
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case description
        case petType = "pet_type"
        case breed
        case age
        case gender
        case size
        case color
        case vaccinations
        case isNeutered = "is_neutered"
        case hasPassport = "has_passport"
        case hasChip = "has_chip"
        case medicalConditions = "medical_conditions"
        case medications
        case specialNeeds = "special_needs"
        case city
        case district
        case showPhone = "show_phone"
        case media
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        petType = try container.decode(PetType.self, forKey: .petType)
        breed = try container.decodeIfPresent(String.self, forKey: .breed)
        age = try container.decode(PetAge.self, forKey: .age)
        gender = try container.decode(PetGender.self, forKey: .gender)
        size = try container.decodeIfPresent(PetSize.self, forKey: .size)
        color = try container.decodeIfPresent(String.self, forKey: .color)
        
        // Array'leri PostgreSQL formatından decode et
        if let vaccinationsArray = try? container.decode([String].self, forKey: .vaccinations) {
            // Direkt array gelirse
            vaccinations = vaccinationsArray
        } else if let vaccinationsString = try? container.decode(String.self, forKey: .vaccinations),
                  vaccinationsString != "{}" {
            // String formatında gelirse
            vaccinations = vaccinationsString.dropFirst().dropLast()
                .split(separator: ",")
                .map { String($0).trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "\"", with: "") }
        } else {
            vaccinations = nil
        }
        
        isNeutered = try container.decode(Bool.self, forKey: .isNeutered)
        hasPassport = try container.decode(Bool.self, forKey: .hasPassport)
        hasChip = try container.decode(Bool.self, forKey: .hasChip)
        
        if let conditionsArray = try? container.decode([String].self, forKey: .medicalConditions) {
            medicalConditions = conditionsArray
        } else if let conditionsString = try? container.decode(String.self, forKey: .medicalConditions),
                  conditionsString != "{}" {
            medicalConditions = conditionsString.dropFirst().dropLast()
                .split(separator: ",")
                .map { String($0).trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "\"", with: "") }
        } else {
            medicalConditions = nil
        }
        
        if let medicationsArray = try? container.decode([String].self, forKey: .medications) {
            medications = medicationsArray
        } else if let medicationsString = try? container.decode(String.self, forKey: .medications),
                  medicationsString != "{}" {
            medications = medicationsString.dropFirst().dropLast()
                .split(separator: ",")
                .map { String($0).trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "\"", with: "") }
        } else {
            medications = nil
        }
        
        specialNeeds = try container.decodeIfPresent(String.self, forKey: .specialNeeds)
        city = try container.decode(String.self, forKey: .city)
        district = try container.decode(String.self, forKey: .district)
        showPhone = try container.decode(Bool.self, forKey: .showPhone)
        
        // Media'yı decode et
        if let mediaArray = try? container.decode([MediaItem].self, forKey: .media) {
            // Direkt array olarak gelirse
            media = mediaArray
        } else if let mediaString = try? container.decode(String.self, forKey: .media) {
            // JSON string olarak gelirse
            media = try JSONDecoder().decode([MediaItem].self, from: Data(mediaString.utf8))
        } else {
            // Hiçbiri olmazsa boş array
            media = []
        }
        
        status = try container.decode(PostStatus.self, forKey: .status)
        
        // ISO8601 tarih formatını kullan
        let dateFormatter = ISO8601DateFormatter()
        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        let updatedAtString = try container.decode(String.self, forKey: .updatedAt)
        
        createdAt = dateFormatter.date(from: createdAtString) ?? Date()
        updatedAt = dateFormatter.date(from: updatedAtString) ?? Date()
    }
}

enum PetType: String, Codable, CaseIterable {
    case dog = "dog"
    case cat = "cat"
    case bird = "bird"
    case fish = "fish"
    case other = "other"
    
    var localizedName: String {
        switch self {
        case .dog: return "Köpek"
        case .cat: return "Kedi"
        case .bird: return "Kuş"
        case .fish: return "Balık"
        case .other: return "Diğer"
        }
    }
    
    var icon: String {
        switch self {
        case .dog: return "dog"
        case .cat: return "cat"
        case .bird: return "bird"
        case .fish: return "fish"
        case .other: return "pawprint"
        }
    }
}

enum PetAge: String, Codable, CaseIterable {
    case baby = "baby"
    case young = "young"
    case adult = "adult"
    case senior = "senior"
    
    var localizedName: String {
        switch self {
        case .baby: return "Yavru"
        case .young: return "Genç"
        case .adult: return "Yetişkin"
        case .senior: return "Yaşlı"
        }
    }
}

enum PetGender: String, Codable, CaseIterable {
    case male = "male"
    case female = "female"
    
    var localizedName: String {
        switch self {
        case .male: return "Erkek"
        case .female: return "Dişi"
        }
    }
    
    var icon: String {
        switch self {
        case .male: return "male"
        case .female: return "female"
        }
    }
}

enum PetSize: String, Codable, CaseIterable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    
    var localizedName: String {
        switch self {
        case .small: return "Küçük"
        case .medium: return "Orta"
        case .large: return "Büyük"
        }
    }
}

enum PostStatus: String, Codable {
    case pending = "pending"
    case active = "active"
    case rejected = "rejected"
    case adopted = "adopted"
    
    var localizedName: String {
        switch self {
        case .pending: return "Onay Bekliyor"
        case .active: return "Aktif"
        case .rejected: return "Reddedildi"
        case .adopted: return "Sahiplenildi"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "yellow"
        case .active: return "green"
        case .rejected: return "red"
        case .adopted: return "purple"
        }
    }
}

struct MediaItem: Codable, Identifiable {
    let id: String
    let url: String
    let type: MediaType
    let thumbnailUrl: String?
    
    enum MediaType: String, Codable {
        case image
        case video
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case url
        case type
        case thumbnailUrl = "thumbnail_url"
    }
} 