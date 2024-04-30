//
//  MusicAnalyzerApp.swift
//  MusicAnalyzer
//
//  Created by Matkat Music LLC on 4/29/24.
//

import SwiftUI

@main
struct MusicAnalyzerApp: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView(musicPlayer: MusicPlayer())
        }
    }
}
