//
//  AVAudioPCMBufferCircularBuffer.swift
//  MusicAnalyzer
//
//  Created by Matkat Music LLC on 5/6/24.
//

import Foundation

import AVFoundation

struct AVAudioPCMBufferCircularBuffer 
{
    private var array: [AVAudioPCMBuffer?]
    private var readIndex = 0
    private var writeIndex = 0
    private var isFull_ = false

    init(size: Int) 
    {
        array = Array(repeating: nil, count: size)
    }

    /*
     struct types are passed by value
     class types are passed by reference.
     Int and AVAudioFrameCount are struct types.
     */
    mutating func prepare(numChannels: Int, numSamples: AVAudioFrameCount)
    {
        for i in 0..<array.count 
        {
            /*
             The array owns optional instances of AVAudioPCMBuffers
             
             the constructor above puts 'nil' in every index in this array.
             
             The purpose of this 'prepare' function is to populate all elements in the array with actual instances of the PCMBuffers
             
             Each of these functions below, prior to the assignment, returns an optional.
             These returned values are force-unwrapped by appending '!' at the end of the function call.
             This turns the format and buffer into concrete objects and not optionals.
             */
            let format = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: AVAudioChannelCount(numChannels))!
            let buffer = AVAudioPCMBuffer(pcmFormat: format,
                                          frameCapacity: numSamples)!
            array[i] = buffer
        }
    }

    /*
     In swift, structs are value types and member functions of value types are non-mutating by default.  You must explicitly mark them as mutating if it is allowed to modify the struct's properties.
     */
    mutating func push(_ element: AVAudioPCMBuffer)
    {
        //overwrite whatever is at writeIndex in the array
        array[writeIndex] = element
        //increment the writeIndex and wrap
        writeIndex = (writeIndex + 1) % array.count
        if writeIndex == readIndex 
        {
            isFull_ = true
            //increment the read index.  This keeps the readindex in front of the write index, since the writeIndex has caught up to the read index
            readIndex = (readIndex + 1) % array.count
        }
    }

    mutating func pull(buffer: inout AVAudioPCMBuffer) -> Bool
    {
        if isEmpty { return false }
        
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
        
        /*
         the difference between the write index and read index can sometimes be a negative value.
         adding array.count to it and the performing modulo on the sum will produce an accurate count.  
         */
        return (writeIndex - readIndex + array.count) % array.count
    }
}
