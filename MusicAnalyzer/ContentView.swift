//
//  ContentView.swift
//  MusicAnalyzer
//
//  Created by Matkat Music LLC on 4/29/24.
//

import SwiftUI
import AVFAudio

struct ContentView: View {
    var musicPlayer: MusicPlayer
    var body: some View {
        VStack {
            Analyzer(magnitudes: [0.3, 0.5, 0.8])//.frame(height:200)
            PlayerControls(musicPlayer: musicPlayer)//.frame(height: 100)
            musicPlayer.frame(height: 250)
        }
        .padding()
    }
}

#Preview {
    ContentView(musicPlayer: MusicPlayer())
}
