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
            print( "Magnitude: \(magnitude)" )
        }
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
    
    @State private var buffer: AVAudioPCMBuffer = AVAudioPCMBuffer()
    {
        didSet
        {
//            print( "Buffer: \(buffer.frameLength)" )
        }
    }
    
    @ObservedObject var magnitude = Magnitude()
    
    
    func removeConnections()
    {
        audioPlayerNode.removeTap(onBus: 0)
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
            audioPlayerNode.installTap(onBus: 0, bufferSize: 512, format: nil, block: {
                buffer, time in
//                self.buffer = buffer
                let floatArray = Array(UnsafeBufferPointer(start: buffer.floatChannelData![0], 
                                                           count: Int(buffer.frameLength)))
                
                var sum: CGFloat = 0
                for i in 0..<floatArray.count
                {
                    sum += CGFloat(floatArray[i] * floatArray[i])
                }
                
                sum = sum / CGFloat(floatArray.count)
                let rms = sqrt(sum)
                
                DispatchQueue.main.async {
                    self.magnitude.magnitude = rms
//                    print( "Magnitude: \(rms)" )
                    self.buffer = buffer
                }
            })
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
