import SwiftUI
import MapKit


struct VeterinaryDetailView: View {
    let veterinary: VeterinaryProfile
    @State private var selectedTab = 0
    @State private var region: MKCoordinateRegion
    @State private var showAppointment = false
    
    init(veterinary: VeterinaryProfile) {
        self.veterinary = veterinary
        let coordinate = CLLocationCoordinate2D(
            latitude: veterinary.location.latitude,
            longitude: veterinary.location.longitude
        )
        _region = State(initialValue: MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header Image ve Profil
                ZStack(alignment: .bottom) {
                    // Cover Image
                    AsyncImage(url: URL(string: veterinary.basicInfo.coverImage)) { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                    }
                    .frame(height: 200)
                    .clipped()
                    
                    // Profil Bilgileri
                    HStack(alignment: .bottom, spacing: 16) {
                        // Profil Resmi
                        AsyncImage(url: URL(string: veterinary.basicInfo.profileImage)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 3))
                        .shadow(radius: 3)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(veterinary.basicInfo.clinicName)
                                .font(.title2)
                                .fontWeight(.bold)
                            Text(veterinary.basicInfo.name)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Açık/Kapalı Durumu
                        StatusBadge(veterinary: veterinary)
                    }
                    .padding()
                    .background(
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .blur(radius: 3)
                    )
                }
                
                // İletişim Bilgileri
                VStack(alignment: .leading, spacing: 12) {
                    ContactRow(icon: "phone.fill", text: veterinary.basicInfo.phone)
                    ContactRow(icon: "envelope.fill", text: veterinary.basicInfo.email)
                    ContactRow(icon: "globe", text: veterinary.basicInfo.website)
                    ContactRow(icon: "mappin.and.ellipse", text: veterinary.location.address)
                }
                .padding(.horizontal)
                
                // İstatistikler
                StatisticsView(statistics: veterinary.statistics)
                    .padding(.horizontal)
                
                // Tab View
                Picker("", selection: $selectedTab) {
                    Text("Hakkında").tag(0)
                    Text("Hizmetler").tag(1)
                    Text("Yorumlar").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Tab İçeriği
                switch selectedTab {
                case 0:
                    AboutTab(veterinary: veterinary)
                case 1:
                    ServicesTab(services: veterinary.services)
                case 2:
                    ReviewsTab(reviews: veterinary.reviews)
                default:
                    EmptyView()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .bottom) {
            Button(action: { showAppointment = true }) {
                Text("Randevu Al")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                    .background(Color.purple)
                    .cornerRadius(15)
                    .padding()
            }
            .background(
                Rectangle()
                    .fill(.white)
                    .shadow(color: .black.opacity(0.1), radius: 5, y: -5)
            )
        }
        .sheet(isPresented: $showAppointment) {
            AppointmentView(veterinary: veterinary)
        }
    }
}

// MARK: - Yardımcı Görünümler
struct ContactRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            Text(text)
            Spacer()
        }
    }
}

struct StatisticsView: View {
    let statistics: Statistics
    
    var body: some View {
        HStack {
            StatItem(value: String(format: "%.1f", statistics.rating), title: "Puan")
            Divider()
            StatItem(value: "\(statistics.reviewCount)", title: "Yorum")
            Divider()
            StatItem(value: "\(statistics.appointmentCount)", title: "Randevu")
            Divider()
            StatItem(value: "\(Int(statistics.completionRate))%", title: "Tamamlanma")
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct StatItem: View {
    let value: String
    let title: String
    
    var body: some View {
        VStack {
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Tab Görünümleri
struct AboutTab: View {
    let veterinary: VeterinaryProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Hakkında
            VStack(alignment: .leading, spacing: 8) {
                Text("Hakkında")
                    .font(.headline)
                Text(veterinary.professionalInfo.about)
                    .font(.body)
            }
            
            // Uzmanlık Alanları
            VStack(alignment: .leading, spacing: 8) {
                Text("Uzmanlık Alanları")
                    .font(.headline)
                ForEach(veterinary.professionalInfo.specialties, id: \.name) { specialty in
                    VStack(alignment: .leading) {
                        Text(specialty.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(specialty.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Çalışma Saatleri
            VStack(alignment: .leading, spacing: 8) {
                Text("Çalışma Saatleri")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hafta İçi")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    ForEach(veterinary.workingHours.weekdays, id: \.day) { day in
                        if !day.isClosed {
                            Text("\(dayName(day.day)): \(day.open) - \(day.close)")
                                .font(.caption)
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hafta Sonu")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    ForEach(veterinary.workingHours.weekend, id: \.day) { day in
                        if !day.isClosed {
                            Text("\(dayName(day.day)): \(day.open) - \(day.close)")
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .padding()
    }
    
    private func dayName(_ day: Int) -> String {
        switch day {
        case 1: return "Pazartesi"
        case 2: return "Salı"
        case 3: return "Çarşamba"
        case 4: return "Perşembe"
        case 5: return "Cuma"
        case 6: return "Cumartesi"
        case 7: return "Pazar"
        default: return ""
        }
    }
}

struct ServicesTab: View {
    let services: [Service]
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(services, id: \.id) { service in
                ServiceCard(service: service)
            }
        }
        .padding()
    }
}

struct ServiceCard: View {
    let service: Service
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(service.name)
                    .font(.headline)
                Spacer()
                Text("\(Int(service.price)) ₺")
                    .font(.headline)
                    .foregroundColor(.accentColor)
            }
            
            Text(service.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Label("\(service.duration) dk", systemImage: "clock")
                Spacer()
                Text(service.category)
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct ReviewsTab: View {
    let reviews: [Review]?
    
    var body: some View {
        VStack(spacing: 16) {
            if let reviews = reviews, !reviews.isEmpty {
                ForEach(reviews) { review in
                    ReviewCard(review: review)
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "star.slash")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("Henüz değerlendirme yapılmamış")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            }
        }
        .padding()
    }
}

struct ReviewCard: View {
    let review: Review
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Kullanıcı Resmi
                if let imageUrl = review.userImage {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                }
                
                VStack(alignment: .leading) {
                    Text(review.userName)
                        .font(.headline)
                    Text(review.date.formatted())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Yıldız Puanı
                HStack {
                    Text(String(review.rating))
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
                .font(.subheadline)
            }
            
            Text(review.comment)
                .font(.body)
            
            if let response = review.response {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Yanıt")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(response.text)
                        .font(.body)
                    Text(response.date.formatted())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
} 
