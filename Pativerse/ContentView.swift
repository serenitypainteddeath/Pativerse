//
//  ContentView.swift
//  Pativerse
//
//  Created by Erdem on 5.01.2025.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var currentSlideIndex = 0
    let slides = ["slide1", "slide2", "slide3"] // Slider görselleri

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Pativerse")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.purple)
                        
                        Spacer()
                        
                        NavigationLink(destination: ProfileView()) {
                            ProfileAvatar()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Slider
                    TabView(selection: $currentSlideIndex) {
                        ForEach(0..<slides.count, id: \.self) { index in
                            SliderCard()
                                .tag(index)
                        }
                    }
                    .frame(height: 200)
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                    .padding(.vertical)
                    
                    // Main Menu Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 20) {
                        MainMenuCard(title: "Sahiplen", 
                                   icon: "heart.fill",
                                   color: .pink,
                                   destination: AnyView(AdoptionListView()))
                        
                        MainMenuCard(title: "Veteriner",
                                   icon: "cross.case.fill",
                                   color: .blue,
                                   destination: AnyView(VeterinaryListView()))
                        
                        MainMenuCard(title: "Hayvanlarım",
                                   icon: "pawprint.fill",
                                   color: .purple,
                                   destination: AnyView(MyPetsView()))
                        
                        MainMenuCard(title: "PetShop",
                                   icon: "cart.fill",
                                   color: .orange,
                                   destination: AnyView(PetShopView()))
                    }
                    .padding()
                }
            }
            .background(Color(.systemGray6))
        }
    }
}
/*
// MARK: - Tab Views
struct AdoptionView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    SearchBar()
                    
                    CategoryScrollView()
                    
                    AdoptionCardList()
                }
                .padding()
            }
            .navigationTitle("Sahiplendir")
        }
    }
}
*/
struct VeterinaryView: View {
    var body: some View {
        NavigationView {
            Text("Veteriner View")
                .navigationTitle("Veterinerler")
        }
    }
}

struct MyPetsView: View {
    var body: some View {
        NavigationView {
            Text("My Pets View")
                .navigationTitle("Hayvanlarım")
        }
    }
}

struct PetShopView: View {
    var body: some View {
        NavigationView {
            Text("Pet Shop View")
                .navigationTitle("PetShop")
        }
    }
}

// MARK: - Custom Components
struct SearchBar: View {
    @State private var searchText = ""
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Ara...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
}

struct CategoryScrollView: View {
    let categories = ["Kedi", "Köpek", "Kuş", "Balık", "Hamster", "Diğer"]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(categories, id: \.self) { category in
                    CategoryButton(title: category)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct CategoryButton: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.system(.subheadline, design: .rounded, weight: .medium))
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.purple.opacity(0.1))
            .foregroundColor(.purple)
            .cornerRadius(20)
    }
}
/*
struct AdoptionCardList: View {
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            ForEach(0..<10) { _ in
                AdoptionCard()
            }
        }
    }
}
*/
/*
struct AdoptionCard: View {
    var body: some View {
        VStack(alignment: .leading) {
            Image("pet_placeholder")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 150)
                .clipped()
                .cornerRadius(15)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Pamuk")
                    .font(.system(.headline, design: .rounded))
                
                Text("2 yaşında • Ankara")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}
*/
struct ProfileAvatar: View {
    var body: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .frame(width: 40, height: 40)
            .foregroundColor(.purple)
            .background(Circle().fill(.white))
            .overlay(Circle().stroke(Color.purple, lineWidth: 2))
    }
}

struct SliderCard: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [.purple, .blue]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            
            VStack {
                Text("Evcil Hayvan Dostunu Bul")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Binlerce evcil hayvan seni bekliyor")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal)
    }
}

struct MainMenuCard: View {
    let title: String
    let icon: String
    let color: Color
    let destination: AnyView
    
    var body: some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 15) {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 30))
                            .foregroundColor(color)
                    )
                
                Text(title)
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
}

struct ProfileView: View {
    var body: some View {
        Text("Profil Sayfası")
            .navigationTitle("Profil")
    }
}
/*
#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
*/

