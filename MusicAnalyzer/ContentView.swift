//
//  ContentView.swift
//  MusicAnalyzer
//
//  Created by Matkat Music LLC on 4/29/24.
//

import SwiftUI

struct ContentView: View {
    var musicPlayer: MusicPlayer
    var body: some View {
        VStack {
            Analyzer()
            PlayerControls(musicPlayer: musicPlayer).frame(height: 100)
            musicPlayer.frame(height: 250)
        }
        .padding()
    }
}

#Preview {
    ContentView(musicPlayer: MusicPlayer())
}
