//
//  AudioFileLoader.swift
//  MusicAnalyzer
//
//  Created by Matkat Music LLC on 5/4/24.
//

import Foundation

import AVFoundation

class AudioFileLoader: ObservableObject {
    @Published var audioFile: AVAudioFile?

    func loadFile() {
        //Bundle is the location of this app's .app file on disk
        //main is the folder where the executable is stored.
        //path returns an optional string, which is why 'guard' is used below
        let sound = Bundle.main.path(forResource: "Know Myself - Patrick Patrikios", ofType: "mp3")
        //if sound is nil, print an error message and return
        guard let url = sound else {
            print("MP3 not found")
            return
        }

        let mp3URL = URL(fileURLWithPath: url)

        /*
         In swift, 'try-catch' blocks are written as:
         do {
            try something
         } catch {
            error is implicitly provided in the catch{} block
         }
         */
        do {
            let file = try AVAudioFile(forReading: mp3URL)
            audioFile = file
        } catch {
            print("Error loading audio file: \(error.localizedDescription)")
        }
    }
}
