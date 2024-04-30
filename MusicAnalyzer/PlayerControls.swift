//
//  PlayerControls.swift
//  MusicAnalyzer
//
//  Created by Matkat Music LLC on 4/29/24.
//

import SwiftUI

struct PlayerControls: View {
    var musicPlayer: MusicPlayer
    
    var body: some View {
        Button(action: { musicPlayer.togglePlay(start: true)},
               label: {Text("Play")})
        Button(action: { musicPlayer.togglePlay(start: false)},
               label: { Text("Stop") })
    }
}

#Preview {
    var musicPlayer = MusicPlayer()
    return PlayerControls(musicPlayer: musicPlayer//,
//                          isPlaying: musicPlayer.$isPlaying
    )
}
