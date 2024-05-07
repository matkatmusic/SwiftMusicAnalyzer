//
//  Meter.swift
//  MusicAnalyzer
//
//  Created by Matkat Music LLC on 5/4/24.
//

import SwiftUI

struct Meter : View
{
    /*
     whenever mag changes, this view will refresh itself.
     that's the power of ObservedObject!!
     */
    @ObservedObject var mag: ObservedFloat
    /*
     fillColor is declared but not initialized.
     this forces the member to be a constructor argument if no init() function is written
     */
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
