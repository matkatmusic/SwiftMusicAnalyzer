//
//  SingleChannelSampleFifo.swift
//  MusicAnalyzer
//
//  Created by Matkat Music LLC on 5/6/24.
//

import Foundation

import AVFoundation

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
    /*
     I want a concrete instance of AVAudioPCMBuffer so I don't have to use '!' every where I use the variable
     */
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
    
    func getNumCompleteBuffersAvailable() -> Int
    {
        return audioBufferFifo.count
    }
    
    func isPrepared() -> Bool { return prepared }
    
    func getSize() -> Int { return size }
    //==============================================================================

    /*
     tagging a function parameter with 'inout' converts that parameter into a reference.
     Class types are passed by reference, which means NORMALLY 'inout' is not required here.
     However, because the pull function is changing the reference intself by assigning a completely new object to the parameter, we do need to use 'inout' here.
     */
    func getAudioBuffer(buf: inout AVAudioPCMBuffer) -> Bool
    {
        return audioBufferFifo.pull(buffer: &buf)
    }

    private func pushNextSampleIntoFifo(sample: Float)
    {
        if( fifoIndex == bufferToFill.frameLength )
        {
            audioBufferFifo.push(bufferToFill);
            fifoIndex = 0;
        }

        /*
         floatChannelData is an optional, so we must force-unwrap it in order to access the underlying buffers
         */
        bufferToFill.floatChannelData![0][fifoIndex] = sample
        //Swift does not support ++ or --.  instead you must use += or -=
        //I bet the reason is because post-inc vs pre-inc has been the source of many bugs over the years.
        fifoIndex += 1;
    }
}
