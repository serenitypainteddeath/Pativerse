import SwiftUI
import PhotosUI

struct AdoptionListView: View {
    @StateObject private var viewModel = AdoptionViewModel()
    @State private var showFilters = false
    @State private var showCreatePost = false
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
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
                        
                        // Aktif Filtreler
                        if viewModel.selectedPetType != nil || viewModel.selectedCity != nil || viewModel.selectedDistrict != nil {
                            ActiveFiltersView(viewModel: viewModel)
                                .padding(.horizontal)
                        }
                        
                        // İlan Listesi
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(viewModel.filteredPosts) { post in
                                NavigationLink(destination: AdoptionDetailView(post: post)) {
                                    AdoptionCard(post: post)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                .refreshable {
                    await viewModel.fetchPosts()
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
                    } else if viewModel.posts.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "pawprint.circle")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            
                            Text("Henüz ilan bulunmuyor")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemGray6))
                    }
                }
                
                // İlan Oluştur Butonu
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showCreatePost = true }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.purple)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Sahiplendir")
            .sheet(isPresented: $showFilters) {
                AdoptionFilterView(viewModel: viewModel)
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $showCreatePost) {
                CreateAdoptionPostView(viewModel: viewModel)
            }
        }
        .task {
            await viewModel.fetchPosts()
        }
    }
}

struct AdoptionCard: View {
    let post: AdoptionPost
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // İlan Fotoğrafı
            if let firstImage = post.media.first(where: { $0.type == .image }) {
                AsyncImage(url: URL(string: firstImage.url)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                }
                .frame(height: 200)
                .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 200)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                    }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                // Başlık
                Text(post.title)
                    .font(.headline)
                    .lineLimit(2)
                
                // Detaylar
                HStack {
                    Label(post.petType.localizedName, systemImage: post.petType.icon)
                        .font(.caption)
                    
                    Spacer()
                    
                    Label(post.age.localizedName, systemImage: "clock")
                        .font(.caption)
                }
                .foregroundColor(.gray)
                
                // Konum
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.red)
                    
                    Text("\(post.district), \(post.city)")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            .padding()
            .background(Color.white)
        }
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct ActiveFiltersView: View {
    @ObservedObject var viewModel: AdoptionViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let petType = viewModel.selectedPetType {
                    FilterChip(
                        text: petType.localizedName,
                        onRemove: { viewModel.selectedPetType = nil }
                    )
                }
                
                if let city = viewModel.selectedCity {
                    FilterChip(
                        text: city,
                        onRemove: { viewModel.selectedCity = nil }
                    )
                }
                
                if let district = viewModel.selectedDistrict {
                    FilterChip(
                        text: district,
                        onRemove: { viewModel.selectedDistrict = nil }
                    )
                }
                
                Button(action: viewModel.resetFilters) {
                    Text("Temizle")
                        .font(.caption)
                        .foregroundColor(.purple)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

struct FilterChip: View {
    let text: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.caption)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.white)
        .cornerRadius(15)
    }
}

struct AdoptionFilterView: View {
    @ObservedObject var viewModel: AdoptionViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Hayvan Türü") {
                    Picker("Tür Seçin", selection: $viewModel.selectedPetType) {
                        Text("Tümü").tag(Optional<PetType>.none)
                        ForEach(PetType.allCases, id: \.self) { type in
                            Text(type.localizedName).tag(Optional(type))
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Şehir") {
                    Picker("Şehir Seçin", selection: $viewModel.selectedCity) {
                        Text("Tümü").tag(Optional<String>.none)
                        ForEach(viewModel.cities, id: \.self) { city in
                            Text(city).tag(Optional(city))
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                if viewModel.selectedCity != nil {
                    Section("İlçe") {
                        Picker("İlçe Seçin", selection: $viewModel.selectedDistrict) {
                            Text("Tümü").tag(Optional<String>.none)
                            ForEach(viewModel.districts, id: \.self) { district in
                                Text(district).tag(Optional(district))
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            }
            .navigationTitle("Filtreler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Sıfırla") {
                        viewModel.resetFilters()
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

struct AdoptionStatusBadge: View {
    let status: PostStatus
    
    var body: some View {
        Text(status.localizedName)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(status.color))
            .cornerRadius(4)
    }
} 