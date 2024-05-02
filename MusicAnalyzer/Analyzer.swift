//
//  Analyzer.swift
//  MusicAnalyzer
//
//  Created by Matkat Music LLC on 4/29/24.
//

import SwiftUI

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

struct Analyzer: View {
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
    let mags: [CGFloat] = [0.5, 0.7, 0.3, 0.9, 0.1]
    return Analyzer(magnitudes: mags)
}
