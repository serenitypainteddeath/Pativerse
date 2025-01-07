//
//  PativerseApp.swift
//  Pativerse
//
//  Created by Erdem on 5.01.2025.
//

import SwiftUI

@main
struct PativerseApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                MainTabView()
                    .environmentObject(authViewModel)
            } else {
                AuthView()
                    .environmentObject(authViewModel)
            }
        }
    }
}
