import Foundation
import Supabase
import GoTrue

@MainActor
class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: String?
    
    private let supabase = SupabaseClient(
        supabaseURL: URL(string: "https://jtyierzqnnlthzfcdbcf.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp0eWllcnpxbm5sdGh6ZmNkYmNmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzYwMzQ0MzAsImV4cCI6MjA1MTYxMDQzMH0.nJLFpVRxrRW_PXOU7vKt2G4ceOlUDDNUvo-fA4fVLyA"
    )
    
    private func formatPhoneNumber(_ phone: String) -> String {
        var formatted = phone.replacingOccurrences(of: " ", with: "")
        if !formatted.hasPrefix("+90") {
            formatted = "+90" + formatted
        }
        return formatted
    }
    
    func signUp(phone: String, email: String?, fullName: String, password: String) async {
        isLoading = true
        error = nil
        
        do {
            let formattedPhone = formatPhoneNumber(phone)
            
            let authResponse = try await supabase.auth.signUp(
                phone: formattedPhone,
                password: password,
                data: [
                    "full_name": AnyJSON.string(fullName),
                    "email": AnyJSON.string(email ?? ""),
                    "phone": AnyJSON.string(formattedPhone)
                ]
            )
            
            if authResponse.user != nil {
                isLoading = false
            }
        } catch {
            self.error = "Kayıt olurken bir hata oluştu: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    func verifyPhone(phone: String, token: String) async {
        isLoading = true
        error = nil
        
        do {
            let formattedPhone = formatPhoneNumber(phone)
            
            let response = try await supabase.auth.verifyOTP(
                phone: formattedPhone,
                token: token,
                type: .sms
            )
            
            if let user = response.user {
                try await supabase.database
                    .from("profiles")
                    .update(values: ["is_phone_verified": AnyJSON.bool(true)])
                    .eq(column: "id", value: user.id)
                    .execute()
                
                await fetchUser()
                isAuthenticated = true
            }
        } catch {
            self.error = "Doğrulama başarısız: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func signIn(phone: String, password: String) async {
        isLoading = true
        error = nil
        
        do {
            let formattedPhone = formatPhoneNumber(phone)
            
            let response = try await supabase.auth.signIn(
                phone: formattedPhone,
                password: password
            )
            
            if response.user != nil {
                await fetchUser()
                isAuthenticated = true
            }
        } catch {
            self.error = "Giriş başarısız: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func signOut() async {
        do {
            try await supabase.auth.signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            self.error = "Çıkış yapılırken hata oluştu: \(error.localizedDescription)"
        }
    }
    
    private func fetchUser() async {
        do {
            let response = try await supabase.database
                .from("profiles")
                .select()
                .single()
                .execute()
                .value
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: response) {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                currentUser = try decoder.decode(User.self, from: jsonData)
            }
        } catch {
            self.error = "Kullanıcı bilgileri alınamadı: \(error.localizedDescription)"
        }
    }
} 
