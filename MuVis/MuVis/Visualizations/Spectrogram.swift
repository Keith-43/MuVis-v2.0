//
//  Spectrogram.swift
//  MuVis
//
// The 16 peaks of each spectrum is rendered along a horizontal line extending from 0.0 to width.

// Cycling through the 6 "hue" colors is a convenient representation for cycling through the 12 notes of an octave:
//       red        yellow      green        cyan       blue       magenta       red
//  hue = 0          1/6         2/6         3/6         4/6         5/6          1
//        |-----------|-----------|-----------|-----------|-----------|-----------|
// note = 0     1     2     3     4     5     6     7     8     9    10    11     0
//        C     C#    D     D#    E     F     F#    G     G#    A     A#    B     C
//
//
//
//
//  Created by Keith Bromley in Dec 2022.
//

import SwiftUI

struct Spectrogram: View {
    @EnvironmentObject var settings: Settings
    var body: some View {
        ZStack {
            if (settings.optionOn == false) {
                GrayVertRectangles(columnCount: 72)
                VerticalLines(columnCount: 72)
                HorizontalNoteNames(rowCount: 2, octavesPerRow: 6)
            } else {
                GrayHorRectangles(rowCount: 72)
                HorizontalLines(rowCount: 72, offset: 0.0)
                VerticalNoteNames(columnCount: 2, octavesPerColumn: 6)
            }
            Spectrogram_Live()
        }
    }
}


struct Spectrogram_Live: View {
    @EnvironmentObject var audioManager: AudioManager  // Observe the instance of AudioManager passed from ContentView
    @EnvironmentObject var settings: Settings
    let noteProc = NoteProcessing()
    
    var body: some View {

        Canvas { context, size in
            let lineCount: Int = peaksHistCount         // lineCount must be <= peaksHistCount = 100
            var boxHueTemp: Double = 0.0
            var boxHue: Double = 0.0
            var x: Double = 0.0
            var y: Double = 0.0
            var boxWidth:  Double = 0.0
            var boxHeight: Double = 0.0

            // For each audio frame, we will render 100 * 16 = 1600 little boxes:
            if (settings.optionOn == false) {       // vertical scrolling from top to bottom
                boxWidth  = size.width  / Double(NoteProcessing.binCount6-1)  // binCount6 = 756
                boxHeight = size.height / Double(lineCount)                 // lineCount = 100
            } else {                                // horizontal scrolling from right to left
                boxWidth  = size.width  / Double(lineCount)                 // lineCount = 100
                boxHeight = size.height / Double(NoteProcessing.binCount6-1)  // binCount6 = 756
            }

            for lineNum in 0 ..< lineCount {       // lineNum = 0, 1, 2, ... 97, 98, 99
                
                // For each historical spectrum, render 16 peaks:
                for peakNum in 0 ..< peakCount{     // 0 <= peakNum < 16
                    
                    // We need to account for the newest data being at the end of the peaksHistory array:
                    // We want lineNum = 0 (at the pane top) to render the peaks of the newest spectrum:
                    let tempIndex = (lineCount-1 - lineNum) * peakCount + peakNum // 100*16=1600 bin numbers
                    
                    if(audioManager.peaksHistory[tempIndex] != 0) { // Only render a box for non-zero bin numbers.
                        
                        boxHueTemp = 6.0 * noteProc.binXFactor6[audioManager.peaksHistory[tempIndex]]
                        boxHue = boxHueTemp.truncatingRemainder(dividingBy: 1)

                        // For each peak, render a box (rectangle) with upper left coordinates x,y:

                        if (settings.optionOn == false) {	// vertical scrolling from top to bottom
                            x = size.width  * noteProc.binXFactor6[audioManager.peaksHistory[tempIndex]]
                            y = size.height * ( Double(lineNum) / Double(lineCount) )

                        } else {							// horizontal scrolling from right to left
                            x = size.width  * ( 1.0 - ( Double(lineNum) / Double(lineCount) ) )
                            y = size.height * ( 1.0 - noteProc.binXFactor6[audioManager.peaksHistory[tempIndex]] )
                        }

                        context.fill(
                            Path(CGRect(x: x, y: y, width: boxWidth, height: boxHeight)),
                            with: .color(Color( hue: boxHue, saturation: 1.0, brightness: 1.0 )))
                    }
                }  // end of for() loop over peakNum
            }  // end of for() loop over lineNum


            // Print on-screen the elapsed duration-per-frame (in milliseconds) (typically about 50)
            if(showMSPF == true) {
                let frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                context.draw(Text("MSPF: \( settings.monitorPerformance() )"), in: frame )
            }

        }  // end of Canvas{}
    }  //end of var body: some View
}  // end of Spectrogram_Live struct
