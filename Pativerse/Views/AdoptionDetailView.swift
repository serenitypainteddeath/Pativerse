import SwiftUI
import AVKit

struct AdoptionDetailView: View {
    let post: AdoptionPost
    @State private var selectedImageIndex = 0
    @State private var showImageViewer = false
    @State private var showVideoPlayer = false
    
    private var images: [MediaItem] {
        post.media.filter { $0.type == .image }
    }
    
    private var video: MediaItem? {
        post.media.first { $0.type == .video }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Medya Galerisi
                TabView(selection: $selectedImageIndex) {
                    ForEach(Array(images.enumerated()), id: \.element.id) { index, image in
                        AsyncImage(url: URL(string: image.url)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .onTapGesture {
                                    selectedImageIndex = index
                                    showImageViewer = true
                                }
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                        }
                    }
                    
                    if let video = video {
                        VideoThumbnail(url: video.url) {
                            showVideoPlayer = true
                        }
                    }
                }
                .tabViewStyle(.page)
                .frame(height: 300)
                .clipShape(Rectangle())
                
                VStack(alignment: .leading, spacing: 20) {
                    // Başlık ve Durum
                    HStack {
                        Text(post.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        AdoptionDetailStatusBadge(status: post.status)
                    }
                    
                    // Temel Bilgiler
                    VStack(alignment: .leading, spacing: 12) {
                        InfoRow(icon: post.petType.icon, text: post.petType.localizedName)
                        if let breed = post.breed {
                            InfoRow(icon: "pawprint", text: breed)
                        }
                        InfoRow(icon: "clock", text: post.age.localizedName)
                        InfoRow(icon: post.gender.icon, text: post.gender.localizedName)
                        if let size = post.size {
                            InfoRow(icon: "ruler", text: size.localizedName)
                        }
                        if let color = post.color {
                            InfoRow(icon: "paintpalette", text: color)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    // Sağlık Bilgileri
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Sağlık Bilgileri")
                            .font(.headline)
                        
                        // Aşılar
                        if let vaccinations = post.vaccinations, !vaccinations.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Aşılar")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                FlowLayout(spacing: 8) {
                                    ForEach(vaccinations, id: \.self) { vaccine in
                                        Text(vaccine)
                                            .font(.caption)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.purple.opacity(0.1))
                                            .foregroundColor(.purple)
                                            .cornerRadius(15)
                                    }
                                }
                            }
                        }
                        
                        // Durum Bilgileri
                        HStack(spacing: 16) {
                            StatusItem(
                                icon: "cross.case",
                                text: "Kısırlaştırma",
                                isActive: post.isNeutered
                            )
                            
                            StatusItem(
                                icon: "doc.text",
                                text: "Pasaport",
                                isActive: post.hasPassport
                            )
                            
                            StatusItem(
                                icon: "wave.3.right",
                                text: "Çip",
                                isActive: post.hasChip
                            )
                        }
                        
                        // Rahatsızlıklar
                        if let conditions = post.medicalConditions, !conditions.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Rahatsızlıklar")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                ForEach(conditions, id: \.self) { condition in
                                    Text("• \(condition)")
                                        .font(.callout)
                                }
                            }
                        }
                        
                        // İlaçlar
                        if let medications = post.medications, !medications.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("İlaçlar")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                ForEach(medications, id: \.self) { medication in
                                    Text("• \(medication)")
                                        .font(.callout)
                                }
                            }
                        }
                        
                        // Özel İhtiyaçlar
                        if let specialNeeds = post.specialNeeds {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Özel İhtiyaçlar")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text(specialNeeds)
                                    .font(.callout)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Açıklama
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Açıklama")
                            .font(.headline)
                        
                        Text(post.description)
                            .font(.body)
                    }
                    
                    Divider()
                    
                    // Konum
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Konum")
                            .font(.headline)
                        
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.red)
                            
                            Text("\(post.district), \(post.city)")
                                .font(.body)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // TODO: İletişime geç
                }) {
                    Text("İletişime Geç")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.purple)
                        .cornerRadius(20)
                }
            }
        }
        .fullScreenCover(isPresented: $showImageViewer) {
            ImageViewer(
                images: images.map { $0.url },
                initialIndex: selectedImageIndex,
                isPresented: $showImageViewer
            )
        }
        .fullScreenCover(isPresented: $showVideoPlayer) {
            if let videoURL = video?.url {
                VideoPlayer(player: AVPlayer(url: URL(string: videoURL)!))
                    .ignoresSafeArea()
                    .overlay(alignment: .topTrailing) {
                        Button(action: { showVideoPlayer = false }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .padding()
                        }
                    }
            }
        }
    }
}

struct InfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        Label(text, systemImage: icon)
            .font(.subheadline)
    }
}

struct AdoptionDetailStatusBadge: View {
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

struct StatusItem: View {
    let icon: String
    let text: String
    let isActive: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(isActive ? .green : .gray)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct VideoThumbnail: View {
    let url: String
    let action: () -> Void
    
    var body: some View {
        ZStack {
            AsyncImage(url: URL(string: url)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
            }
            
            Circle()
                .fill(Color.black.opacity(0.5))
                .frame(width: 60, height: 60)
                .overlay {
                    Image(systemName: "play.fill")
                        .font(.title)
                        .foregroundColor(.white)
                }
        }
        .onTapGesture(perform: action)
    }
}

struct ImageViewer: View {
    let images: [String]
    let initialIndex: Int
    @Binding var isPresented: Bool
    @State private var currentIndex: Int
    @GestureState private var dragOffset: CGSize = .zero
    
    init(images: [String], initialIndex: Int, isPresented: Binding<Bool>) {
        self.images = images
        self.initialIndex = initialIndex
        self._isPresented = isPresented
        self._currentIndex = State(initialValue: initialIndex)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            TabView(selection: $currentIndex) {
                ForEach(Array(images.enumerated()), id: \.element) { index, url in
                    AsyncImage(url: URL(string: url)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .tag(index)
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        // TODO: Zoom
                                    }
                            )
                    } placeholder: {
                        ProgressView()
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                Spacer()
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        return computeSize(rows: rows, proposal: proposal)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        placeViews(in: bounds, rows: rows)
    }
    
    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubviews.Element]] {
        var currentRow: [LayoutSubviews.Element] = []
        var rows: [[LayoutSubviews.Element]] = []
        var currentWidth: CGFloat = 0
        
        for view in subviews {
            let viewSize = view.sizeThatFits(.unspecified)
            if currentWidth + viewSize.width + spacing > (proposal.width ?? .infinity) {
                rows.append(currentRow)
                currentRow = [view]
                currentWidth = viewSize.width
            } else {
                currentRow.append(view)
                currentWidth += viewSize.width + spacing
            }
        }
        
        if !currentRow.isEmpty {
            rows.append(currentRow)
        }
        
        return rows
    }
    
    private func computeSize(rows: [[LayoutSubviews.Element]], proposal: ProposedViewSize) -> CGSize {
        var height: CGFloat = 0
        var width: CGFloat = 0
        
        for row in rows {
            var rowWidth: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for view in row {
                let viewSize = view.sizeThatFits(.unspecified)
                rowWidth += viewSize.width + spacing
                rowHeight = max(rowHeight, viewSize.height)
            }
            
            width = max(width, rowWidth)
            height += rowHeight + spacing
        }
        
        return CGSize(width: width - spacing, height: height - spacing)
    }
    
    private func placeViews(in bounds: CGRect, rows: [[LayoutSubviews.Element]]) {
        var y = bounds.minY
        
        for row in rows {
            var x = bounds.minX
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            
            for view in row {
                let viewSize = view.sizeThatFits(.unspecified)
                view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(viewSize))
                x += viewSize.width + spacing
            }
            
            y += rowHeight + spacing
        }
    }
} 