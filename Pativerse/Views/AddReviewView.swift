import SwiftUI

struct AddReviewView: View {
    let veterinary: VeterinaryProfile
    let appointmentId: String
    @StateObject private var viewModel = VeterinaryViewModel()
    @State private var rating = 5
    @State private var comment = ""
    @State private var isSubmitting = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Puanınız") {
                    HStack {
                        ForEach(1...5, id: \.self) { index in
                            Image(systemName: index <= rating ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .onTapGesture {
                                    rating = index
                                }
                        }
                    }
                    .font(.title2)
                }
                
                Section("Yorumunuz") {
                    TextEditor(text: $comment)
                        .frame(height: 100)
                }
                
                Section {
                    Button(action: submitReview) {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Gönder")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(comment.isEmpty || isSubmitting)
                }
            }
            .navigationTitle("Değerlendirme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func submitReview() {
        isSubmitting = true
        
        Task {
            do {
                try await viewModel.addReview(
                    veterinaryId: veterinary.id,
                    appointmentId: appointmentId,
                    rating: rating,
                    comment: comment
                )
                dismiss()
            } catch {
                print("Yorum gönderme hatası:", error)
            }
            isSubmitting = false
        }
    }
} 