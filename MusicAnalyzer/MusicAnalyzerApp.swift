//
//  MusicAnalyzerApp.swift
//  MusicAnalyzer
//
//  Created by Matkat Music LLC on 4/29/24.
//

import SwiftUI
import AVFAudio

import Foundation

func printMemoryAddress<T>(_ object: T, message: String)
{
    let unmanaged = Unmanaged.passUnretained(object as AnyObject)
    let pointer = unmanaged.toOpaque()
    let address = UInt(bitPattern: pointer)
    
    print("caller: [\(message)] Memory address of \(type(of: object)) instance: \(address)")
}

class AudioEngineManager: NSObject, ObservableObject {
    @State private var audioEngine: AVAudioEngine = AVAudioEngine()
    @State private var audioPlayerNode: AVAudioPlayerNode = AVAudioPlayerNode()
    @ObservedObject var audioFileLoader = AudioFileLoader()
    @State private var mixer: AVAudioMixerNode = AVAudioMixerNode()
    
    @ObservedObject var magnitude = Magnitude()
    @ObservedObject var buffer: AudioBuffer

    init(buffer: AudioBuffer)
    {
        self.buffer = buffer
        super.init()
        setupAudioEngine()
    }

    static func computeMagnitude(buffer: AVAudioPCMBuffer, chan: UInt32) -> CGFloat
    {
        let floatArray = Array(UnsafeBufferPointer(start: buffer.floatChannelData![Int(chan)],
                                                   count: Int(buffer.frameLength)))
        
        var sum: CGFloat = 0
        for i in 0..<floatArray.count
        {
            sum += CGFloat(floatArray[i] * floatArray[i])
        }
        
        sum = sum / CGFloat(floatArray.count)
        let rms = sqrt(sum)
        
        return rms
    }
    
    func setupAudioEngine()
    {
        do
        {
            audioEngine.attach(mixer)
            audioEngine.connect(mixer, to: audioEngine.outputNode, format: nil)
            try audioEngine.start()
            
            audioEngine.attach(audioPlayerNode)
            audioEngine.connect(audioPlayerNode, to: mixer, format: nil)
            audioPlayerNode.installTap(onBus: 0, 
                                       bufferSize: 512,
                                       format: nil,
                                       block: { buffer, time in
//                self.buffer = buffer
                
                var avgRMS = 0.0
                for ch in 0 ..< buffer.format.channelCount
                {
                    let rms = AudioEngineManager.computeMagnitude(buffer: buffer, chan: ch)
                    avgRMS += rms
                }
                
                avgRMS /= Double(buffer.format.channelCount)
                
                let bufferCopy = buffer
                
                DispatchQueue.main.async {
                    self.magnitude.magnitude = avgRMS
//                    printMemoryAddress(self.buffer.buffer, message: "MusicPlayer::createConnections::installTap")
                    //copy data to buffer
                    
                    
                    printMemoryAddress(bufferCopy, message: "DispatchQueue.main.async")
                    printMemoryAddress(self.buffer.buffer, message: "DispatchQueue.main.async")
                    self.buffer.updateData(data: bufferCopy)
                }
            })
            
            
        }
        catch
        {
            print( "Error configuring connections: \(error.localizedDescription)" )
        }
    }


    func stopAudioEngine() 
    {
        audioEngine.disconnectNodeOutput(audioPlayerNode)
        audioEngine.disconnectNodeOutput(mixer)
        audioEngine.disconnectNodeOutput(audioEngine.outputNode)
        
        audioPlayerNode.removeTap(onBus: 0)
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
            stopAudioEngine()
            
            print( "Stopping" )
        }
    }
    
    func play()
    {
        if( audioEngine.isRunning == false )
        {
            setupAudioEngine()
        }
        
        if( audioFileLoader.audioFile == nil )
        {
            audioFileLoader.loadFile()
        }
         
        audioPlayerNode.scheduleFile(audioFileLoader.audioFile!, at: nil, completionHandler: nil)
        audioPlayerNode.play()
        print( "Playing" )
    }
}

@main
struct MusicAnalyzerApp: App {
    
    var body: some Scene {
        WindowGroup {
//            let musicPlayer = MusicPlayer()
//            let analyzer = Analyzer(buffer: musicPlayer.buffer)
//            ContentView(musicPlayer: musicPlayer, analyzer: analyzer)
            ContentView(audioEngineManager: audioEngineManager)
        }
    }
    
    @ObservedObject var audioEngineManager: AudioEngineManager
    
    init()
    {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSession.Category.playback)
            try session.setActive(true)
        } catch {
            print("Setting category to AVAudioSessionCategoryPlayback failed.")
        }
        
        let numOutputs = session.outputNumberOfChannels
        let numSamples = session.ioBufferDuration * session.sampleRate * Double(numOutputs)
        
        let format = AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatFloat32,
                                   sampleRate: session.sampleRate,
                                   channels: AVAudioChannelCount(numOutputs),
                                   interleaved: false)!
        
        let buffer = AVAudioPCMBuffer(pcmFormat: format,
                                         frameCapacity: AVAudioFrameCount(numSamples))!
        
        let channels = buffer.format.channelCount
        let frameLength = buffer.frameCapacity

        // Accessing the float channel data
        guard let floatChannelData = buffer.floatChannelData else {
            fatalError("Failed to access float channel data.")
        }

        // Fill the buffer with dummy audio data
        for channel in 0..<channels {
            for frame in 0..<Int(frameLength) {
                floatChannelData[Int(channel)][frame] = 0.0
            }
        }

        // Set the frame length to indicate valid audio samples
        buffer.frameLength = frameLength

        
        printBufferInfo(buffer: buffer)
        
        let audioBuffer = AudioBuffer(buffer: buffer)
        self.audioEngineManager = AudioEngineManager(buffer: audioBuffer)
    }
}
