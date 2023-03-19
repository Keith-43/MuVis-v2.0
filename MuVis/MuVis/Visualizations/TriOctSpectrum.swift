/// TriOctSpectrum.swift
/// MuVis
///
/// The TriOctSpectrum visualization is similar to the LinearOAS visualization in that it shows a muSpectrum of six octaves of the audio waveform -
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
/// As with the LinearOAS visualization, the spectral peaks comprising each note are a separate color, and the colors of the grid are consistent across all octaves -
/// hence all octaves of a "C" note are red; all octaves of an "E" note are green, and all octaves of a "G" note are light blue, etc.
/// Also, we have added a piano-keyboard overlay to clearly differentiate the black notes (in gray) from the white notes (in white).
/// Also, we have added note names for the white notes at the top and bottom.
///
/// The visual appearance of these two MuSpectra is of each note being rendered as a small blob of a different color. However, in fact, we implement this effect by
/// having static vertical blocks depicting the note colors and then having the non-spectrum rendered as two big white / dark-gray blobs covering the non-spectrum
/// portion of the spectrum display - one each for the upper-half-screen and the lower-half-screen. The static colored vertical blocks are rendered first; then the
/// dynamic white / dark-gray big blobs; then the gray "black notes"; and finally the note names.
///
/// Created by Keith Bromley on 29/  Nov 2020.


import SwiftUI


struct TriOctSpectrum: View {
    @EnvironmentObject var settings: Settings

    var body: some View {
        GeometryReader { geometry in
            ZStack {

                ColorRectangles(columnCount: 36)                        // struct code in VisUtilities file
                TriOctSpectrum_Live()

                if(settings.optionOn) {
                    // Overlay the screen with semi-transparent gray rectangles denoting the piano's keyboard:
                    GrayVertRectangles(columnCount: 36)                 // struct code in VisUtilities file
                    VerticalLines(columnCount: 36)                      // struct code in VisUtilities file
                    HorizontalLines(rowCount: 2, offset: 0.0)           // struct code in VisUtilities file
                    HorizontalNoteNames(rowCount: 2, octavesPerRow: 3)  // struct code in VisUtilities file
                }
            }
        }
    }
}



struct TriOctSpectrum_Live : View {
    @EnvironmentObject var audioManager: AudioManager  // Observe the instance of AudioManager passed from ContentView.
    @EnvironmentObject var settings: Settings
    let noteProc = NoteProcessing()
    
    var body: some View {
        
        GeometryReader { geometry in

            let width  : CGFloat = geometry.size.width
            let height : CGFloat = geometry.size.height
            let halfHeight : CGFloat = height * 0.5

            var x : CGFloat = 0.0       // The drawing origin is in the upper left corner.
            var y : CGFloat = 0.0       // The drawing origin is in the upper left corner.
            var magY: CGFloat = 0.0     // used as a preliminary part of the "y" value
            let octavesPerRow : Int = 3
            let octaveWidth: CGFloat = width / CGFloat(octavesPerRow)
            
            ForEach( 0 ... 1, id: \.self) { row in // row = 0 is lower 3-oct row; row = 1 is upper 3-oct row
            
                Path { path in
                    
                    // Render lower 3 octaves in the bottom halfpane, and the upper 3 octaves in the upper halfplane:
                    if (row == 0) {
                        path.move   ( to: CGPoint( x: width, y: halfHeight) )   // right midpoint
                        path.addLine( to: CGPoint( x: width, y: height))        // right bottom
                        path.addLine( to: CGPoint( x: 0.0,   y: height))        // left bottom
                        path.addLine( to: CGPoint( x: 0.0,   y: halfHeight))    // left midpoint
                    } else {
                        path.move   ( to: CGPoint( x: width, y: halfHeight) )   // right midpoint
                        path.addLine( to: CGPoint( x: width, y: 0.0))           // right top
                        path.addLine( to: CGPoint( x: 0.0,   y: 0.0))           // left top
                        path.addLine( to: CGPoint( x: 0.0,   y: halfHeight))    // left midpoint
                    }
                    
                    for oct in 0 ... 2 {                                // render 3 octaves in each of the two rows
                        let newOct: Int = (row == 0) ? oct : 3 + oct
                        
                        for bin in noteProc.octBottomBin[newOct] ... noteProc.octTopBin[newOct] {
                            x = ( Double(oct) * octaveWidth ) + ( noteProc.binXFactor[bin] * octaveWidth )
                            magY = Double(audioManager.spectrum[bin]) * halfHeight
                            magY = min(max(0.0, magY), halfHeight)
                            y = (row == 0) ? halfHeight + magY : halfHeight - magY
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    path.addLine( to: CGPoint( x: width, y: halfHeight ) )
                    path.closeSubpath()
                    
                }  // end of Path
                .foregroundColor( (settings.selectedColorScheme == .light) ? Color.white : Color.darkGray )
                
            }  // end of ForEach(row)
     

            
            // Print on-screen the elapsed time/frame (in milliseconds) (typically about 17)
            if(showMSPF == true) {
                HStack {
                    Text("MSPF: \( settings.monitorPerformance() )")
                    Spacer()
                }
            }

        }  // end of GeometryReader
    }  // end of var body: some View
}  // end of TriOctSpectrum_Live struct
