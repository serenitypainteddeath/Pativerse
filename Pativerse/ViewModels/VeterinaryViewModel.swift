import Foundation
import Supabase
import PostgREST
@MainActor
class VeterinaryViewModel: ObservableObject {
    @Published var veterinaries: [VeterinaryProfile] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var selectedCity: String = "Tüm Şehirler"
    @Published var selectedDistrict: String = "Tüm İlçeler"
    @Published var searchText = ""
    
    private let supabase = SupabaseClient(
        supabaseURL: URL(string: "https://jtyierzqnnlthzfcdbcf.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp0eWllcnpxbm5sdGh6ZmNkYmNmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzYwMzQ0MzAsImV4cCI6MjA1MTYxMDQzMH0.nJLFpVRxrRW_PXOU7vKt2G4ceOlUDDNUvo-fA4fVLyA"
    )
    
    var cities: [String] {
        var citySet = Set<String>()
        veterinaries.forEach { citySet.insert($0.location.city) }
        return ["Tüm Şehirler"] + Array(citySet).sorted()
    }
    
    var districts: [String] {
        var districtSet = Set<String>()
        veterinaries
            .filter { selectedCity == "Tüm Şehirler" || $0.location.city == selectedCity }
            .forEach { districtSet.insert($0.location.district) }
        return ["Tüm İlçeler"] + Array(districtSet).sorted()
    }
    
    var filteredVeterinaries: [VeterinaryProfile] {
        veterinaries.filter { vet in
            let matchesCity = selectedCity == "Tüm Şehirler" || vet.location.city == selectedCity
            let matchesDistrict = selectedDistrict == "Tüm İlçeler" || vet.location.district == selectedDistrict
            let matchesSearch = searchText.isEmpty || 
                vet.basicInfo.clinicName.localizedCaseInsensitiveContains(searchText) ||
                vet.basicInfo.name.localizedCaseInsensitiveContains(searchText)
            
            return matchesCity && matchesDistrict && matchesSearch
        }
    }
    
    func fetchVeterinaries() async {
        isLoading = true
        error = nil
        
        do {
            print("Supabase'e istek yapılıyor...")
            
            let response: PostgrestResponse<[VeterinaryProfile]> = try await supabase.database
                .from("veterinary_profiles")
                .select()
                .execute()
            
            veterinaries = response.value
            print("Veteriner sayısı:", veterinaries.count)
            
            if veterinaries.isEmpty {
                print("Veri bulunamadı")
                self.error = "Henüz veteriner kliniği bulunmuyor."
            }
        } catch {
            self.error = "Veteriner listesi alınamadı: \(error.localizedDescription)"
            print("Supabase hatası:", error)
        }
        
        isLoading = false
    }
    
    func resetFilters() {
        selectedCity = "Tüm Şehirler"
        selectedDistrict = "Tüm İlçeler"
        searchText = ""
    }
    
    func addReview(veterinaryId: String, appointmentId: String, rating: Int, comment: String) async throws {
        do {
            let userId = try await supabase.auth.session.user.id.uuidString
            
            try await supabase.database
                .from("reviews")
                .insert(values: [
                    "veterinary_id": AnyJSON.string(veterinaryId),
                    "appointment_id": AnyJSON.string(appointmentId),
                    "user_id": AnyJSON.string(userId),
                    "rating": AnyJSON.number(Double(rating)),
                    "comment": AnyJSON.string(comment)
                ])
                .execute()
            
            await updateVeterinaryStatistics(veterinaryId: veterinaryId)
        } catch {
            throw error
        }
    }
    
    private func updateVeterinaryStatistics(veterinaryId: String) async {
        do {
            let response = try await supabase.database
                .from("reviews")
                .select(columns: "id, rating")
                .eq(column: "veterinary_id", value: veterinaryId)
                .execute()
            
            if let reviews = response.value as? [[String: Any]] {
                let reviewCount = reviews.count
                let totalRating = reviews.compactMap { $0["rating"] as? Double }.reduce(0, +)
                let averageRating = reviewCount > 0 ? totalRating / Double(reviewCount) : 0
                
                try await supabase.database
                    .from("veterinary_profiles")
                    .update(values: [
                        "statistics": [
                            "rating": AnyJSON.number(averageRating),
                            "review_count": AnyJSON.number(Double(reviewCount))
                        ]
                    ])
                    .eq(column: "id", value: veterinaryId)
                    .execute()
                
                await fetchVeterinaries()
            }
        } catch {
            print("İstatistik güncelleme hatası:", error)
        }
    }
    
    func canUserReview(veterinaryId: String) async -> (canReview: Bool, appointmentId: String?) {
        do {
            let userId = try await supabase.auth.session.user.id.uuidString
            
            let response = try await supabase.database
                .from("appointments")
                .select()
                .eq(column: "veterinary_id", value: veterinaryId)
                .eq(column: "user_id", value: userId)
                .eq(column: "status", value: "completed")
                .not(column: "id", operator: .in, value: """
                    select appointment_id from reviews
                    where veterinary_id = '\(veterinaryId)'
                    and user_id = '\(userId)'
                """)
                .execute()
            
            if let appointments = response.value as? [[String: Any]],
               let firstAppointment = appointments.first,
               let appointmentId = firstAppointment["id"] as? String {
                return (true, appointmentId)
            }
            
            return (false, nil)
        } catch {
            print("Yorum kontrolü hatası:", error)
            return (false, nil)
        }
    }
} 
