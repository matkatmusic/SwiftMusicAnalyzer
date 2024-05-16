//
//  MusicAnalyzerApp.swift
//  MusicAnalyzer
//
//  Created by Matkat Music LLC on 4/29/24.
//

import SwiftUI
import AVFAudio

import Foundation

class Idea
{
    private var buffer: AudioBuffer = AudioBuffer(buffer: getBufferFromAudioSession(numChannels: nil, numSamples: nil))
    @ObservedObject var audioEngineManager: AudioEngineManager// = AudioEngineManager(buffer: buffer)
    init()
    {
        audioEngineManager = AudioEngineManager(buffer: self.buffer)
    }
}


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
    
    @ObservedObject var leftMagnitude = ObservedFloat()
    @ObservedObject var rightMagnitude = ObservedFloat()
    @ObservedObject var leftPeakValue = ObservedFloat()
    @ObservedObject var rightPeakValue = ObservedFloat()
    @ObservedObject var buffer: AudioBuffer

    init(buffer: AudioBuffer)
    {
        //member variables that aren't initialized when declared need to be initialized first before the parent class's initializer is called.
        self.buffer = buffer
        //if you need to perform more setup during initialization, init the super class then perform your additional setup
        super.init()
        setupAudioEngine()
    }

    //static class member functions must be called using the syntax:
    // ClassName.staticFunction.
    static func computeMagnitude(buffer: AVAudioPCMBuffer, chan: UInt32) -> CGFloat
    {
        /*
         creating an Array from an UnsafeBufferPointer<> makes that array refer to the same underlying data.
         this is how you can access the audio data inside an AVAUdioPCMBuffer for mutating.
         */
        let floatArray = Array(UnsafeBufferPointer(start: buffer.floatChannelData![Int(chan)],
                                                   count: Int(buffer.frameLength)))
        
        var sum: CGFloat = 0
        /*
         instead of writing for( int i = 0; i < floatArray.count; ++i )
         you write
            for i in 0 ..< floatArray.count
         in swift
         */
        for i in 0..<floatArray.count
        {
            sum += CGFloat(floatArray[i] * floatArray[i])
        }
        
        sum = sum / CGFloat(floatArray.count)
        let rms = sqrt(sum)
        
        return rms
    }
    
    static func computePeak(buffer: AVAudioPCMBuffer, chan: UInt32) -> CGFloat
    {
        let floatArray = Array(UnsafeBufferPointer(start: buffer.floatChannelData![Int(chan)],
                                                   count: Int(buffer.frameLength)))
        
        var peak: CGFloat = 0
        for i in 0..<floatArray.count
        {
            peak = max(peak,
                       abs(CGFloat(floatArray[i])))
        }
        
        return peak
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
                let leftRMS = AudioEngineManager.computeMagnitude(buffer: buffer, chan: 0)
                let rightRMS = AudioEngineManager.computeMagnitude(buffer: buffer, chan: 1)
                let leftPeak = AudioEngineManager.computePeak(buffer: buffer, chan: 0)
                let rightPeak = AudioEngineManager.computePeak(buffer: buffer, chan: 1)
                
                let bufferCopy = buffer
                
                /*
                 We don't know which thread the block will be called on.
                 Therefore, we force the update of the Observed objects to occur on the Main/Message thread by using a DispatchQueue's main object.
                 This requires copies of the buffer be passed around.
                 */
                DispatchQueue.main.async {
                    self.leftMagnitude.value = leftRMS
                    self.rightMagnitude.value = rightRMS
                    self.leftPeakValue.value = leftPeak
                    self.rightPeakValue.value = rightPeak
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

func getBufferFromAudioSession(numChannels: Int?, numSamples: Int?) -> AVAudioPCMBuffer
{
    let session = AVAudioSession.sharedInstance()
    do {
        try session.setCategory(AVAudioSession.Category.playback)
        try session.setActive(true)
    } catch {
        print("Setting category to AVAudioSessionCategoryPlayback failed.")
    }
    
    var numOutputs = 0
    if numChannels != nil
    {
        numOutputs = numChannels!
    }
    else
    {
        numOutputs = session.outputNumberOfChannels
    }
    
    var sampleCount = 0.0
    if numSamples != nil
    {
        sampleCount = Double(numSamples!)
    }
    else
    {
        sampleCount = session.ioBufferDuration * session.sampleRate * Double(numOutputs)
    }
    
    let format = AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatFloat32,
                               sampleRate: session.sampleRate,
                               channels: AVAudioChannelCount(numOutputs),
                               interleaved: false)!
    
    let buffer = AVAudioPCMBuffer(pcmFormat: format,
                                     frameCapacity: AVAudioFrameCount(sampleCount))!
    
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
    
    return buffer
}

@main
struct MusicAnalyzerApp: App {
    
    //a declaration of a 'body' variable with a closure
    //the closure returns a WindowGroup
    var body: some Scene {
        WindowGroup {
            //the windowGroup is initialized with a closure that returns a ContentView instance
            //because the closure has only one line in it, no return statement is needed.
            ContentView(audioEngineManager: audioEngineManager)
        }
    }
    
    @ObservedObject var audioEngineManager: AudioEngineManager
    
    init()
    {
        let buffer = getBufferFromAudioSession(numChannels: nil, numSamples: nil)

        printBufferInfo(buffer: buffer)
        
        let audioBuffer = AudioBuffer(buffer: buffer)
        /*
         Before the body is initialized, the audioEngineManager must be created
         the AEM needs an instance of an AudioBuffer in order to be constructed.
         we don't want the AudioBuffer to be a member variable, which means we have to delay the construction of it until this init() function is called.
         this is why we can't default-construct the AEM.
         Once the AEM exists, then the ContentView being created in the 'body' can be created. 
         */
        self.audioEngineManager = AudioEngineManager(buffer: audioBuffer)
    }
}
