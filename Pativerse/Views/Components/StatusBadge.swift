import SwiftUI

struct StatusBadge: View {
    let veterinary: VeterinaryProfile
    
    var body: some View {
        Text(veterinary.isCurrentlyOpen ? "Açık" : "Kapalı")
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(veterinary.isCurrentlyOpen ? Color.green : Color.red)
            .cornerRadius(4)
    }
} 