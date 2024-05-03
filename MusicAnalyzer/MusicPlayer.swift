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

class Magnitude: ObservableObject {
    @Published var magnitude: CGFloat = 0
    {
        didSet
        {
//            print( "Magnitude: \(magnitude)" )
        }
    }
}

class Magnitudes: ObservableObject
{
    @Published var mags: [CGFloat] = []
}

class Buffer: ObservableObject {
    @Published var buffer: AVAudioPCMBuffer?
    {
        didSet
        {
            if buffer == nil
            {
                print ("buffer is nil")
            }
            else
            {
                print ("buffer updated")
            }
        }
    }
}

protocol AudioBufferListener: AnyObject
{
    func bufferDidChange(buffer: inout AVAudioPCMBuffer)
}

class AudioBuffer: ObservableObject
{
    @Published var buffer: AVAudioPCMBuffer
    var listeners = [AudioBufferListener]()
    
    init(buffer: AVAudioPCMBuffer) {
        self.buffer = buffer
    }
    
    func updateData(data: AVAudioPCMBuffer)
    {
        var changed = false
        for frame in 0..<Int(data.frameLength)
        {
            for channel in 0..<data.format.channelCount
            {
                if( channel < (self.buffer.format.channelCount) )
                {
                    if( frame < self.buffer.frameCapacity )
                    {
                        self.buffer.floatChannelData![Int(channel)][frame] = data.floatChannelData![Int(channel)][frame]
                        changed = true
                    }
                }
            }
        }
        
        if changed
        {
            notifyListeners()
        }
    }
    
    func addListener(_ listener: AudioBufferListener) {
        listeners.append(listener)
    }

    func removeListener(_ listener: AudioBufferListener) {
        listeners = listeners.filter { $0 !== listener }
    }
    
    private func notifyListeners()
    {
        listeners.forEach({ listener in
            listener.bufferDidChange(buffer: &self.buffer)
        })
    }
}

struct Meter : View
{
    @Binding var mag: CGFloat
    var body : some View {
        GeometryReader
        { geometry in
            let h = geometry.size.height
            let w = geometry.size.width
            Rectangle().frame(width: w,
                              height: h * mag)
            .foregroundColor(.yellow)
            .offset(y: (1 - mag) * h)
        }
        .background(.black)
    }
}

struct MusicPlayer: View {
    var body: some View {
        Text("Music Player")
        Meter(mag: $magnitude.magnitude)
            .frame(width: 100, height: 300)
    }
    
//    func togglePlay(start: Bool)
//    {
//        if( start )
//        {
//            play()
//        }
//        else
//        {
//            audioPlayerNode.stop()
//            removeConnections()
//            
//            audioEngine.stop()
//            print( "Stopping" )
//        }
//    }
//    
//    func play()
//    {
//        if( audioEngine.isRunning == false )
//        {
//            createConnections()
//        }
//        
//        if( audioFileLoader.audioFile == nil )
//        {
//            audioFileLoader.loadFile()
//        }
//         
//        audioPlayerNode.scheduleFile(audioFileLoader.audioFile!, at: nil, completionHandler: nil)
//        audioPlayerNode.play()
//        print( "Playing" )
//    }
    
//    @State private var audioEngine: AVAudioEngine = AVAudioEngine()
//    @State private var audioPlayerNode: AVAudioPlayerNode = AVAudioPlayerNode()
//    @ObservedObject var audioFileLoader = AudioFileLoader()
//    @State private var mixer: AVAudioMixerNode = AVAudioMixerNode()
    
    @ObservedObject var magnitude = Magnitude()
    @ObservedObject var buffer: AudioBuffer
    
    
//    func removeConnections()
//    {
//        audioEngine.disconnectNodeOutput(audioPlayerNode)
//        audioEngine.disconnectNodeOutput(mixer)
//        audioEngine.disconnectNodeOutput(audioEngine.outputNode)
//        
//        audioPlayerNode.removeTap(onBus: 0)
//    }
//    
//    func createConnections()
//    {
//        do
//        {
//            audioEngine.attach(mixer)
//            audioEngine.connect(mixer, to: audioEngine.outputNode, format: nil)
//            try audioEngine.start()
//            
//            audioEngine.attach(audioPlayerNode)
//            audioEngine.connect(audioPlayerNode, to: mixer, format: nil)
//            audioPlayerNode.installTap(onBus: 0, bufferSize: 512, format: nil, block: {
//                buffer, time in
////                self.buffer = buffer
//                let floatArray = Array(UnsafeBufferPointer(start: buffer.floatChannelData![0], 
//                                                           count: Int(buffer.frameLength)))
//                
//                var sum: CGFloat = 0
//                for i in 0..<floatArray.count
//                {
//                    sum += CGFloat(floatArray[i] * floatArray[i])
//                }
//                
//                sum = sum / CGFloat(floatArray.count)
//                let rms = sqrt(sum)
//                
//                DispatchQueue.main.async {
//                    self.magnitude.magnitude = rms
////                    print( "Magnitude: \(rms)" )
//                    printMemoryAddress(self.buffer.buffer, message: "MusicPlayer::createConnections::installTap")
//                    //copy data to buffer
//                    self.buffer.updateData(data: buffer)
////                    for frame in 0..<Int(buffer.frameLength)
////                    {
////                        for channel in 0..<buffer.format.channelCount
////                        {
////                            if( channel < (self.buffer.buffer?.format.channelCount)! )
////                            {
////                                if( frame < self.buffer.buffer!.frameCapacity )
////                                {
////                                    self.buffer.buffer?.floatChannelData![Int(channel)][frame] = buffer.floatChannelData![Int(channel)][frame]
////                                }
////                            }
////                        }
////                    }
//                    
////                    self.buffer.buffer = AVAudioPCMBuffer(pcmFormat: buffer.format, frameCapacity: buffer.frameCapacity)
////                    self.buffer.buffer?.frameLength = buffer.frameLength
////                    let floatArray = Array(UnsafeBufferPointer(start: buffer.floatChannelData![0], count: Int(buffer.frameLength)))
////                    var floatArray2 = Array(UnsafeBufferPointer(start: self.buffer.buffer!.floatChannelData![0], count: Int(buffer.frameLength)))
////                    for i in 0..<floatArray.count
////                    {
////                        floatArray2[i] = floatArray[i]
////                    }
//                    
////                    self.buffer.buffer = buffer
//                }
//            })
//        }
//        catch
//        {
//            print( "Error configuring connections: \(error.localizedDescription)" )
//        }
//    }
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
    
    let audioBuffer = AudioBuffer(buffer: buffer)
    return MusicPlayer(buffer: audioBuffer)
}
