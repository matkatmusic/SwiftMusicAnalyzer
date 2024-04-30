//
//  MusicPlayer.swift
//  MusicAnalyzer
//
//  Created by Matkat Music LLC on 4/29/24.
//

import SwiftUI

import AVFoundation

class AudioFileLoader: ObservableObject {
    @Published var audioFile: AVAudioFile?

    func loadFile() {
        let sound = Bundle.main.path(forResource: "Know Myself - Patrick Patrikios", ofType: "mp3")
        guard let url = sound else {
            print("MP3 not found")
            return
        }

        let mp3URL = URL(fileURLWithPath: url)

        do {
            let file = try AVAudioFile(forReading: mp3URL)
            audioFile = file
        } catch {
            print("Error loading audio file: \(error.localizedDescription)")
        }
    }
}

struct MusicPlayer: View {
    var body: some View {
        Text("Music Player")
    }
    
    func togglePlay(start: Bool)
    {
        if( start )
        {
            play()
        }
        else
        {
            audioPlayerNode.stop()
            audioEngine.stop()
            removeConnections()
            print( "Stopping" )
        }
    }
    
    func play()
    {
        if( audioEngine.isRunning == false )
        {
            createConnections()
        }
        
        if( audioFileLoader.audioFile == nil )
        {
            audioFileLoader.loadFile()
        }
         
        audioPlayerNode.scheduleFile(audioFileLoader.audioFile!, at: nil, completionHandler: nil)
        audioPlayerNode.play()
        print( "Playing" )
    }
    
    @State private var audioEngine: AVAudioEngine = AVAudioEngine()
    @State private var audioPlayerNode: AVAudioPlayerNode = AVAudioPlayerNode()
    @ObservedObject var audioFileLoader = AudioFileLoader()
    @State private var mixer: AVAudioMixerNode = AVAudioMixerNode()
    
    @State private var buffer: AVAudioPCMBuffer?
    {
        didSet
        {
            if let buffer = buffer
            {
                print( "Buffer: \(buffer.frameLength)" )
            }
        }
    }
    
    func removeConnections()
    {
        audioEngine.disconnectNodeOutput(audioPlayerNode)
        audioEngine.disconnectNodeOutput(mixer)
        audioEngine.disconnectNodeOutput(audioEngine.outputNode)
    }
    
    func createConnections()
    {
        do
        {
            audioEngine.attach(mixer)
            audioEngine.connect(mixer, to: audioEngine.outputNode, format: nil)
            try audioEngine.start()
            
            audioEngine.attach(audioPlayerNode)
            audioEngine.connect(audioPlayerNode, to: mixer, format: nil)
        }
        catch
        {
            print( "Error configuring connections: \(error.localizedDescription)" )
        }
    }
}

#Preview {
    MusicPlayer()
}
