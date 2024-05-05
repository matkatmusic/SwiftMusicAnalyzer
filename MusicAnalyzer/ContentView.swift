//
//  ContentView.swift
//  MusicAnalyzer
//
//  Created by Matkat Music LLC on 4/29/24.
//

import SwiftUI
import AVFAudio

struct ContentView: View {
    @ObservedObject var audioEngineManager: AudioEngineManager
    
//    var musicPlayer: MusicPlayer
    var meter: Meter
    var analyzer: Analyzer
    var playerControls: PlayerControls
    
    var body: some View {
        return VStack {
            analyzer
            playerControls
            meter.frame(height: 250)
        }
        .padding()
    }
    
    init(audioEngineManager: AudioEngineManager) {
        self.audioEngineManager = audioEngineManager
        analyzer = Analyzer()
        
//        meter = MusicPlayer(buffer: audioEngineManager.buffer)
        meter = Meter(mag: audioEngineManager.$magnitude.magnitude)
        playerControls = PlayerControls(musicPlayer: audioEngineManager)
        
        self.audioEngineManager.buffer.addListener(analyzer.binManager)
    }
}

#Preview {
    let numOutputs = 2
    let numSamples = 1024
    
    let format = AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatFloat32,
                               sampleRate: 48000,
                               channels: AVAudioChannelCount(numOutputs),
                               interleaved: false)!
    
    let buffer = AVAudioPCMBuffer(pcmFormat: format,
                                     frameCapacity: AVAudioFrameCount(numSamples))!
    
    let audioBuffer = AudioBuffer(buffer: buffer)
    let aem = AudioEngineManager(buffer: audioBuffer)
    return ContentView(audioEngineManager: aem)
}
