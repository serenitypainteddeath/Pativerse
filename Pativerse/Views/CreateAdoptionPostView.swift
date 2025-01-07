import SwiftUI
import PhotosUI

struct CreateAdoptionPostView: View {
    @ObservedObject var viewModel: AdoptionViewModel
    @Environment(\.dismiss) var dismiss
    @State private var currentStep = 0
    @State private var showError = false
    @State private var isLoading = false
    
    @State private var currentVaccination = ""
    @State private var currentMedication = ""
    @State private var currentCondition = ""
    
    var body: some View {
        NavigationView {
            Form {
                // Adım 1: Temel Bilgiler
                if currentStep == 0 {
                    Section("İlan Başlığı") {
                        TextField("Örn: Sevimli Yavru Kedi Sahiplendirme", text: $viewModel.title)
                    }
                    
                    Section("Hayvan Bilgileri") {
                        Picker("Tür", selection: $viewModel.petType) {
                            ForEach(PetType.allCases, id: \.self) { type in
                                Text(type.localizedName).tag(type)
                            }
                        }
                        
                        TextField("Cins (Opsiyonel)", text: $viewModel.breed)
                        
                        Picker("Yaş", selection: $viewModel.age) {
                            ForEach(PetAge.allCases, id: \.self) { age in
                                Text(age.localizedName).tag(age)
                            }
                        }
                        
                        Picker("Cinsiyet", selection: $viewModel.gender) {
                            ForEach(PetGender.allCases, id: \.self) { gender in
                                Text(gender.localizedName).tag(gender)
                            }
                        }
                        
                        Picker("Boyut", selection: $viewModel.size) {
                            ForEach(PetSize.allCases, id: \.self) { size in
                                Text(size.localizedName).tag(size)
                            }
                        }
                        
                        TextField("Renk (Opsiyonel)", text: $viewModel.color)
                    }
                }
                
                // Adım 2: Sağlık Bilgileri
                else if currentStep == 1 {
                    Section("Aşılar") {
                        HStack {
                            TextField("Aşı ekle", text: $currentVaccination)
                            Button(action: {
                                if !currentVaccination.isEmpty {
                                    viewModel.vaccinations.append(currentVaccination)
                                    currentVaccination = ""
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        
                        ForEach(viewModel.vaccinations.indices, id: \.self) { index in
                            HStack {
                                Text(viewModel.vaccinations[index])
                                Spacer()
                                Button(action: { viewModel.vaccinations.remove(at: index) }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                    
                    Section {
                        Toggle("Kısırlaştırılmış", isOn: $viewModel.isNeutered)
                        Toggle("Pasaportu Var", isOn: $viewModel.hasPassport)
                        Toggle("Çipi Var", isOn: $viewModel.hasChip)
                    }
                    
                    Section("Sağlık Durumu") {
                        HStack {
                            TextField("Rahatsızlık ekle", text: $currentCondition)
                            Button(action: {
                                if !currentCondition.isEmpty {
                                    viewModel.medicalConditions.append(currentCondition)
                                    currentCondition = ""
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        
                        ForEach(viewModel.medicalConditions.indices, id: \.self) { index in
                            HStack {
                                Text(viewModel.medicalConditions[index])
                                Spacer()
                                Button(action: { viewModel.medicalConditions.remove(at: index) }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                    
                    Section("İlaçlar") {
                        HStack {
                            TextField("İlaç ekle", text: $currentMedication)
                            Button(action: {
                                if !currentMedication.isEmpty {
                                    viewModel.medications.append(currentMedication)
                                    currentMedication = ""
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        
                        ForEach(viewModel.medications.indices, id: \.self) { index in
                            HStack {
                                Text(viewModel.medications[index])
                                Spacer()
                                Button(action: { viewModel.medications.remove(at: index) }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                    
                    Section("Özel İhtiyaçlar (Opsiyonel)") {
                        TextEditor(text: $viewModel.specialNeeds)
                            .frame(height: 100)
                    }
                }
                
                // Adım 3: Medya
                else if currentStep == 2 {
                    Section("Fotoğraflar") {
                        PhotosPicker(
                            selection: $viewModel.selectedPhotos,
                            maxSelectionCount: 5,
                            matching: .images
                        ) {
                            Label("Fotoğraf Seç (Maks. 5)", systemImage: "photo.on.rectangle")
                        }
                        
                        if !viewModel.selectedPhotos.isEmpty {
                            ScrollView(.horizontal) {
                                HStack {
                                    ForEach(viewModel.selectedPhotos, id: \.self) { photo in
                                        PhotoPreview(photo: photo)
                                    }
                                }
                            }
                            .frame(height: 100)
                        }
                    }
                    
                    Section("Video (Opsiyonel)") {
                        PhotosPicker(
                            selection: $viewModel.selectedVideo,
                            matching: .videos
                        ) {
                            Label("Video Seç", systemImage: "video")
                        }
                        
                        if viewModel.selectedVideo != nil {
                            Text("Video seçildi")
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                // Adım 4: Konum ve İletişim
                else if currentStep == 3 {
                    Section("Konum") {
                        TextField("Şehir", text: $viewModel.city)
                        TextField("İlçe", text: $viewModel.district)
                    }
                    
                    Section {
                        Toggle("Telefon Numaramı Göster", isOn: $viewModel.showPhone)
                    } footer: {
                        Text("Telefon numaranız ilan detayında görünür olacaktır.")
                    }
                    
                    Section("İlan Açıklaması") {
                        TextEditor(text: $viewModel.description)
                            .frame(height: 150)
                    }
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if currentStep == 0 {
                        Button("İptal") {
                            dismiss()
                        }
                    } else {
                        Button("Geri") {
                            currentStep -= 1
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if currentStep == 3 {
                        Button(action: createPost) {
                            if isLoading {
                                ProgressView()
                            } else {
                                Text("Oluştur")
                                    .bold()
                            }
                        }
                        .disabled(isLoading)
                    } else {
                        Button("İleri") {
                            currentStep += 1
                        }
                    }
                }
            }
            .alert("Hata", isPresented: $showError) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text(viewModel.error ?? "Bir hata oluştu")
            }
            
            // Form hataları için
            if !viewModel.formErrors.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.formErrors, id: \.self) { error in
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            }
        }
        .overlay {
            if viewModel.showSuccessAlert {
                SuccessToast(
                    message: viewModel.successMessage,
                    isPresented: $viewModel.showSuccessAlert
                )
            }
        }
    }
    
    private var navigationTitle: String {
        switch currentStep {
        case 0: return "Temel Bilgiler"
        case 1: return "Sağlık Bilgileri"
        case 2: return "Fotoğraf/Video"
        case 3: return "Konum ve İletişim"
        default: return ""
        }
    }
    
    private func createPost() {
        isLoading = true
        
        Task {
            do {
                if try await viewModel.createPost() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        dismiss()
                    }
                }
            } catch {
                // Hata durumunda form hataları gösterilecek
            }
            isLoading = false
        }
    }
}

struct PhotoPreview: View {
    let photo: PhotosPickerItem
    @State private var image: Image?
    
    var body: some View {
        Group {
            if let image = image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay {
                        ProgressView()
                    }
            }
        }
        .frame(width: 100, height: 100)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        guard let data = try? await photo.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data) else {
            return
        }
        
        image = Image(uiImage: uiImage)
    }
} 