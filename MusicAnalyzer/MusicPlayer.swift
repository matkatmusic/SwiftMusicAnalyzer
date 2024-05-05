//
//  MusicPlayer.swift
//  MusicAnalyzer
//
//  Created by Matkat Music LLC on 4/29/24.
//

import SwiftUI

import AVFoundation



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



//struct MusicPlayer: View {
//    var body: some View {
//        Text("Music Player")
//        Meter(mag: magnitude)
//            .frame(width: 100, height: 300)
//    }
//    
//    @ObservedObject var magnitude: ObservedFloat
//}

