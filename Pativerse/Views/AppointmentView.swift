import SwiftUI

struct AppointmentView: View {
    let veterinary: VeterinaryProfile
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = AppointmentViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Tarih Seçimi
                    DatePicker(
                        "Tarih Seçin",
                        selection: $viewModel.selectedDate,
                        in: Date()...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    
                    // Hizmet Seçimi
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Hizmet Seçin")
                            .font(.headline)
                        
                        ForEach(veterinary.services, id: \.id) { service in
                            ServiceSelectionRow(
                                service: service,
                                isSelected: viewModel.selectedService?.id == service.id,
                                action: { viewModel.selectedService = service }
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    
                    // Müsait Saatler
                    if let selectedService = viewModel.selectedService {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Müsait Saatler")
                                .font(.headline)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 10) {
                                ForEach(viewModel.availableSlots(for: selectedService, workingHours: veterinary.workingHours), id: \.self) { slot in
                                    TimeSlotButton(
                                        time: slot,
                                        isSelected: viewModel.selectedTime == slot,
                                        action: { viewModel.selectedTime = slot }
                                    )
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                    }
                    
                    // Notlar Alanı
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Notlar (Opsiyonel)")
                            .font(.headline)
                        
                        TextEditor(text: $viewModel.notes)
                            .frame(height: 100)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    
                    // Randevu Oluştur Butonu
                    if viewModel.canCreateAppointment {
                        Button(action: {
                            createAppointment()
                        }) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Randevu Oluştur")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                            }
                        }
                        .background(Color.purple)
                        .cornerRadius(10)
                        .disabled(viewModel.isLoading)
                    }
                }
                .padding()
            }
            .navigationTitle("Randevu Al")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
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
    
    private func createAppointment() {
        Task {
            do {
                if try await viewModel.createAppointment(veterinaryId: veterinary.id) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        dismiss()
                    }
                }
            } catch {
                // Hata durumu
            }
        }
    }
}

struct ServiceSelectionRow: View {
    let service: Service
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(service.name)
                        .font(.headline)
                    Text("\(service.duration) dk")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(Int(service.price)) ₺")
                    .font(.headline)
                    .foregroundColor(.purple)
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .purple : .gray)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TimeSlotButton: View {
    let time: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(time)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(isSelected ? Color.purple : Color(.systemGray6))
                .cornerRadius(8)
        }
    }
} 