/// RainbowSpectrum2.swift
/// MuVis
///
/// The RainbowSpectrum2 visualization is simple a more dynamic version of the RainbowSpectrum visualization. Also, the colors are different.
///
/// The rows showing the current muSpectrum are no longer static at the top and bottom of the screen - but move dynamically between the midpoint and
/// the top and bottom of the screen.
///
/// Created by Keith Bromley on 16 Dec 2020.  Significantly updated on 12 Mar 2023.


import SwiftUI


struct RainbowSpectrum2: View {
    @EnvironmentObject var settings: Settings

    var body: some View {
        
        // Toggle between black and white as the Canvas's background color:
        let backgroundColor: Color = (settings.selectedColorScheme == .dark) ? Color.black : Color.white
        
        RainbowSpectrum2_Live()
            .background( backgroundColor )
    }
}



struct RainbowSpectrum2_Live: View {
    @EnvironmentObject var audioManager: AudioManager  // We observe the instance of AudioManager passed to us from ContentView.
    @EnvironmentObject var settings: Settings
    
    var body: some View {
        Canvas { context, size in

            let width: Double  = size.width
            let height: Double = size.height
            let halfHeight: CGFloat     = height * 0.5
            let quarterHeight: CGFloat  = height * 0.25
            
            var x : CGFloat = 0.0       // The drawing origin is in the upper left corner.
            var y : CGFloat = 0.0       // The drawing origin is in the upper left corner.

            var hueIndex: Double = 0.0
            
            let octavesPerRow: Int = 3
            let pointsPerRow: Int = pointsPerNote * notesPerOctave * octavesPerRow  // pointsPerRow = 12 * 12 * 3 = 432
            
            var lineRampUp: CGFloat = 0.0
            var lineRampDown: CGFloat = 0.0
            var startX: CGFloat = 0.0
            var endX: CGFloat = 0.0
            var valY: CGFloat = 0.0
            
            let now = Date()
            let time = now.timeIntervalSinceReferenceDate
            let frequency: Double = 0.1  // 1 cycle per 10 seconds
            var vertOffset: Double = 0.0  // vertOffset oscillates between -1 and +1.
            
            var histOffset : Int = 0
            
            // Note that the newest data is at the end of the of the muSpecHistory array
            // tempIndexR0 is the index to first element of the most-recent (hist=0) spectrum written
            let tempIndexR0 = (historyCount - 1) * sixOctPointCount
            var tempIndexR1 : Int = 0
            var tempIndexR2 : Int = 0
            var tempIndexR3 : Int = 0
            var tempIndexR4 : Int = 0

            for lineNum in 0 ..< historyCount {           //  0 <= hist < 48

                histOffset = lineNum * sixOctPointCount
                tempIndexR1 = tempIndexR0 - histOffset

                // We need to account for wrap-around at the muSpecHistory[] ends
                tempIndexR2 = (tempIndexR1 >= 0) ? tempIndexR1 : tempIndexR1 + (historyCount*sixOctPointCount)

                // As lineNum goes from 0 to lineCount, lineRampUp goes from 0.0 to 1.0:
                lineRampUp = CGFloat(lineNum) / CGFloat(historyCount)

                // As lineNum goes from 0 to lineCount, lineRampDown goes from 1.0 to 0.0:
                lineRampDown =  CGFloat(historyCount - lineNum ) / CGFloat(historyCount)

                // Each spectrum is rendered along a horizontal line extending from startX to endX.
                startX = 0.0   + lineRampUp * (0.33 * width)
                endX   = width - lineRampUp * (0.33 * width)
                let spectrumWidth: CGFloat = endX - startX
                let pointWidth: CGFloat = spectrumWidth / CGFloat(pointsPerRow)  // pointsPerRow= 3*12*8 = 288

                vertOffset = cos(2.0 * Double.pi * frequency * time )  // vertOffset oscillates between -1 and +1.
                valY = lineRampDown*(quarterHeight-(quarterHeight*CGFloat(vertOffset))) + (lineRampUp*halfHeight)

                // Render the lower and upper triOct spectra:
                for triOct in 0 ..< 2 {                 // triOct = 0, 1

                    hueIndex = (triOct == 0) ? 0.66 : 0.0  // lower triOct is blue;  upper triOct is red

                    var path = Path()
                    path.move( to: CGPoint( x: startX, y: (triOct == 0) ? height - valY : valY ) )

                    // The lower triOct spectrum and the upper triOct spectrum each contain 3 * 144 = 432 points.
                    // For each frame, we render 2 * 48 = 96 paths.
                    // For each frame, we render a total of 2 * 48 * 432 = 41,472 points

                    for point in 0 ..< pointsPerRow{     // 0 <= point < 432
                        x = startX + ( CGFloat(point) * pointWidth )
                        x = min(max(startX, x), endX);

                        tempIndexR3 = (triOct == 0) ? (tempIndexR2 + point) : (pointsPerRow + tempIndexR2 + point)

                        // We needed to account for wrap-around at the muSpecHistory[] ends
                        tempIndexR4 = tempIndexR3 % (historyCount * sixOctPointCount)
                        let mag: CGFloat = CGFloat(audioManager.muSpecHistory[tempIndexR4]) * lineRampDown * quarterHeight
                        let magY = valY + mag
                        y = (triOct == 0) ? height - magY : magY
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    path.addLine( to: CGPoint( x: endX, y: (triOct == 0) ? height - valY : valY ) )

                    if(settings.optionOn) {
                        context.stroke( path,
                                        with: .linearGradient( settings.hue3Gradient,
                                                               startPoint: CGPoint(x: startX, y: valY),
                                                               endPoint: CGPoint(x: endX, y: valY)),
                                        lineWidth: 0.2 + (lineRampDown * 3.0) )
                    } else {
                        context.stroke( path,
                                        with: .color(Color(hue: hueIndex, saturation: 1.0, brightness: 1.0)),
                                        lineWidth: 0.2 + (lineRampDown * 3.0) )
                    }

                }  // end of ForEach() loop over triOct

            }  // end of ForEach() loop over lineNum


    
            // Print on-screen the elapsed duration-per-frame (in milliseconds) (typically about 17)
            if(showMSPF == true) {
                let frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                context.draw(Text("MSPF: \( settings.monitorPerformance() )"), in: frame )
            }

        }  // end of Canvas
    }  //end of var body: some View
}  // end of RainbowSpectrum2_Live struct
