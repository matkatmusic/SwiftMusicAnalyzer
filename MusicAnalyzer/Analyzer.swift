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
    @Published var values: [Float] = []
    @Published var order: Int = 10
    init()
    {
        //set up an observer for the order property
        _ = $order.sink { _ in
            self.updateValues()
        }
        
        self.updateValues()
    }
    
    private func updateValues()
    {
        let countDouble = NSDecimalNumber(decimal: pow(2.0, self.order))
        
        let count = Int(countDouble.intValue)
        
        self.values = Array<Float>(repeating: 0,
                                   count: count)
    }
}

class BinManager : AudioBufferListener
{
    @ObservedObject var bins: Bins = Bins()
    
    private var leftSCSF: SingleChannelSampleFifo = SingleChannelSampleFifo(channel: Channel.Left)
//    private var rightSCSF: SingleChannelSampleFifo = SingleChannelSampleFifo(channel: Channel.Right)
    
    func prepare(bufferSize: Int)
    {
        //make sure bufferSize is a power of 2!!!
        assert( (bufferSize & (bufferSize - 1)) == 0)
        
        leftSCSF.prepare(bufferSize: bufferSize)
//        rightSCSF.prepare(bufferSize: bufferSize)
    }
    
    func bufferDidChange(buffer: AVAudioPCMBuffer)
    {
        if( buffer.floatChannelData == nil )
        {
            print("No channel data in buffer")
            return
        }
        
        if( buffer.frameLength == 0 )
        {
//            print("No audio data in buffer")
            return
        }
        
        if( buffer.stride == 0 )
        {
            print("No audio channels in buffer")
            return
        }
        
//        printBufferInfo(buffer: buffer)
        leftSCSF.update(buffer: buffer)
//        if( buffer.format.channelCount > 1 )
//        {
////            rightSCSF.update(buffer: buffer)
//        }
//        
        var tempBuf: AVAudioPCMBuffer = AVAudioPCMBuffer()
        while leftSCSF.getNumCompleteBuffersAvailable() > 0
        {
            if leftSCSF.getAudioBuffer(buf: &tempBuf)
            {
                printBufferInfo(buffer: tempBuf)
                var mags = refreshBins(buffer: tempBuf)
                
            }
        }
    }
    
    func refreshBins(buffer: AVAudioPCMBuffer) -> [Float]?
    {
        var binTotals: [Float] = []
        
        var channels: [[Float]] = []
        if( buffer.format.isInterleaved )
        {
            assert(false)
        }
        else
        {
            for channel in 0..<buffer.format.channelCount 
            {
                if let channelData = buffer.floatChannelData?[Int(channel)] 
                {
                    let channelArray = Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength)))
                    channels.append(channelArray)
                }
            }
        }
        
        var outputMags: [[Float]] = []
        //fill 'binTotals' with as many zeros as there are samples in the input buffer
        //TODO: is this same as channels.first!.count?
        binTotals = [Float](repeating: 0, count: Int(buffer.frameLength))
        
        for channel in channels 
        {
            //https://stackoverflow.com/questions/60120842/how-to-use-apples-accelerate-framework-in-swift-in-order-to-compute-the-fft-of
            //https://gist.github.com/jeremycochoy/45346cbfe507ee9cb96a08c049dfd34f
            //the length of the input
            let length = vDSP_Length(channel.count)

            // The power of two of two times the length of the input.
            // Do not forget this factor 2.
            let log2n = vDSP_Length(ceil(log2(Float(length * 2))))
            
            // Create the instance of the FFT class which allow computing FFT of complex vector with length
            // up to `length`.
            let fftSetup = vDSP.FFT(log2n: log2n,
                                    radix: .radix2,
                                    ofType: DSPSplitComplex.self)!
            
            // --- Input / Output arrays
            var forwardInputReal = [Float](channel) // Copy the signal here
            var forwardInputImag = [Float](repeating: 0, count: Int(length))
            var forwardOutputReal = [Float](repeating: 0, count: Int(length))
            var forwardOutputImag = [Float](repeating: 0, count: Int(length))
            var magnitudes = [Float](repeating: 0, count: Int(length))
            
            /// --- Compute FFT
            forwardInputReal.withUnsafeMutableBufferPointer { forwardInputRealPtr in
                forwardInputImag.withUnsafeMutableBufferPointer { forwardInputImagPtr in
                    forwardOutputReal.withUnsafeMutableBufferPointer { forwardOutputRealPtr in
                        forwardOutputImag.withUnsafeMutableBufferPointer { forwardOutputImagPtr in
                            // Input
                            let forwardInput = DSPSplitComplex(realp: forwardInputRealPtr.baseAddress!, imagp: forwardInputImagPtr.baseAddress!)
                            // Output
                            var forwardOutput = DSPSplitComplex(realp: forwardOutputRealPtr.baseAddress!, imagp: forwardOutputImagPtr.baseAddress!)
                            
                            fftSetup.forward(input: forwardInput, output: &forwardOutput)
                            vDSP.absolute(forwardOutput, result: &magnitudes)
                        }
                    }
                }
            }
            
            outputMags.append(magnitudes)
        }
        
        for ch in 0 ..< outputMags.count
        {
            for i in 0 ..< outputMags[ch].count
            {
                binTotals[i] += outputMags[ch][i]
            }
        }
        
        //normalize the average magnitude of all channels for a particular bin
        for i in 0 ..< outputMags.count
        {
            binTotals[i] /= Float(buffer.stride)
        }
        
        //now normalize the bins against the total number of bins
        for i in 0 ..< binTotals.count
        {
            binTotals[i] /= Float(binTotals.count)
        }
        
//        print( "bins: \(binTotals.count)")
        self.bins.values = binTotals //this should refresh the view
        return binTotals
    }
}

struct Analyzer : View
{
    var binManager: BinManager = BinManager()
    @ObservedObject var bins: Bins
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
    
    init()
    {
        bins = binManager.bins
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
                
                let binSum = self.bins.values[startBin..<endBin].reduce(0, { b1, b2 in
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
//    static func performFFT(input: [Float]) -> [Float]?
//    {
//        var real = input
//        var imaginary = [Float](repeating: 0.0, count: input.count)
//        var splitComplex = DSPSplitComplex(realp: &real,
//                                           imagp: &imaginary)
//        
//        let length = vDSP_Length(log2(Float(input.count)))
//        let radix = FFTRadix(kFFTRadix2)
//        let weights = vDSP_create_fftsetup(length, radix)
//        
//        vDSP_fft_zip(weights!, &splitComplex, 1, length, FFTDirection(FFT_FORWARD))
//        
//        vDSP_destroy_fftsetup(weights)
//        
//        // Calculate the magnitudes of the FFT result
//        var magnitudes = [Float](repeating: 0.0, count: input.count)
//        vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(input.count))
//        
//        return magnitudes
        
//        let length = input.count
//        let log2n = vDSP_Length(log2(Float(length)))
//        
//        guard let fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else {
//            print("Error creating FFT setup")
//            return nil
//        }
//        defer {
//            vDSP_destroy_fftsetup(fftSetup)
//        }
//        
//        var complexBuffer = [DSPComplex](repeating: DSPComplex(), count: length/2)
//        var output = [Float](repeating: 0, count: length)
//        
//        // Pack the input into complex buffer (imaginary parts are 0)
//        input.withUnsafeBytes {_ in 
//            vDSP_ctoz([DSPComplex](unsafeUninitializedCapacity: length/2) { complexPtr, _ in
//                complexPtr.initialize(from: complexPtr.baseAddress!.assumingMemoryBound(to: DSPComplex.self), count: length/2)
//            }, 2, &complexBuffer, 1, vDSP_Length(length/2))
//        }
//        
//        // Perform FFT
//        vDSP_fft_zrip(fftSetup, &complexBuffer, 1, log2n, FFTDirection(FFT_FORWARD))
//        
//        // Calculate magnitude
//        vDSP_zvmags(&complexBuffer, 1, &output, 1, vDSP_Length(length/2))
//        
//        return output
//    }
    
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
