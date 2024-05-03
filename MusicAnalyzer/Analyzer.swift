//
//  Analyzer.swift
//  MusicAnalyzer
//
//  Created by Matkat Music LLC on 4/29/24.
//

import SwiftUI
import AVFAudio
import Accelerate

extension Color {
    static func random() -> Color {
        let red = Double.random(in: 0.25..<1)
        let green = Double.random(in: 0.25..<1)
        let blue = Double.random(in: 0.25..<1)
        return Color(red: red, green: green, blue: blue)
    }
}

struct Bar : View
{
    var mag: CGFloat
    var body : some View {
        GeometryReader
        { geometry in
            let w = geometry.size.width
            let h = geometry.size.height
            Path { path in
                let rect = CGRect(origin: CGPoint(x: 0,
                                                  y: h * (1 - mag)),
                                  size: CGSize(width: w,
                                               height: h * mag))
                path.addRect(rect)
            }
            .fill(Color.random())
        }
        .background(.black)
    }
}

class Bins: ObservableObject
{
    @Published var values: [Float]
    init()
    {
        self.values = Array<Float>(repeating: 0, count: 1024)
    }
}

class BinManager : AudioBufferListener
{
    @ObservedObject var bins: Bins = Bins()
    func bufferDidChange(buffer: inout AVAudioPCMBuffer)
    {
        refreshBins(buffer: &buffer)
    }
    
    func refreshBins(buffer: inout AVAudioPCMBuffer)
    {
        if( buffer.floatChannelData == nil )
        {
            print("No audio data in buffer")
            return
        }
        
        if( buffer.frameLength == 0 )
        {
            print("No audio data in buffer")
            return
        }
        
        if( buffer.stride == 0 )
        {
            print("No audio channels in buffer")
            return
        }
        
        var binTotals: [Float] = []
        for chan in 0 ..< buffer.stride
        {
            let floatArray = Array(UnsafeBufferPointer(start: buffer.floatChannelData![chan],
                                                       count: Int(buffer.frameLength)))
            
            
            let bins = Analyzer.performFFT(input: floatArray)
            
            //split the bins into 24
            for i in 0 ..< bins.count
            {
                if( binTotals.count <= i )
                {
                    binTotals.append(bins[i])
                }
                else
                {
                    binTotals[i] += bins[i]
                }
            }
        }
        
        //normalize the average magnitude of all channels for a particular bin
        for i in 0 ..< binTotals.count
        {
            binTotals[i] /= Float(buffer.stride)
        }
        
        //now normalize the bins against the total number of bins
        for i in 0 ..< binTotals.count
        {
            binTotals[i] /= Float(binTotals.count)
        }
        
        print( "bins: \(binTotals.count)")
        self.bins.values = binTotals //this should refresh the view
    }
}

struct Analyzer : View
{
    var binManager: BinManager = BinManager()
    /*
     template <typename Type>
     Type mapToLog10 (Type value0To1, Type logRangeMin, Type logRangeMax)
     {
         jassert (logRangeMin > 0);
         jassert (logRangeMax > 0);

         auto logMin = std::log10 (logRangeMin);
         auto logMax = std::log10 (logRangeMax);

         return std::pow ((Type) 10.0, value0To1 * (logMax - logMin) + logMin);
     }
     */
    //a port of the JUCE mapToLog10 function:
    func mapToLog10(_ value0To1: CGFloat, _ logRangeMin: CGFloat, _ logRangeMax: CGFloat) -> CGFloat
    {
        assert( logRangeMin > 0 )
        assert( logRangeMax > 0 )
        
        let logMin = log10(logRangeMin)
        let logMax = log10(logRangeMax)
        
        return pow(10.0, value0To1 * (logMax - logMin) + logMin)
    }
    
    
    var body : some View
    {
        /*
         show 24 bars
         the bars are an equal division of the frequency range 20-20000hz
         */
        
//        printMemoryAddress(buffer, message: "Analyzer::body")
        return GeometryReader { geometry in
            let h = geometry.size.height
            let w = geometry.size.width
            
            let numBars = 24
            
            let barWidth = w / CGFloat(numBars)
            /*
             convert the width of a bar into a frequency range.
             */
            
            ForEach(0..<numBars, id: \.self) { barNum in
                let startFreq = self.mapToLog10(CGFloat(barNum) / CGFloat(numBars),
                                           20,
                                           20000)
                let endFreq = self.mapToLog10(CGFloat(barNum + 1) / CGFloat(numBars),
                                         20,
                                         20000)
                
                let startBin = Int(startFreq / 48000.0 * 1024)
                let endBin = Int(endFreq / 48000.0 * 1024)
                
                let binCount = endBin - startBin
                
                let binSum = self.binManager.bins.values[startBin..<endBin].reduce(0, { b1, b2 in
                    b1 + b2 })
                let binAvg = binSum / Float(binCount)
                
                let mag = CGFloat(binAvg)
                let x = barWidth * CGFloat(barNum)
                
                Bar(mag: mag)
                    .frame(width: barWidth,
                           height: h)
                    .position(x: x + barWidth / 2)
                    .offset(y: h / 2)
            }
        }
    }
    
    /*
     Whenever the buffer is updated, calculate the magnitudes of each FFT bin and store them in the magnitudes array.
     */
    static func performFFT(input: Array<Float>) -> [Float]
    {
        var real = input
        var imaginary = [Float](repeating: 0.0, count: input.count)
        var splitComplex = DSPSplitComplex(realp: &real, 
                                           imagp: &imaginary)
        
        let length = vDSP_Length(log2(Float(input.count)))
        let radix = FFTRadix(kFFTRadix2)
        let weights = vDSP_create_fftsetup(length, radix)
        
        vDSP_fft_zip(weights!, &splitComplex, 1, length, FFTDirection(FFT_FORWARD))
        
        vDSP_destroy_fftsetup(weights)
        
        // Calculate the magnitudes of the FFT result
        var magnitudes = [Float](repeating: 0.0, count: input.count)
        vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(input.count))
        
        return magnitudes
    }
    
}

struct AnalyzerOld: View {
    var magnitudes: [CGFloat]
    
    var body : some View {
        GeometryReader { geometry in
            let h = geometry.size.height
            let w = geometry.size.width
            
            let numBars = magnitudes.count
            let barWidth = w / CGFloat(numBars)
            ForEach(0..<numBars, id: \.self) { i in
                let mag = magnitudes[i]
                let x = barWidth * CGFloat(i)
                
                Bar(mag: mag)
                    .frame(width: barWidth,
                           height: h)
                    .position(x: x + barWidth / 2)
                    .offset(y: h / 2)
            }
        }
    }
}

#Preview {
//    let mags: [CGFloat] = [0.5, 0.7, 0.3, 0.9, 0.1]
//    return Analyzer(magnitudes: mags)
//    let buffer = Buffer()
//    let sampleRate = 48000.0
//    let format = AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatFloat32,
//                               sampleRate: sampleRate,
//                               channels: AVAudioChannelCount(2),
//                               interleaved: false)!
//    
//    let frameCapacity = AVAudioFrameCount(2048)
//    
//    var buffer = AVAudioPCMBuffer(pcmFormat: format,
//                                     frameCapacity: frameCapacity)
////    else {
////        fatalError("failed to create AVAudioPCMBuffer in Preview!!")
////    }
//    
//    let frequency = Float(1000)
//    let amplitude = Float(0.5)
//
//    for frame in 0..<Int(frameCapacity) {
//        let time = Float(frame) / Float(sampleRate)
//        let value = sin(2.0 * .pi * frequency * time) * amplitude
//        //copy the value to each channel
//        for ch in 0 ..< Int(format.channelCount )
//        {
//            buffer?.floatChannelData![ch][frame] = value
//        }
//    }
//
//    // Set the frame length to the frame capacity to indicate that the buffer is full
//    buffer?.frameLength = frameCapacity
//    
//    let audioBuffer = AudioBuffer(buffer: buffer!)
    
//    return Analyzer(buf: audioBuffer)
    Analyzer()
}
