import SwiftUI
import Supabase
import Supabase

struct AuthView: View {
    @State private var isLogin = true
    @State private var phone = ""
    @State private var email = ""
    @State private var password = ""
    @State private var fullName = ""
    @State private var verificationCode = ""
    @State private var showVerification = false
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                // Arka plan gradyanı
                LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.2)]),
                             startPoint: .topLeading,
                             endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Logo ve başlık
                        VStack(spacing: 15) {
                            Image(systemName: "pawprint.circle.fill")
                                .resizable()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.purple)
                            
                            Text("Pativerse")
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundColor(.purple)
                        }
                        .padding(.top, 50)
                        
                        if showVerification {
                            // Doğrulama kodu ekranı
                            VStack(spacing: 20) {
                                Text("Telefon Doğrulama")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text("\(phone) numarasına gönderilen kodu giriniz")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                
                                CustomTextField(text: $verificationCode,
                                             placeholder: "Doğrulama Kodu",
                                             systemImage: "key.fill")
                                    .keyboardType(.numberPad)
                                
                                Button(action: {
                                    Task {
                                        await authViewModel.verifyPhone(phone: phone, token: verificationCode)
                                    }
                                }) {
                                    Text("Doğrula")
                                        .buttonStyle()
                                }
                            }
                            .padding(.horizontal, 24)
                        } else {
                            // Giriş/Kayıt ekranı
                            Picker("Auth Mode", selection: $isLogin) {
                                Text("Giriş Yap").tag(true)
                                Text("Kayıt Ol").tag(false)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.horizontal, 24)
                            
                            VStack(spacing: 20) {
                                if !isLogin {
                                    CustomTextField(text: $fullName,
                                                 placeholder: "Ad Soyad",
                                                 systemImage: "person.fill")
                                    
                                    CustomTextField(text: $email,
                                                 placeholder: "E-posta (Opsiyonel)",
                                                 systemImage: "envelope.fill")
                                        .textInputAutocapitalization(.never)
                                        .keyboardType(.emailAddress)
                                }
                                
                                PhoneNumberTextField(text: $phone,
                                                   placeholder: "Telefon Numarası (5XX XXX XX XX)")
                                
                                CustomSecureField(text: $password,
                                               placeholder: "Şifre",
                                               systemImage: "lock.fill")
                                
                                Button(action: {
                                    Task {
                                        if isLogin {
                                            await authViewModel.signIn(phone: phone, password: password)
                                        } else {
                                            await authViewModel.signUp(phone: phone, email: email, fullName: fullName, password: password)
                                            showVerification = true
                                        }
                                    }
                                }) {
                                    Text(isLogin ? "Giriş Yap" : "Kayıt Ol")
                                        .buttonStyle()
                                }
                                .disabled(authViewModel.isLoading)
                                
                                if isLogin {
                                    Button("Şifremi Unuttum") {
                                        // TODO: Implement forgot password
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.purple)
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                }
                
                if authViewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
            .navigationBarHidden(true)
            .alert("Hata", isPresented: .constant(authViewModel.error != nil)) {
                Button("Tamam") {
                    authViewModel.error = nil
                }
            } message: {
                Text(authViewModel.error ?? "")
            }
        }
    }
    
    private func formatPhoneNumber(_ phone: String) -> String {
        var formatted = phone.replacingOccurrences(of: " ", with: "")
        if formatted.hasPrefix("0") {
            formatted.removeFirst()
        }
        if !formatted.hasPrefix("+90") {
            formatted = "+90" + formatted
        }
        return formatted
    }
}

// MARK: - Custom Components
struct CustomTextField: View {
    @Binding var text: String
    let placeholder: String
    let systemImage: String
    
    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundColor(.gray)
                .frame(width: 20)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
    }
}

struct CustomSecureField: View {
    @Binding var text: String
    let placeholder: String
    let systemImage: String
    
    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundColor(.gray)
                .frame(width: 20)
            
            SecureField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
    }
}

struct PhoneNumberTextField: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        CustomTextField(text: $text,
                      placeholder: placeholder,
                      systemImage: "phone.fill")
            .keyboardType(.phonePad)
            .onChange(of: text) { newValue in
                // Sadece rakamları ve + işaretini kabul et
                let filtered = newValue.filter { "0123456789+".contains($0) }
                if filtered != newValue {
                    text = filtered
                }
                
                // Maksimum uzunluk kontrolü (başında +90 ile birlikte 13 karakter)
                if filtered.count > 13 {
                    text = String(filtered.prefix(13))
                }
            }
    }
}

// MARK: - View Extensions
extension Text {
    func buttonStyle() -> some View {
        self
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 55)
            .background(Color.purple)
            .cornerRadius(15)
    }
} 