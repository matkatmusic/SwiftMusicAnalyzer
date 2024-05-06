//
//  AudioBuffer.swift
//  MusicAnalyzer
//
//  Created by Matkat Music LLC on 5/4/24.
//

import Foundation

import AVFoundation

protocol AudioBufferListener: AnyObject
{
    func bufferDidChange(buffer: AVAudioPCMBuffer)
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
