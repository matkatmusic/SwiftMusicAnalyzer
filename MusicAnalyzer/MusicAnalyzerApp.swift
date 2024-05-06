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

struct AVAudioPCMBufferCircularBuffer {
    private var array: [AVAudioPCMBuffer?]
    private var readIndex = 0
    private var writeIndex = 0
    private var isFull_ = false

    init(size: Int) {
        array = Array(repeating: nil, count: size)
    }

    mutating func prepare(numChannels: Int, numSamples: AVAudioFrameCount) {
        for i in 0..<array.count {
            let format = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: AVAudioChannelCount(numChannels))!
            let buffer = AVAudioPCMBuffer(pcmFormat: format, 
                                          frameCapacity: numSamples)!
            array[i] = buffer
        }
    }

    mutating func push(_ element: AVAudioPCMBuffer) {
        array[writeIndex] = element
        writeIndex = (writeIndex + 1) % array.count
        if writeIndex == readIndex {
            isFull_ = true
            readIndex = (readIndex + 1) % array.count
        }
    }

    mutating func pull(buffer: inout AVAudioPCMBuffer) -> Bool
    {
        guard !isEmpty else { return false }
        
        buffer = array[readIndex]!
        readIndex = (readIndex + 1) % array.count
        isFull_ = false
        return true
    }

    var isEmpty: Bool {
        return !isFull_ && readIndex == writeIndex
    }

    var isFull: Bool {
        return isFull_
    }

    var count: Int {
        if isFull_ {
            return array.count
        }
        
        return (writeIndex - readIndex + array.count) % array.count
    }
}


enum Channel: Int
{
    case Left = 0
    case Right = 1
}

//a non-atomic port of the SimpleMBComp's SingleChannelSampleFifo
class SingleChannelSampleFifo
{
    private var channelToUse: Channel
    
    init(channel: Channel) 
    {
        self.channelToUse = channel
    }
    
    private var fifoIndex: Int = 0
    
    private var audioBufferFifo = AVAudioPCMBufferCircularBuffer(size: 50)
    private var bufferToFill = AVAudioPCMBuffer()
    private var prepared = false
    private var size: Int = 0
    
    func prepare(bufferSize: Int )
    {
        prepared = false
        size = bufferSize
        
        bufferToFill = getBufferFromAudioSession(numChannels: 1, numSamples: bufferSize)
        
        audioBufferFifo.prepare(numChannels: 1,
                                numSamples: AVAudioFrameCount(bufferSize))
        fifoIndex = 0
        prepared = true
    }
    
    func update(buffer: AVAudioPCMBuffer)
    {
        assert(prepared == true)
        assert(buffer.format.channelCount > channelToUse.rawValue )
        
        let data = buffer.floatChannelData![channelToUse.rawValue]
        let numSamples = buffer.frameLength
        
        for i in 0 ..< numSamples
        {
            pushNextSampleIntoFifo(sample: data[ Int(i) ] )
        }
    }
    
//    int getNumCompleteBuffersAvailable() const { return audioBufferFifo.getNumAvailableForReading(); }
    func getNumCompleteBuffersAvailable() -> Int
    {
        return audioBufferFifo.count
    }
//    bool isPrepared() const { return prepared.get(); }
    func isPrepared() -> Bool { return prepared }
//    int getSize() const { return size.get(); }
    func getSize() -> Int { return size }
    //==============================================================================
//    bool getAudioBuffer(BlockType& buf) { return audioBufferFifo.pull(buf); }
    func getAudioBuffer(buf: inout AVAudioPCMBuffer) -> Bool
    {
        return audioBufferFifo.pull(buffer: &buf)
    }

    private func pushNextSampleIntoFifo(sample: Float)
    {
//        if (fifoIndex == bufferToFill.getNumSamples())
        if( fifoIndex == bufferToFill.frameLength )
        {
//            print("SCSF bufferToFill has been filled!" )
//            printBufferInfo(buffer: bufferToFill)
            audioBufferFifo.push(bufferToFill);
//
//            juce::ignoreUnused(ok);
//            assert( ok )
//
            fifoIndex = 0;
        }
//        
//        bufferToFill.setSample(0, fifoIndex, sample);
        bufferToFill.floatChannelData![0][fifoIndex] = sample
        fifoIndex += 1;
    }
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
//                self.buffer = buffer
                
//                var avgRMS = 0.0
//                for ch in 0 ..< buffer.format.channelCount
//                {
//                    let rms = AudioEngineManager.computeMagnitude(buffer: buffer, chan: ch)
//                    avgRMS += rms
//                }
//                
//                avgRMS /= Double(buffer.format.channelCount)
                
                let leftRMS = AudioEngineManager.computeMagnitude(buffer: buffer, chan: 0)
                let rightRMS = AudioEngineManager.computeMagnitude(buffer: buffer, chan: 1)
                let leftPeak = AudioEngineManager.computePeak(buffer: buffer, chan: 0)
                let rightPeak = AudioEngineManager.computePeak(buffer: buffer, chan: 1)
                
                let bufferCopy = buffer
                
                DispatchQueue.main.async {
                    self.leftMagnitude.value = leftRMS
                    self.rightMagnitude.value = rightRMS
                    self.leftPeakValue.value = leftPeak
                    self.rightPeakValue.value = rightPeak
//                    printMemoryAddress(self.buffer.buffer, message: "MusicPlayer::createConnections::installTap")
                    //copy data to buffer
//                    printMemoryAddress(bufferCopy, message: "DispatchQueue.main.async")
//                    printMemoryAddress(self.buffer.buffer, message: "DispatchQueue.main.async")
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
    
    var body: some Scene {
        WindowGroup {
            ContentView(audioEngineManager: audioEngineManager)
        }
    }
    
    @ObservedObject var audioEngineManager: AudioEngineManager
    
    init()
    {
        var buffer = getBufferFromAudioSession(numChannels: nil, numSamples: nil)

        printBufferInfo(buffer: buffer)
        
        let audioBuffer = AudioBuffer(buffer: buffer)
        self.audioEngineManager = AudioEngineManager(buffer: audioBuffer)
    }
}
