import Foundation
import CoreLocation

struct VeterinaryProfile: Codable, Identifiable {
    let id: String
    let basicInfo: BasicInfo
    let professionalInfo: ProfessionalInfo
    let workingHours: WorkingHours
    let services: [Service]
    let gallery: [Media]
    let statistics: Statistics
    let reviews: [Review]?
    let location: Location
    let isOpen: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case basicInfo = "basic_info"
        case professionalInfo = "professional_info"
        case workingHours = "working_hours"
        case services
        case gallery
        case statistics
        case reviews
        case location
        case isOpen = "is_open"
        case createdAt = "created_at"
    }
}

struct BasicInfo: Codable {
    let phone: String
    let website: String
    let clinicName: String
    let profileImage: String
    let coverImage: String
    let email: String
    let socialMedia: SocialMedia
    let name: String
}

struct SocialMedia: Codable {
    let twitter: String
    let facebook: String
    let instagram: String
}

struct ProfessionalInfo: Codable {
    let licenseNumber: String
    let certificates: [Certificate]
    let education: [Education]
    let experience: Int
    let about: String
    let specialties: [Specialty]
    let languages: [Language]
}

struct Certificate: Codable {
    let name: String
    let year: Int
    let issuer: String
}

struct Education: Codable {
    let school: String
    let year: Int
    let field: String
    let degree: String
}

struct Specialty: Codable {
    let name: String
    let description: String
}

struct Language: Codable {
    let name: String
    let level: String
}

struct WorkingHours: Codable {
    let weekend: [WorkDay]
    let weekdays: [WorkDay]
}

struct WorkDay: Codable {
    let isClosed: Bool
    let day: Int
    let open: String
    let close: String
}

struct Service: Codable {
    let duration: Int
    let id: String
    let description: String
    let name: String
    let price: Double
    let category: String
    
    var uuid: UUID? {
        UUID(uuidString: id)
    }
}

struct Media: Codable {
    let id: String
    let url: String
    let type: String
    let description: String
}

struct Statistics: Codable {
    let completionRate: Double
    let appointmentCount: Int
    let reviewCount: Int
    let rating: Double
}

struct Location: Codable {
    let address: String
    let city: String
    let district: String
    let longitude: Double
    let latitude: Double
    let parkingInfo: String
    let publicTransport: String
}

struct Review: Codable, Identifiable {
    let id: String
    let userId: String
    let userName: String
    let userImage: String?
    let rating: Int
    let comment: String
    let date: Date
    let response: Response?
    
    struct Response: Codable {
        let text: String
        let date: Date
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case userName = "user_name"
        case userImage = "user_image"
        case rating
        case comment
        case date
        case response
    }
}

extension VeterinaryProfile {
    var isCurrentlyOpen: Bool {
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        // Swift'te weekday 1=Pazar, 7=Cumartesi şeklinde
        // Bizim modelimizde 1=Pazartesi, 7=Pazar şeklinde
        let adjustedWeekday = weekday == 1 ? 7 : weekday - 1
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let currentTime = formatter.string(from: now)
        
        let dayHours: WorkDay?
        if adjustedWeekday <= 5 {
            dayHours = self.workingHours.weekdays.first { $0.day == adjustedWeekday }
        } else {
            dayHours = self.workingHours.weekend.first { $0.day == adjustedWeekday }
        }
        
        guard let hours = dayHours else {
            return false
        }
        
        if hours.isClosed {
            return false
        }
        
        return currentTime >= hours.open && currentTime <= hours.close
    }
} 