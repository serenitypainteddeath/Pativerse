import Foundation
import Supabase

struct AppointmentInput: Encodable {
    let veterinary_id: String
    let user_id: String
    let service_id: String
    let pet_id: String?
    let date_time: String
    let duration: Int
    let status: String
    let payment_status: String
    let notes: String?
    let created_at: String
}

@MainActor
class AppointmentViewModel: ObservableObject {
    @Published var selectedDate = Date()
    @Published var selectedService: Service?
    @Published var selectedTime: String?
    @Published var notes: String = ""
    @Published var isLoading = false
    @Published var error: String?
    @Published var showSuccessAlert = false
    @Published var successMessage = ""
    
    private let supabase = SupabaseClient(
        supabaseURL: URL(string: "https://jtyierzqnnlthzfcdbcf.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp0eWllcnpxbm5sdGh6ZmNkYmNmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzYwMzQ0MzAsImV4cCI6MjA1MTYxMDQzMH0.nJLFpVRxrRW_PXOU7vKt2G4ceOlUDDNUvo-fA4fVLyA"
    )
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
        formatter.timeZone = TimeZone(secondsFromGMT: 0) // UTC için
        return formatter
    }()
    
    var canCreateAppointment: Bool {
        selectedService != nil && selectedTime != nil
    }
    
    func availableSlots(for service: Service, workingHours: WorkingHours) -> [String] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: selectedDate)
        let adjustedWeekday = weekday == 1 ? 7 : weekday - 1
        
        let dayHours: WorkDay?
        if adjustedWeekday <= 5 {
            dayHours = workingHours.weekdays.first { $0.day == adjustedWeekday }
        } else {
            dayHours = workingHours.weekend.first { $0.day == adjustedWeekday }
        }
        
        guard let hours = dayHours, !hours.isClosed else {
            return []
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        let openTime = formatter.date(from: hours.open)!
        let closeTime = formatter.date(from: hours.close)!
        
        var slots: [String] = []
        var currentTime = openTime
        
        while currentTime <= closeTime {
            slots.append(formatter.string(from: currentTime))
            currentTime = calendar.date(byAdding: .minute, value: service.duration, to: currentTime)!
        }
        
        return slots
    }
    
    func createAppointment(veterinaryId: String) async throws -> Bool {
        print("🔵 Randevu oluşturma başladı")
        
        // Oturum kontrolü
        guard let session = try? await supabase.auth.session else {
            error = "Oturum açmanız gerekiyor"
            print("❌ Oturum bulunamadı")
            throw AppointmentError.sessionRequired
        }
        
        print("🔵 Oturum durumu: aktif")
        print("🔵 Kullanıcı ID: \(session.user.id)")
        print("🔵 Seçilen tarih: \(selectedDate)")
        print("🔵 Seçilen saat: \(selectedTime ?? "nil")")
        print("🔵 Seçilen hizmet: \(selectedService?.name ?? "nil")")
        print("🔵 Veteriner ID: \(veterinaryId)")
        print("🔵 Notlar: \(notes)")
        
        guard let service = selectedService,
              let timeString = selectedTime else {
            print("❌ Gerekli alanlar eksik")
            error = "Lütfen tüm gerekli alanları doldurun"
            throw AppointmentError.missingFields
        }
        
        isLoading = true
        error = nil
        
        defer {
            isLoading = false
        }
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        guard let time = timeFormatter.date(from: timeString) else {
            error = "Geçersiz saat formatı"
            print("❌ Saat formatı dönüşüm hatası")
            throw AppointmentError.invalidTimeFormat
        }
        
        let calendar = Calendar.current
        let appointmentComponents = calendar.dateComponents([.hour, .minute], from: time)
        var finalDateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        finalDateComponents.hour = appointmentComponents.hour
        finalDateComponents.minute = appointmentComponents.minute
        finalDateComponents.second = 0 // Saniyeyi 0 olarak ayarla
        
        guard let finalDate = calendar.date(from: finalDateComponents) else {
            error = "Tarih oluşturulamadı"
            print("❌ Final tarih oluşturma hatası")
            throw AppointmentError.invalidDate
        }
        
        print("🔵 Final tarih: \(finalDate)")
        
        do {
            let userId = try await supabase.auth.session.user.id.uuidString
            print("🔵 Kullanıcı ID: \(userId)")
            
            let newServiceId = UUID().uuidString.uppercased()
            let currentDate = dateFormatter.string(from: Date())
            let appointmentDate = dateFormatter.string(from: finalDate)
            
            let appointmentInput = AppointmentInput(
                veterinary_id: veterinaryId,
                user_id: userId,
                service_id: newServiceId,
                pet_id: "550e8496-e29b-41d4-a716-447755440000",
                date_time: appointmentDate,
                duration: service.duration,
                status: "pending",
                payment_status: "pending",
                notes: notes.isEmpty ? "" : notes,
                created_at: currentDate
            )
            
            print("🔵 Gönderilecek veriler:")
            print("   veterinary_id: \(appointmentInput.veterinary_id)")
            print("   user_id: \(appointmentInput.user_id)")
            print("   service_id: \(appointmentInput.service_id)")
            print("   pet_id: \(appointmentInput.pet_id ?? "nil")")
            print("   date_time: \(appointmentInput.date_time)")
            print("   duration: \(appointmentInput.duration)")
            print("   status: \(appointmentInput.status)")
            print("   payment_status: \(appointmentInput.payment_status)")
            print("   notes: \(appointmentInput.notes ?? "yok")")
            print("   created_at: \(appointmentInput.created_at)")
            
            let response = try await supabase.database
                .from("appointments")
                .insert(values: [
                    "veterinary_id": appointmentInput.veterinary_id,
                    "user_id": appointmentInput.user_id,
                    "service_id": appointmentInput.service_id,
                    "pet_id": appointmentInput.pet_id ?? "",
                    "date_time": appointmentInput.date_time,
                    "duration": String(appointmentInput.duration),
                    "status": appointmentInput.status,
                    "payment_status": appointmentInput.payment_status,
                    "notes": appointmentInput.notes ?? "",
                    "created_at": appointmentInput.created_at
                ])
                .execute()
            
            print("✅ Randevu başarıyla oluşturuldu")
            print("✅ Yanıt: \(response)")
            
            successMessage = "Randevunuz başarıyla oluşturuldu!"
            showSuccessAlert = true
            return true
            
        } catch {
            self.error = "Randevu oluşturma hatası: \(error.localizedDescription)"
            print("❌ Hata: \(error)")
            if let postgrestError = error as? PostgrestError {
                print("❌ Postgrest Hata Detayı: \(postgrestError)")
            }
            throw error
        }
    }
}

enum AppointmentError: Error {
    case sessionRequired
    case missingFields
    case invalidTimeFormat
    case invalidDate
} 
