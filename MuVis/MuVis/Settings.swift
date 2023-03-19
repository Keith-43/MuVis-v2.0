///  Settings.swift
///  MuVis
///
///  This class contains variables that the app's user gets to adjust - using the buttons and sliders provided in the user interface within the ContentView struct.
///  It also contans constants and variables that the app's developer has selected for optimum performance.
///
///  Created by Keith Bromley on 16 Feb 20/21.


import Foundation
import SwiftUI


class Settings: ObservableObject {

    static let settings = Settings()  // This singleton instantiates the Settings class

    @Published var selectedColorScheme: ColorScheme = .light  // allows user to select light or dark mode
                                                // Changed in ContentView; Published to all visualizations

    @Published var optionOn: Bool = false       // allows user to view a variation on each visualization
                                                // Changed in ContentView; Published to all visualizations
    
    
    // Performance Monitoring:
    var date = NSDate()
    var timePassed: Double = 0.0
    var displayedTimePassed: Double = 0.0
    var counter: Int = 0     // simple counter   0 <= counter < 5

    func monitorPerformance() -> (Int) {
        // Find the elapsed time since the last timer reset:
        let timePassed: Double = -date.timeIntervalSinceNow
        // print( lround( 1000.0 * timePassed ) )  // Gives frame-by-frame timing for debugging.
        // the variable "counter" counts from 0 to 4 continuously (incrementing by one each frame):
        counter = (counter < 4) ? counter + 1 : 0
        // Every fifth frame update the "displayedTimePassed" and render it on the screen:
        if (counter == 4) {displayedTimePassed = timePassed}
        let mspFrame: Int = lround( 1000.0 * displayedTimePassed )
        date = NSDate() // Reset the timer to the current time.  <- Done just before end of visualization rendering.
        return mspFrame
    }  // end of monitorPerformance() func



    // Convert a hueValue to RGB colors:     // 0.0 <= hueValue <= 1.0
    // This function is used in the Cymbal visualization.
    func HtoRGB( hueValue: Double ) -> (redValue: Double, greenValue: Double, blueValue: Double) {
        var redValue:   Double = 0.0
        var greenValue: Double = 0.0
        var blueValue:  Double = 0.0
        let hue: Double = hueValue * 6.0

        if       (hue <= 1.0)   { redValue = 1.0;       greenValue = hue;       blueValue = 0.0
        }else if (hue <  2.0)   { redValue = 2.0 - hue; greenValue = 1.0;       blueValue = 0.0
        }else if (hue <  3.0)   { redValue = 0.0;       greenValue = 1.0;       blueValue = hue - 2.0
        }else if (hue <  4.0)   { redValue = 0.0;       greenValue = 4.0 - hue; blueValue = 1.0
        }else if (hue <  5.0)   { redValue = hue - 4.0; greenValue = 0.0;       blueValue = 1.0
        }else                   { redValue = 1.0;       greenValue = 0.0;       blueValue = 6.0 - hue
        }
        return (redValue, greenValue, blueValue)
    }  // end of HtoRGB() func



    // This func allows me to use a HSB color in the format of a gradient:
    // This is used in the RainbowEllipse and SpinningEllipse visualizations.
    func hueToGradient( hueValue: Double) -> Gradient {
        let hue: Double = hueValue
        return ( Gradient(colors: [Color(hue: hue, saturation: 1.0, brightness: 1.0) ] ) )
    }
    


    // Array stating which notes are accidentals:
    //                               C      C#    D      D#     E     F      F#    G      G#    A      A#    B
    let accidentalNote: [Bool] = [  false, true, false, true, false, false, true, false, true, false, true, false,
                                    false, true, false, true, false, false, true, false, true, false, true, false,
                                    false, true, false, true, false, false, true, false, true, false, true, false,
                                    false, true, false, true, false, false, true, false, true, false, true, false,
                                    false, true, false, true, false, false, true, false, true, false, true, false,
                                    false, true, false, true, false, false, true, false, true, false, true, false,
                                    false, true, false, true, false, false, true, false, true, false, true, false ]


/*  Cycling through the 6 "hue" colors is a convenient representation for cycling through the 12 notes of an octave:
           red        yellow      green        cyan       blue       magenta       red
      hue = 0          1/6         2/6         3/6         4/6         5/6          1
            |-----------|-----------|-----------|-----------|-----------|-----------|
     note = 0     1     2     3     4     5     6     7     8     9    10    11     0
            C     C#    D     D#    E     F     F#    G     G#    A     A#    B     C
*/



    // Define a Gradient that cycles through the same color sequence as the standard "hue":
    // This is used in the OctaveAlignedSpectrum, EllipticalOAS, SpiralOAS, TriOctMuSpectrum, RainbowSpectrum, RaibowOAS,
    // RainbowEllipse, and SpinningEllipse visualizations.
    let hueGradient: Gradient = Gradient(colors: [Color(red: 1.0, green: 0.0, blue: 0.0),     // red
                                                  Color(red: 1.0, green: 1.0, blue: 0.0),     // yellow
                                                  Color(red: 0.0, green: 1.0, blue: 0.0),     // green
                                                  Color(red: 0.0, green: 1.0, blue: 1.0),     // cyan
                                                  Color(red: 0.0, green: 0.0, blue: 1.0),     // blue
                                                  Color(red: 1.0, green: 0.0, blue: 1.0),     // magenta
                                                  Color(red: 1.0, green: 0.0, blue: 0.0)])    // red
    
    
    // Define a Gradient that cycles 3 times through the same color sequence as the standard "hue":
    // This is used in the TriOctMuSpectrum, RainbowSpectrum, RainbowSpectrum2, and Waterfall visualizations.
    let hue3Gradient: Gradient = Gradient(colors: [Color(red: 1.0, green: 0.0, blue: 0.0),     // red
                                                   Color(red: 1.0, green: 1.0, blue: 0.0),     // yellow
                                                   Color(red: 0.0, green: 1.0, blue: 0.0),     // green
                                                   Color(red: 0.0, green: 1.0, blue: 1.0),     // cyan
                                                   Color(red: 0.0, green: 0.0, blue: 1.0),     // blue
                                                   Color(red: 1.0, green: 0.0, blue: 1.0),     // magenta
                                                   Color(red: 1.0, green: 0.0, blue: 0.0),     // red
                                                   Color(red: 1.0, green: 1.0, blue: 0.0),     // yellow
                                                   Color(red: 0.0, green: 1.0, blue: 0.0),     // green
                                                   Color(red: 0.0, green: 1.0, blue: 1.0),     // cyan
                                                   Color(red: 0.0, green: 0.0, blue: 1.0),     // blue
                                                   Color(red: 1.0, green: 0.0, blue: 1.0),     // magenta
                                                   Color(red: 1.0, green: 0.0, blue: 0.0),     // red
                                                   Color(red: 1.0, green: 1.0, blue: 0.0),     // yellow
                                                   Color(red: 0.0, green: 1.0, blue: 0.0),     // green
                                                   Color(red: 0.0, green: 1.0, blue: 1.0),     // cyan
                                                   Color(red: 0.0, green: 0.0, blue: 1.0),     // blue
                                                   Color(red: 1.0, green: 0.0, blue: 1.0),     // magenta
                                                   Color(red: 1.0, green: 0.0, blue: 0.0)])    // red
                                                  
                                                  
    // Define a Gradient that cycles 6 times through the same color sequence as the standard "hue":
    // This is used in the SpinningEllipse, OutOfTheRabbitHole, and DownTheRabbitHole visualizations.
    let hue6Gradient: Gradient = Gradient(colors: [Color(red: 1.0, green: 0.0, blue: 0.0),     // red
                                                   Color(red: 1.0, green: 1.0, blue: 0.0),     // yellow
                                                   Color(red: 0.0, green: 1.0, blue: 0.0),     // green
                                                   Color(red: 0.0, green: 1.0, blue: 1.0),     // cyan
                                                   Color(red: 0.0, green: 0.0, blue: 1.0),     // blue
                                                   Color(red: 1.0, green: 0.0, blue: 1.0),     // magenta
                                                   Color(red: 1.0, green: 0.0, blue: 0.0),     // red
                                                   Color(red: 1.0, green: 1.0, blue: 0.0),     // yellow
                                                   Color(red: 0.0, green: 1.0, blue: 0.0),     // green
                                                   Color(red: 0.0, green: 1.0, blue: 1.0),     // cyan
                                                   Color(red: 0.0, green: 0.0, blue: 1.0),     // blue
                                                   Color(red: 1.0, green: 0.0, blue: 1.0),     // magenta
                                                   Color(red: 1.0, green: 0.0, blue: 0.0),     // red
                                                   Color(red: 1.0, green: 1.0, blue: 0.0),     // yellow
                                                   Color(red: 0.0, green: 1.0, blue: 0.0),     // green
                                                   Color(red: 0.0, green: 1.0, blue: 1.0),     // cyan
                                                   Color(red: 0.0, green: 0.0, blue: 1.0),     // blue
                                                   Color(red: 1.0, green: 0.0, blue: 1.0),     // magenta
                                                   Color(red: 1.0, green: 0.0, blue: 0.0),     // red
                                                   Color(red: 1.0, green: 1.0, blue: 0.0),     // yellow
                                                   Color(red: 0.0, green: 1.0, blue: 0.0),     // green
                                                   Color(red: 0.0, green: 1.0, blue: 1.0),     // cyan
                                                   Color(red: 0.0, green: 0.0, blue: 1.0),     // blue
                                                   Color(red: 1.0, green: 0.0, blue: 1.0),     // magenta
                                                   Color(red: 1.0, green: 0.0, blue: 0.0),     // red
                                                   Color(red: 1.0, green: 1.0, blue: 0.0),     // yellow
                                                   Color(red: 0.0, green: 1.0, blue: 0.0),     // green
                                                   Color(red: 0.0, green: 1.0, blue: 1.0),     // cyan
                                                   Color(red: 0.0, green: 0.0, blue: 1.0),     // blue
                                                   Color(red: 1.0, green: 0.0, blue: 1.0),     // magenta
                                                   Color(red: 1.0, green: 0.0, blue: 0.0),     // red
                                                   Color(red: 1.0, green: 1.0, blue: 0.0),     // yellow
                                                   Color(red: 0.0, green: 1.0, blue: 0.0),     // green
                                                   Color(red: 0.0, green: 1.0, blue: 1.0),     // cyan
                                                   Color(red: 0.0, green: 0.0, blue: 1.0),     // blue
                                                   Color(red: 1.0, green: 0.0, blue: 1.0),     // magenta
                                                   Color(red: 1.0, green: 0.0, blue: 0.0)])    // red

}  // end of Settings class
