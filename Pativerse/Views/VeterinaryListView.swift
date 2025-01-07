import SwiftUI
import SDWebImage
import SDWebImageSwiftUI

struct VeterinaryListView: View {
    @StateObject private var viewModel = VeterinaryViewModel()
    @State private var showFilters = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGray6)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Arama ve Filtre
                        SearchFilterBar(
                            searchText: $viewModel.searchText,
                            showFilters: $showFilters
                        )
                        .padding(.horizontal)
                        
                        // Veteriner Listesi
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.filteredVeterinaries) { vet in
                                NavigationLink(destination: VeterinaryDetailView(veterinary: vet)) {
                                    VeterinaryCard(veterinary: vet)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                .refreshable {
                    await viewModel.fetchVeterinaries()
                }
                .overlay {
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black.opacity(0.2))
                    } else if let error = viewModel.error {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            
                            Text(error)
                                .font(.headline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemGray6))
                    }
                }
            }
            .navigationTitle("Veterinerler")
            .sheet(isPresented: $showFilters) {
                FilterView(
                    selectedCity: $viewModel.selectedCity,
                    selectedDistrict: $viewModel.selectedDistrict,
                    cities: viewModel.cities,
                    districts: viewModel.districts,
                    resetFilters: viewModel.resetFilters
                )
                .presentationDetents([.medium])
            }
        }
        .task {
            await viewModel.fetchVeterinaries()
        }
    }
}

struct SearchFilterBar: View {
    @Binding var searchText: String
    @Binding var showFilters: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Veteriner veya klinik ara", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            
            Button(action: { showFilters.toggle() }) {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.purple)
                    .padding(12)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
        }
    }
}

struct VeterinaryCard: View {
    let veterinary: VeterinaryProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Klinik Fotoğrafı
            WebImage(url: URL(string: veterinary.basicInfo.coverImage)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Image(systemName: "photo")
                    .foregroundColor(.gray)
            }
            .frame(height: 200)
            .clipped()
            .clipShape(
                RoundedCorner(
                    radius: 15,
                    corners: [UIRectCorner.topLeft, UIRectCorner.topRight]
                )
            )
            
            VStack(alignment: .leading, spacing: 12) {
                // Klinik Adı ve Durum
                HStack {
                    Text(veterinary.basicInfo.clinicName)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    StatusBadge(veterinary: veterinary)
                }
                
                // Veteriner Adı
                Text(veterinary.basicInfo.name)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Divider()
                
                // Alt Bilgiler
                HStack(spacing: 16) {
                    // Puan
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        
                        Text(String(format: "%.1f", veterinary.statistics.rating))
                            .fontWeight(.medium)
                        
                        Text("(\(veterinary.statistics.reviewCount))")
                            .foregroundColor(.gray)
                    }
                    
                    // Konum
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .foregroundColor(.red)
                        
                        Text("\(veterinary.location.district), \(veterinary.location.city)")
                            .lineLimit(1)
                    }
                }
                .font(.footnote)
            }
            .padding()
            .background(Color.white)
        }
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}



struct FilterView: View {
    @Binding var selectedCity: String
    @Binding var selectedDistrict: String
    let cities: [String]
    let districts: [String]
    let resetFilters: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Şehir") {
                    Picker("Şehir Seçin", selection: $selectedCity) {
                        ForEach(cities, id: \.self) { city in
                            Text(city).tag(city)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("İlçe") {
                    Picker("İlçe Seçin", selection: $selectedDistrict) {
                        ForEach(districts, id: \.self) { district in
                            Text(district).tag(district)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle("Filtreler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Sıfırla") {
                        resetFilters()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Tamam") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Extensions
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
} 
