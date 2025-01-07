import Foundation
import Supabase
import SwiftUI
import PhotosUI

@MainActor
class AdoptionViewModel: ObservableObject {
    @Published var posts: [AdoptionPost] = []
    @Published var isLoading = false
    @Published var error: String?
    
    // Filtreler
    @Published var selectedPetType: PetType?
    @Published var selectedCity: String?
    @Published var selectedDistrict: String?
    @Published var searchText = ""
    
    // İlan oluşturma
    @Published var title = ""
    @Published var description = ""
    @Published var petType: PetType = .dog
    @Published var breed = ""
    @Published var age: PetAge = .young
    @Published var gender: PetGender = .male
    @Published var size: PetSize = .medium
    @Published var color = ""
    @Published var vaccinations: [String] = []
    @Published var isNeutered = false
    @Published var hasPassport = false
    @Published var hasChip = false
    @Published var medicalConditions: [String] = []
    @Published var medications: [String] = []
    @Published var specialNeeds = ""
    @Published var city = ""
    @Published var district = ""
    @Published var showPhone = false
    @Published var selectedPhotos: [PhotosPickerItem] = []
    @Published var selectedVideo: PhotosPickerItem?
    @Published var currentVaccination: String = ""
    @Published var currentMedicalCondition: String = ""
    @Published var currentMedication: String = ""
    @Published var formErrors: [String] = []
    @Published var showSuccessAlert = false
    @Published var successMessage = ""
    
    private let supabase = SupabaseClient(
        supabaseURL: URL(string: "https://jtyierzqnnlthzfcdbcf.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp0eWllcnpxbm5sdGh6ZmNkYmNmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzYwMzQ0MzAsImV4cCI6MjA1MTYxMDQzMH0.nJLFpVRxrRW_PXOU7vKt2G4ceOlUDDNUvo-fA4fVLyA"
    )
    
    var filteredPosts: [AdoptionPost] {
        posts.filter { post in
            var matches = true
            
            if let petType = selectedPetType {
                matches = matches && post.petType == petType
            }
            
            if let city = selectedCity {
                matches = matches && post.city == city
            }
            
            if let district = selectedDistrict {
                matches = matches && post.district == district
            }
            
            if !searchText.isEmpty {
                matches = matches && (
                    post.title.localizedCaseInsensitiveContains(searchText) ||
                    post.description.localizedCaseInsensitiveContains(searchText) ||
                    post.breed?.localizedCaseInsensitiveContains(searchText) ?? false
                )
            }
            
            return matches
        }
    }
    
    var cities: [String] {
        Array(Set(posts.map { $0.city })).sorted()
    }
    
    var districts: [String] {
        if let selectedCity = selectedCity {
            return Array(Set(posts.filter { $0.city == selectedCity }.map { $0.district })).sorted()
        }
        return []
    }
    
    func fetchPosts() async {
        isLoading = true
        error = nil
        
        do {
            let query = supabase.database
                .from("adoption_posts")
                .select()
                .order(column: "created_at", ascending: false)
            
            let response: [AdoptionPost] = try await query.execute().value
            posts = response
        } catch {
            self.error = "İlanlar yüklenirken bir hata oluştu: \(error.localizedDescription)"
            print("❌ Hata: \(error)")
        }
        
        isLoading = false
    }
    
    func createPost() async throws -> Bool {
        guard validateForm() else {
            throw ValidationError.missingRequiredFields
        }
        
        print("📝 İlan oluşturma başladı")
        
        var mediaItems: [MediaItem] = []
        
        // Fotoğrafları yükle
        print("📸 \(selectedPhotos.count) adet fotoğraf yüklenecek")
        for (index, photo) in selectedPhotos.enumerated() {
            do {
                let mediaItem = try await uploadMedia(item: photo, type: .image)
                mediaItems.append(mediaItem)
                print("✅ Fotoğraf \(index + 1) yüklendi: \(mediaItem.url)")
            } catch {
                print("❌ Fotoğraf \(index + 1) yüklenirken hata: \(error.localizedDescription)")
            }
        }
        
        // Videoyu yükle
        if let video = selectedVideo {
            print("🎥 Video yükleniyor")
            do {
                let mediaItem = try await uploadMedia(item: video, type: .video)
                mediaItems.append(mediaItem)
                print("✅ Video yüklendi: \(mediaItem.url)")
            } catch {
                print("❌ Video yüklenirken hata: \(error.localizedDescription)")
            }
        }
        
        // Şu anki timestamp'i al
        let currentDate = ISO8601DateFormatter().string(from: Date())
        
        print("📊 İlan verisi hazırlanıyor")
        let postInput = AdoptionPostInput(
            userId: try await supabase.auth.session.user.id,
            title: title,
            description: description,
            petType: petType.rawValue,
            breed: breed,
            age: age.rawValue,
            gender: gender.rawValue,
            size: size.rawValue,
            color: color,
            vaccinations: vaccinations,
            isNeutered: isNeutered,
            hasPassport: hasPassport,
            hasChip: hasChip,
            medicalConditions: medicalConditions,
            medications: medications,
            specialNeeds: specialNeeds,
            city: city,
            district: district,
            showPhone: showPhone,
            media: mediaItems,
            status: PostStatus.pending.rawValue,
            created_at: currentDate,
            updated_at: currentDate
        )
        
        print("💾 İlan veritabanına kaydediliyor")
        
        // MediaItem'ları dictionary array'e dönüştür
        let mediaArray = mediaItems.map { item -> [String: String] in
            return [
                "id": item.id,
                "url": item.url,
                "type": item.type.rawValue,
                "thumbnail_url": item.thumbnailUrl ?? ""
            ]
        }
        
        // Media array'ini JSON string'e çevir
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        let mediaData = try encoder.encode(mediaArray)
        guard let mediaJsonString = String(data: mediaData, encoding: .utf8) else {
            throw UploadError.invalidData
        }
        
        print("📦 Media JSON: \(mediaJsonString)")  // Debug için ekledim
        
        // İlan verilerini hazırla
        var insertValues = postInput.toDictionary()
        insertValues["media"] = mediaJsonString
        
        print("POST EDİLEN VERİ:", insertValues)
        
        let query = supabase.database
            .from("adoption_posts")
            .insert(values: insertValues)

        
        do {
            print("🔄 Supabase sorgusu çalıştırılıyor...")
            print("📝 Query detayları: \(query)")
            
            // Sadece execute edip başarılı olup olmadığını kontrol et
            _ = try await query.execute()
            print("✅ İlan başarıyla oluşturuldu")
            
            // Başarılı durumda
            successMessage = "İlanınız başarıyla oluşturuldu! İncelendikten sonra yayınlanacaktır."
            showSuccessAlert = true
            return true
            
        } catch let createError {
            print("❌ Genel hata:")
            print("Error: \(createError)")
            throw createError
        }
    }
    
    private func uploadMedia(item: PhotosPickerItem, type: MediaItem.MediaType) async throws -> MediaItem {
        let id = UUID().uuidString
        let fileExtension = type == .image ? "jpg" : "mp4"
        let path = "\(id).\(fileExtension)"
        
        print("📤 Medya yükleniyor: \(type == .image ? "Fotoğraf" : "Video")")
        print("🔑 Dosya yolu: \(path)")
        
        if type == .image {
            print("🔄 Fotoğraf verisi yükleniyor")
            guard let imageData = try await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: imageData),
                  let compressedData = uiImage.jpegData(compressionQuality: 0.7) else {
                print("❌ Fotoğraf verisi alınamadı")
                throw UploadError.invalidData
            }
            print("✅ Fotoğraf verisi alındı: \(compressedData.count) bytes")
            
            let fileOptions = FileOptions(
                cacheControl: "3600"
            )
            
            let file = File(
                name: path,
                data: compressedData, fileName: path,
                contentType: "image/jpeg"
            )
            
            print("⬆️ Storage'a yükleniyor")
            try await supabase.storage
                .from(id: "adoption_media")
                .upload(
                    path: path,
                    file: file,
                    fileOptions: fileOptions
                )
            print("✅ Storage'a yüklendi")
            
            print("🔗 Signed URL oluşturuluyor")
            let url = try await supabase.storage
                .from(id: "adoption_media")
                .createSignedURL(
                    path: path,
                    expiresIn: 3600 * 24 * 365
                )
            print("✅ Signed URL oluşturuldu: \(url)")
            
            return MediaItem(id: id, url: url.absoluteString, type: type, thumbnailUrl: nil)
        } else {
            print("🔄 Video verisi yükleniyor")
            guard let videoData = try await item.loadTransferable(type: Data.self) else {
                print("❌ Video verisi alınamadı")
                throw UploadError.invalidData
            }
            print("✅ Video verisi alındı: \(videoData.count) bytes")
            
            let fileOptions = FileOptions(
                cacheControl: "3600"
            )
            
            let file = File(
                name: path,
                data: videoData, fileName: path,
                contentType: "video/mp4"
            )
            
            print("⬆️ Storage'a yükleniyor")
            try await supabase.storage
                .from(id: "adoption_media")
                .upload(
                    path: path,
                    file: file,
                    fileOptions: fileOptions
                )
            print("✅ Storage'a yüklendi")
            
            print("🔗 Signed URL oluşturuluyor")
            let url = try await supabase.storage
                .from(id: "adoption_media")
                .createSignedURL(
                    path: path,
                    expiresIn: 3600 * 24 * 365
                )
            print("✅ Signed URL oluşturuldu: \(url)")
            
            // TODO: Video thumbnail oluşturma
            
            return MediaItem(id: id, url: url.absoluteString, type: type, thumbnailUrl: nil)
        }
    }
    
    func resetFilters() {
        selectedPetType = nil
        selectedCity = nil
        selectedDistrict = nil
        searchText = ""
    }
    
    func addVaccination() {
        guard !currentVaccination.isEmpty else { return }
        vaccinations.append(currentVaccination)
        currentVaccination = ""
    }
    
    func removeVaccination(at index: Int) {
        vaccinations.remove(at: index)
    }
    
    func addMedicalCondition() {
        guard !currentMedicalCondition.isEmpty else { return }
        medicalConditions.append(currentMedicalCondition)
        currentMedicalCondition = ""
    }
    
    func removeMedicalCondition(at index: Int) {
        medicalConditions.remove(at: index)
    }
    
    func addMedication() {
        guard !currentMedication.isEmpty else { return }
        medications.append(currentMedication)
        currentMedication = ""
    }
    
    func removeMedication(at index: Int) {
        medications.remove(at: index)
    }
    
    private func validateForm() -> Bool {
        formErrors.removeAll()
        
        // Zorunlu alanları kontrol et
        if title.isEmpty {
            formErrors.append("Başlık boş bırakılamaz")
        }
        if description.isEmpty {
            formErrors.append("Açıklama boş bırakılamaz")
        }
        if breed.isEmpty {
            formErrors.append("Irk bilgisi boş bırakılamaz")
        }
        if city.isEmpty {
            formErrors.append("Şehir seçilmedi")
        }
        if district.isEmpty {
            formErrors.append("İlçe seçilmedi")
        }
        if selectedPhotos.isEmpty {
            formErrors.append("En az bir fotoğraf eklemelisiniz")
        }
        
        return formErrors.isEmpty
    }
}

struct AdoptionPostInput {
    let userId: UUID
    let title: String
    let description: String
    let petType: String
    let breed: String
    let age: String
    let gender: String
    let size: String
    let color: String
    let vaccinations: [String]
    let isNeutered: Bool
    let hasPassport: Bool
    let hasChip: Bool
    let medicalConditions: [String]
    let medications: [String]
    let specialNeeds: String
    let city: String
    let district: String
    let showPhone: Bool
    let media: [MediaItem]
    let status: String
    let created_at: String
    let updated_at: String
    
    func toDictionary() -> [String: String] {
        [
            "user_id": userId.uuidString,
            "title": title,
            "description": description,
            "pet_type": petType,
            "breed": breed,
            "age": age,
            "gender": gender,
            "size": size,
            "color": color,
            "vaccinations": "{}",
            "is_neutered": isNeutered.sqlString,
            "has_passport": hasPassport.sqlString,
            "has_chip": hasChip.sqlString,
            "medical_conditions": "{}",
            "medications": "{}",
            "special_needs": specialNeeds,
            "city": city,
            "district": district,
            "show_phone": showPhone.sqlString,
            "status": status,
            "created_at": created_at,
            "updated_at": updated_at
        ]
    }
}

enum ValidationError: Error {
    case missingRequiredFields
}

enum UploadError: Error {
    case invalidData
}

struct AdoptionModel: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let media: MediaContent
    let location: String
    let contact: String
    let date: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case media
        case location
        case contact
        case date
    }
}

struct MediaContent: Codable {
    let urls: [String]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let singleUrl = try? container.decode(String.self) {
            self.urls = [singleUrl]
        }
        else if let urlArray = try? container.decode([String].self) {
            self.urls = urlArray
        }
        else {
            self.urls = []
        }
    }
}

private extension Data {
    func stringValue() -> String {
        String(data: self, encoding: .utf8) ?? "[]"
    }
}

// Array formatını düzeltiyoruz
func arrayToPostgresString(_ array: [String]) -> String {
    if array.isEmpty {
        return "{}"
    }
    return "{" + array.map { "\"\($0)\"" }.joined(separator: ",") + "}"
}

private extension Bool {
    var sqlString: String {
        self ? "true" : "false"
    }
} 
