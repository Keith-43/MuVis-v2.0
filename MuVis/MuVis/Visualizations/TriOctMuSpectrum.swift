/// TriOctSpectrum.swift
/// MuVis
///
/// The TriOctMuSpectrum visualization is similar to the LinearOAS visualization in that it shows a muSpectrum of six octaves of the audio waveform -
/// however it renders it as two separate muSpectrum displays.
///
/// It has the format of a downward-facing muSpectrum in the lower half-screen covering the lower three octaves, and an upward-facing muSpectrum in the upper
/// half-screen covering the upper three octaves. Each half screen shows three octaves. (The name "bi- tri-octave muSpectrum" seemed unduly cumbersome,
/// so I abbreviated it to "tri-octave spectrum"). The specific note frequencies are:
///
/// *         262 Hz                                   523 Hz                                    1046 Hz                            1976 Hz
/// *          C4                                          C5                                           C6                                       B6
/// *           |                                               |                                               |                                          |
/// *          W B W B W W B W B W B W W B W B W W B W B W B W W B W B W W B W B W B W
/// *
/// *          W B W B W W B W B W B W W B W B W W B W B W B W W B W B W W B W B W B W
/// *           |                                               |                                               |                                          |
/// *          C1                                          C2                                            C3                                      B3
/// *          33Hz                                   65 Hz                                       130 Hz                               247 Hz
///
///
/// As with the LinearOAS visualization, the spectral peaks comprising each note are a separate color, and the colors of the grid are consistent across all octaves -
/// hence all octaves of a "C" note are red; all octaves of an "E" note are green, and all octaves of a "G" note are light blue, etc.
/// Also, we have added a piano-keyboard overlay to clearly differentiate the black notes (in gray) from the white notes (in white).
/// Also, we have added note names for the white notes at the top and bottom.
///
/// Created by Keith Bromley on 29  Nov 2020.  Improved on 4 Jan 2022.


import SwiftUI


struct TriOctMuSpectrum: View {
    @EnvironmentObject var settings: Settings
    var body: some View {
        ZStack {
            if(settings.optionOn) {
                GrayVertRectangles(columnCount: 36)                         // struct code in VisUtilities file
                HorizontalNoteNames(rowCount: 2, octavesPerRow: 3)          // struct code in VisUtilities file
                TriOctMuSpectrum_Live()
                VerticalLines(columnCount: 36)                              // struct code in VisUtilities file
                HorizontalLines(rowCount: 2, offset: 0.0)                   // struct code in VisUtilities file
            }else{
                TriOctMuSpectrum_Live()
            }
        }
    }
}



struct TriOctMuSpectrum_Live : View {
    @EnvironmentObject var audioManager: AudioManager  // We observe the instance of AudioManager passed from ContentView.
    @EnvironmentObject var settings: Settings

    var body: some View {

        // Toggle between black and white as the Canvas's background color:
        let backgroundColor: Color = (settings.selectedColorScheme == .dark) ? Color.black : Color.white

        GeometryReader { geometry in

            let width  : CGFloat = geometry.size.width
            let height : CGFloat = geometry.size.height
            let halfHeight : CGFloat = height * 0.5
            var x: CGFloat = 0.0       // The drawing origin is in the upper left corner.
            var y: CGFloat = 0.0       // The drawing origin is in the upper left corner.
            var upRamp : CGFloat = 0.0
            var magY: CGFloat = 0.0     // used as a preliminary part of the "y" value
            let octavesPerRow : Int = 3
            let pointsPerRow : Int = pointsPerNote * notesPerOctave * octavesPerRow  //  12 * 12 * 3 = 432

            // Bottom spectrum contains lower three octaves:
            Path { path in
                path.move( to: CGPoint( x: 0.0,   y: halfHeight))    // left midpoint

                for point in 1 ..< pointsPerRow {
                    upRamp =  CGFloat(point) / CGFloat(pointsPerRow)   // upRamp goes from 0.0 to 1.0 as point goes from 0 to pointsPerRow
                    x = upRamp * width
                    magY = CGFloat(audioManager.muSpectrum[point]) * halfHeight
                    magY = min(max(0.0, magY), halfHeight)
                    y = halfHeight + magY
                    path.addLine(to: CGPoint(x: x, y: y))
                }
                path.addLine( to: CGPoint( x: width, y: halfHeight ) )    // right midpoint

                // Top spectrum contains the upper three octaves:
                for point in (1 ..< pointsPerRow).reversed()  {
                    upRamp =  CGFloat(point) / CGFloat(pointsPerRow)   // upRamp goes from 0.0 to 1.0 as point goes from 0 to pointsPerRow
                    x = upRamp * width
                    magY = CGFloat(audioManager.muSpectrum[pointsPerRow + point]) * halfHeight
                    magY = min(max(0.0, magY), halfHeight)
                    y = halfHeight - magY
                    path.addLine(to: CGPoint(x: x, y: y))
                }
                path.addLine( to: CGPoint( x: 0.0,   y: halfHeight))    // left midpoint
                path.closeSubpath()
                
            }  // end of Path
            .background( settings.optionOn ? Color.clear : backgroundColor)
            .foregroundStyle( settings.optionOn ?
                .linearGradient(settings.hue3Gradient, startPoint: .leading, endPoint: .trailing) :
                .linearGradient(settings.hueGradient,  startPoint: .top,     endPoint: .bottom))

            // Print on-screen the elapsed time/frame (in milliseconds) (typically about 17)
            if(showMSPF == true) {
                HStack {
                    Text("MSPF: \( settings.monitorPerformance() )")
                    Spacer()
                }
            }

        }  // end of GeometryReader
    }  // end of var body: some View
}  // end of TriOctMuSpectrum_Live struct
