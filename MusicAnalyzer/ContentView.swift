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
    var leftRMSMeter: Meter
    var rightRMSMeter: Meter
    var leftPeakMeter: Meter
    var rightPeakMeter: Meter
    
    var analyzer: Analyzer
    var playerControls: PlayerControls
    
    var body: some View {
        return VStack {
            analyzer
            playerControls
//            leftRMSMeter.frame(height: 250)
            
            HStack{
                ZStack{
                    leftPeakMeter.frame(width: 100)
                    leftRMSMeter.frame(width: 75)
                }
                ZStack
                {
                    rightPeakMeter.frame(width: 100)
                    rightRMSMeter.frame(width: 75)
                }
            }.frame(height: 250)
        }
        .padding()
    }
    
    init(audioEngineManager: AudioEngineManager) {
        self.audioEngineManager = audioEngineManager
        analyzer = Analyzer()
        
        leftRMSMeter = Meter(mag: audioEngineManager.leftMagnitude, 
                             fillColor: Color.green)
        leftPeakMeter = Meter(mag: audioEngineManager.leftPeakValue,
                              fillColor: Color.blue)
        rightRMSMeter = Meter(mag: audioEngineManager.rightMagnitude,
                              fillColor: Color.green)
        rightPeakMeter = Meter(mag: audioEngineManager.rightPeakValue,
                               fillColor: Color.blue)
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
