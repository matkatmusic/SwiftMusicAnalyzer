//
//  PlayerControls.swift
//  MusicAnalyzer
//
//  Created by Matkat Music LLC on 4/29/24.
//

import SwiftUI
import AVFoundation

struct PlayerControls: View {
    var musicPlayer: AudioEngineManager
    
    var body: some View {
        Button(action: { musicPlayer.togglePlay(start: true)},
               label: {Text("Play")})
        Button(action: { musicPlayer.togglePlay(start: false)},
               label: { Text("Stop") })
    }
}

#Preview {
    let session = AVAudioSession.sharedInstance()
    
    let numOutputs = session.outputNumberOfChannels
    let numSamples = session.ioBufferDuration * session.sampleRate
    
    let format = AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatFloat32,
                               sampleRate: session.sampleRate,
                               channels: AVAudioChannelCount(numOutputs),
                               interleaved: false)!
    
    let buffer = AVAudioPCMBuffer(pcmFormat: format,
                                     frameCapacity: AVAudioFrameCount(numSamples))!
//    
    let audioBuffer = AudioBuffer(buffer: buffer)
    
    let audioEngineManager = AudioEngineManager(buffer: audioBuffer)
    return PlayerControls(musicPlayer: audioEngineManager)
}
