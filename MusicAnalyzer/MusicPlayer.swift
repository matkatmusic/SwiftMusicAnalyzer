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
    @Published var value: CGFloat = 0
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

func printBufferInfo(buffer: AVAudioPCMBuffer)
{
    print( "buffer info: format.channelCount \(buffer.format.channelCount)")
    print( "buffer info: frameLength       : \(buffer.frameLength)")
    print( "buffer info: frameCapacity     : \(buffer.frameCapacity)" )
    print( "buffer info: magnitude : \(AudioEngineManager.computeMagnitude(buffer: buffer, chan: 0))")
}

protocol AudioBufferListener: AnyObject
{
    func bufferDidChange(buffer: AVAudioPCMBuffer)
}

func copyBuffer(source: AVAudioPCMBuffer, destination: inout AVAudioPCMBuffer) 
{
//    printBufferInfo(buffer: source)

    var recreateDestination: Bool = false
    if( destination.format.channelCount != source.format.channelCount )
    {
        recreateDestination = true
    }
    else if( destination.frameLength != source.frameLength )
    {
        recreateDestination = true
    }
    else if( destination.frameCapacity != source.frameCapacity )
    {
        recreateDestination = true
    }
    
    if( recreateDestination )
    {
        print( "recreating destination to match sizes!!" )
        let format = AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatFloat32,
                                   sampleRate: source.format.sampleRate,
                                   channels: source.format.channelCount,
                                   interleaved: false)!
        
        let buffer = AVAudioPCMBuffer(pcmFormat: format,
                                         frameCapacity: source.frameCapacity)!
        
    
        buffer.frameLength = source.frameLength
        destination = buffer
    }
    
    
    guard let sourceData = source.floatChannelData,
          let destinationData = destination.floatChannelData else {
        return
    }


    let channels = Int(source.format.channelCount)
    let frames = Int(source.frameLength)

    for channel in 0..<channels {
        let sourceChannelData = sourceData[channel]
        let destinationChannelData = destinationData[channel]

        // Copy data from source buffer to destination buffer
        memcpy(destinationChannelData, 
               sourceChannelData,
               MemoryLayout<Float>.size * frames)
    }
    
//    printBufferInfo(buffer: destination)
}


class AudioBuffer: ObservableObject
{
    @Published var buffer: AVAudioPCMBuffer
    var listeners = [AudioBufferListener]()
    
    init(buffer: AVAudioPCMBuffer) {
        self.buffer = buffer
        printBufferInfo(buffer: buffer)
        printBufferInfo(buffer: self.buffer)
        print( "ok" )
    }
    
    func updateData(data: AVAudioPCMBuffer)
    {
        copyBuffer(source: data, destination: &self.buffer)

        /*
         When not passing data to this function and instead using self.buffer for each of the listeners being passed a buffer to process, the copy of the buffer is empty.
         When instead passing a copy of 'data' into notifyListeners,
         the copy is not empty.
         
         Something happens to 'self.buffer' between when notifyListeners is called, and when the forEach() call happens and I don't know what it is, but it is causing self.buffer to be empty.
         That tells me that the copy step above where samples are copied from 'data' into self.buffer's channels is erroneous.
         */
        notifyListeners()
    }
    
    func addListener(_ listener: AudioBufferListener) {
        listeners.append(listener)
    }

    func removeListener(_ listener: AudioBufferListener) {
        listeners = listeners.filter { $0 !== listener }
    }
    
    private func notifyListeners(/*data: AVAudioPCMBuffer*/)
    {
        listeners.forEach({ listener in
            var copy = self.buffer
            listener.bufferDidChange(buffer: copy)
        })
    }
}

struct Meter : View
{
    @ObservedObject var mag: Magnitude
    var body : some View {
        GeometryReader
        { geometry in
            let h = geometry.size.height
            let w = geometry.size.width
            let _ = print( "Mag: \(mag.value) ")
            Rectangle().frame(width: w,
                              height: h * mag.value)
            .foregroundColor(.yellow)
            .offset(y: (1 - mag.value) * h)
        }
        .background(.black)
    }
}

struct MusicPlayer: View {
    var body: some View {
        Text("Music Player")
        Meter(mag: magnitude)
            .frame(width: 100, height: 300)
    }
    
    @ObservedObject var magnitude: Magnitude
}

#Preview {
    let mag = Magnitude()
    return MusicPlayer(magnitude: mag)
}
