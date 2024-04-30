//
//  MusicPlayer.swift
//  MusicAnalyzer
//
//  Created by Matkat Music LLC on 4/29/24.
//

import SwiftUI

import AVFoundation

struct MusicPlayer: View {
    var body: some View {
        Text("Music Player")
            .onAppear()
            {
                self.loadFile()
//                self.audioPlayer?.play()
            }
    }
    
    func togglePlay(start: Bool)
    {
        if( start )
        {
            self.audioPlayer?.play()
            print("Playing")
        }
        else
        {
            self.audioPlayer?.stop()
            print( "Stopping" )
        }
    }
    
    @State private var audioPlayer: AVAudioPlayer?
    
    func loadFile()
    {
        let sound = Bundle.main.path(forResource: "Know Myself - Patrick Patrikios", 
                                     ofType: "mp3")
        guard let url = sound else
        {
            print("MP3 not found")
            return
        }
        
        let mp3URL = URL(fileURLWithPath: url)
        
        do {
            let player = try AVAudioPlayer(contentsOf: mp3URL)
            audioPlayer = player
            
            if( audioPlayer? .prepareToPlay() == true )
            {
                print( "Ready to play!" )
            }
        }
        catch{
            print( "Error playing audio: \(error.localizedDescription)" )
        }
    }
}

#Preview {
    MusicPlayer()
}
