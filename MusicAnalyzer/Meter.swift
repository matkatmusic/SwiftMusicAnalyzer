//
//  Meter.swift
//  MusicAnalyzer
//
//  Created by Matkat Music LLC on 5/4/24.
//

import SwiftUI

struct Meter : View
{
    @ObservedObject var mag: ObservedFloat
    var fillColor: Color
    var body : some View {
        GeometryReader
        { geometry in
            let h = geometry.size.height
            let w = geometry.size.width
//            let _ = print( "Mag: \(mag.value) ")
            Rectangle().frame(width: w,
                              height: h * mag.value)
            .foregroundColor(fillColor)
            .offset(y: (1 - mag.value) * h)
        }
//        .background(.black)
    }
}

#Preview {
    let mag = ObservedFloat()
    return Meter(mag: mag, fillColor: Color.green)
}
