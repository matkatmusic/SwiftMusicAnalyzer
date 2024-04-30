//
//  MusicAnalyzerApp.swift
//  MusicAnalyzer
//
//  Created by Matkat Music LLC on 4/29/24.
//

import SwiftUI
import AVFAudio

@main
struct MusicAnalyzerApp: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView(musicPlayer: MusicPlayer())
        }
    }
    
    init()
    {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.playback)
        } catch {
            print("Setting category to AVAudioSessionCategoryPlayback failed.")
        }
    }
}
