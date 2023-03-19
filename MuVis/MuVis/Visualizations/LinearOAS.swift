/// LinearOAS.swift
/// MuVis
/// The LinearOAS visualization is similar to the MusicSpectrum visualization in that it shows an amplitude vs. exponential-frequency spectrum of the audio waveform.
/// The horizontal axis covers 6 octaves from leftFreqC1 = 32 Hz to rightFreqB8 = 2033 Hz -  that is from bin = 12 to bin = 755.  For a pleasing effect, the vertical axis
/// shows both an upward-extending spectrum in the upper-half screen and a downward-extending spectrum in the lower-half screen.
///
/// We have added a piano-keyboard overlay to clearly differentiate the black notes (in gray) from the white notes (in white).
/// Also, we have added note names for the white notes at the top and bottom.
///
/// The spectral peaks comprising each note are a separate color. The colors of the grid are consistent across all octaves - hence all octaves of a "C" note are red;
/// all octaves of an "E" note are green, and all octaves of a "G" note are light blue, etc. Many of the subsequent visualizations use this same note coloring scheme.
/// I have subjectively selected these to provide high color difference between adjacent notes.
///
/// The visual appearance of this spectrum is of each note being rendered as a small blob of a different color. However, in fact, we implement this effect by having
/// static vertical blocks depicting the note colors and then having the non-spectrum rendered as one big white /dark-gray blob covering the non-spectrum portion
/// of the spectrum display. The static colored vertical blocks are rendered first; then the dynamic white / dark-gray big blob; then the gray "black notes";
/// and finally the note names.
///
/// Created by Keith Bromley on 29 Nov 2020.  Converted from muSpectrum to spectrum in March 2023.

import SwiftUI


struct LinearOAS: View {
    @EnvironmentObject var settings: Settings
    
    var body: some View {
        ZStack {
            ColorRectangles(columnCount: 72)                        // struct code in VisUtilities file
            LinearOAS_Live()
            if(settings.optionOn) {
                GrayVertRectangles(columnCount: 72)                 // struct code in VisUtilities file
                VerticalLines(columnCount: 72)                      // struct code in VisUtilities file
                HorizontalNoteNames(rowCount: 2, octavesPerRow: 6)  // struct code in VisUtilities file
            }
        }
    }
}



struct LinearOAS_Live: View {
    @EnvironmentObject var audioManager: AudioManager  // Observe the instance of AudioManager passed from ContentView
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

            // We will render the spectrum bins from 12 to 755 - that is the 6 octaves from 32 Hz to 2,033 Hz.
            let lowerBin: Int = noteProc.octBottomBin[0]    // render the spectrum bins from 12 to 755
            let upperBin: Int = noteProc.octTopBin[5]       // render the spectrum bins from 12 to 755

            // Render the lower white / dark-gray blob:
            Path { path in
                path.move   ( to: CGPoint( x: width, y: halfHeight) )   // right midpoint
                path.addLine( to: CGPoint( x: width, y: height))        // right bottom
                path.addLine( to: CGPoint( x: 0.0,   y: height))        // left bottom
                path.addLine( to: CGPoint( x: 0.0,   y: halfHeight))    // left midpoint

                for bin in lowerBin ... upperBin {
                    x = width * noteProc.binXFactor6[bin]
                    magY = Double(audioManager.spectrum[bin]) * halfHeight
                    magY = min(max(0.0, magY), halfHeight)
                    y = halfHeight + magY
                    path.addLine(to: CGPoint(x: x, y: y))
                }
                path.addLine( to: CGPoint( x: width, y: halfHeight ) )
                path.closeSubpath()
            }
            .foregroundColor( (settings.selectedColorScheme == .light) ? Color.white : Color.darkGray )


            // Render the upper white / dark-gray blob:
            Path { path in
                path.move   ( to: CGPoint( x: width, y: halfHeight) )   // right midpoint
                path.addLine( to: CGPoint( x: width, y: 0.0))           // right top
                path.addLine( to: CGPoint( x: 0.0,   y: 0.0))           // left top
                path.addLine( to: CGPoint( x: 0.0,   y: halfHeight))    // left midpoint

                for bin in lowerBin ... upperBin {
                    x = width * noteProc.binXFactor6[bin]
                    magY = Double(audioManager.spectrum[bin]) * halfHeight
                    magY = min(max(0.0, magY), halfHeight)
                    y = halfHeight - magY
                    path.addLine(to: CGPoint(x: x, y: y))
                }
                path.addLine( to: CGPoint( x: width, y: halfHeight ) )
                path.closeSubpath()

            }
            .foregroundColor( (settings.selectedColorScheme == .light) ? Color.white : Color.darkGray )

            // Print on-screen the elapsed time/frame (in milliseconds) (typically about 17)
            Text("MSPF: \( settings.monitorPerformance() )")
            
        }  // end of GeometryReader
    }  // end of var body: some View
}  // end of LinearOAS_Live struct
