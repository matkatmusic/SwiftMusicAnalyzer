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
    
    /*
     None of these member variables are initialized
     this means either an init() function must be used, or they must be passed as constructor arguments when a ContentView is created.
     */
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
            
            HStack{ //a horizontal stack of two Z-order stacks.
                ZStack{ //Z-order stack.  items closer to the top are further back in the z-order
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
    
    init(audioEngineManager: AudioEngineManager) 
    {
        self.audioEngineManager = audioEngineManager
        analyzer = Analyzer()
        /*
         the binManager lives in the analyzer
         it is default-constructed, but not prepared.
         prepare must be manually called after the object has been constructed
         */
        analyzer.binManager.prepare(bufferSize: 1024)
        
        leftRMSMeter = Meter(mag: audioEngineManager.leftMagnitude, 
                             fillColor: Color.green)
        leftPeakMeter = Meter(mag: audioEngineManager.leftPeakValue,
                              fillColor: Color.blue)
        rightRMSMeter = Meter(mag: audioEngineManager.rightMagnitude,
                              fillColor: Color.green)
        rightPeakMeter = Meter(mag: audioEngineManager.rightPeakValue,
                               fillColor: Color.blue)
        
        /*
         because the PlayerControls class does not have an init function, the constructor argument here is actually the name of the member variable that needs initialization in this class. 
         */
        playerControls = PlayerControls(musicPlayer: audioEngineManager)
        
        /*
         by telling the binManager to listen to the buffer, the binManager can be notified whenever the contents of the buffer changes, and thus process the changed buffer accordingly.
         */
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
