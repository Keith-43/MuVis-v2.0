/// RainbowSpectrum.swift
/// MuVis
///
/// The RainbowSpectrum is the first of the MuVis visualizations that depict the time-history of the muSpectra. That is, instead of rendering just the current
/// muSpectrum, they also render the most-recent 48 muSpectra - so they show how the envelope of each note varies with time. With a frame-rate of 0.1 seconds
/// per frame, these 48 muSpectra cover the last 4.8 seconds of the music we are hearing.
///
/// The RainbowSpectrum visualization uses a similar geometry to the TriOctSpectrum visualization wherein the lower three octaves of muSpectrum audio information
/// are rendered in the lower half-screen and the upper three octaves are rendered in the upper half-screen. The current muSpectrum is shown in the bottom and
/// top rows. And the muSpectrum history is shown as drifting (and shrinking) to the vertical mid-screen.
///
/// For variety, the colors of the upper half-screen and lower half-screen change over time.  If the optionOn button is selected, then a color gradient is applied to
/// the muSpectrum such that the notes within an octave are colored similarly to the standard "hue" color cycle.
///
/// Created by Keith Bromley on 16 Dec 2020.  Significantly updated on 1 Nov 2021 and on 12 Mar 2023.


import SwiftUI



struct RainbowSpectrum: View {
    @EnvironmentObject var settings: Settings

    var body: some View {
        
        // Toggle between black and white as the Canvas's background color:
        let backgroundColor: Color = (settings.selectedColorScheme == .dark) ? Color.black : Color.white
        
        RainbowSpectrum_Live()
            .background( backgroundColor )
    }
}



struct RainbowSpectrum_Live: View {
    @EnvironmentObject var audioManager: AudioManager  // Observe the instance of AudioManager passed from ContentView.
    @EnvironmentObject var settings: Settings

    static var colorIndex: Int = 0
    
    var body: some View {
        Canvas { context, size in

            let width: Double  = size.width
            let height: Double = size.height
            let halfHeight: CGFloat     = height * 0.5
            let quarterHeight: CGFloat  = height * 0.25
            
            var x : CGFloat = 0.0       // The drawing origin is in the upper left corner.
            var y : CGFloat = 0.0       // The drawing origin is in the upper left corner.
            
            var hueIndex: Double = 0.0          // 0 <= hueIndex < 1.0
            var hueLower: Double = 0.0          // 0 <= hueLower < 1.0
            var hueUpper: Double = 0.0          // 0 <= hueUpper < 1.0
            let colorSize: Int = 30_000         // This determines the frequency of the color change over time.
            
            let octavesPerRow: Int = 3
            let pointsPerRow: Int = pointsPerNote * notesPerOctave * octavesPerRow  // pointsPerRow = 12 * 12 * 3 = 432
            
            var lineRampUp: CGFloat = 0.0
            var lineRampDown: CGFloat = 0.0
            var startX: CGFloat = 0.0
            var endX: CGFloat   = 0.0
            var valY: CGFloat = 0.0
            var histOffset : Int = 0
            
            // Note that the newest data is at the end of the of the muSpecHistory array
            // tempIndexR0 is the index to first element of the most-recent (hist=0) spectrum written
            let tempIndexR0 = (historyCount - 1) * sixOctPointCount
            var tempIndexR1 : Int = 0
            var tempIndexR2 : Int = 0
            var tempIndexR3 : Int = 0
            var tempIndexR4 : Int = 0
            
            for lineNum in 0 ..< historyCount {                        //  0 <= lineNum < 48

                histOffset = lineNum * sixOctPointCount
                tempIndexR1 = tempIndexR0 - histOffset
                
                // We need to account for wrap-around at the muSpecHistory[] ends:
                tempIndexR2 = (tempIndexR1 >= 0) ? tempIndexR1 : tempIndexR1 + (historyCount*sixOctPointCount)

                // As lineNum goes from 0 to lineCount, lineRampUp goes from 0.0 to 1.0:
                lineRampUp = CGFloat(lineNum) / CGFloat(historyCount)

                // As lineNum goes from 0 to lineCount, lineRampDown goes from 1.0 to 0.0:
                lineRampDown =  CGFloat(historyCount - lineNum ) / CGFloat(historyCount)

                // Each spectrum is rendered along a horizontal line extending from startX to endX.
                startX = 0.0   + lineRampUp * (0.33 * width)
                endX   = width - lineRampUp * (0.33 * width)
                let spectrumWidth: CGFloat = endX - startX
                let pointWidth: CGFloat = spectrumWidth / CGFloat(pointsPerRow)  // pointsPerRow= 3 * 12 * 12 = 432
                valY = lineRampUp * halfHeight
        
                RainbowSpectrum_Live.colorIndex = ( RainbowSpectrum_Live.colorIndex >= colorSize) ?
                                                    0 :
                                                    RainbowSpectrum_Live.colorIndex + 1
                
                hueLower = Double(RainbowSpectrum_Live.colorIndex) / Double(colorSize)      // 0.0 <= hue < 1.0
                hueUpper = hueLower + 0.5
                if (hueUpper > 1.0) { hueUpper -= 1.0 }
                
                // Render the lower and upper triOct spectra:
                for triOct in 0 ..< 2 {                             // triOct = 0, 1
                    hueIndex = (triOct == 0) ? hueLower : hueUpper

                    var path = Path()
                    path.move( to: CGPoint( x: startX, y: (triOct == 0) ? height - valY : valY ) )

                    // The lower triOct spectrum and the upper triOct spectrum each contain 3 * 144 = 432 points.
                    // For each frame, we render 2 * 48 = 96 paths.
                    // For each frame, we render a total of 2 * 48 * 432 = 41,472 points

                    for point in 0 ..< pointsPerRow{     // 0 <= point < 432
                        x = startX + ( CGFloat(point) * pointWidth )
                        x = min(max(startX, x), endX);

                        tempIndexR3 = (triOct == 0) ? (tempIndexR2 + point) : (pointsPerRow + tempIndexR2 + point)

                        // We needed to account for wrap-around at the muSpecHistory[] ends:
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

                }  // end of for(triOct) loop

            }  // end of for(lineNum) loop



            // Print on-screen the elapsed duration-per-frame (in milliseconds) (typically about 17)
            if(showMSPF == true) {
                let frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                context.draw(Text("MSPF: \( settings.monitorPerformance() )"), in: frame )
            }

        }  // end of Canvas
    }  //end of var body: some View
}  // end of RainbowSpectrum_Live struct
