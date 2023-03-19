/// Cymbal.swift
/// MuVis
///
/// The Cymbal visualization is a different way of depicting the current muSpectrum. It was inspired by contemplating the vibrational patterns of a cymbal.
/// It is purely an aesthetic depiction (with no attempt at real-world modeling).
///
/// On a Mac, we render 6 octaves of the muSpectrum at 12 notes/octave and 2 points/note. Thus, each muSpectrum contains 6 * 12 * 2 = 144 points.
/// This Cymbal visualization renders 144 concentric circles (all with their origin at the pane center) with their radius proportional to these 144 musical-frequency points.
/// 72 of these are note centers, and 72 are the interspersed inter-note midpoints. We dynamically change the line width of these circles to denote the muSpectrum
/// amplitude.
///
/// On an iPhone or iPad, we decrease the circleCount from 144 to 36 to reduce the graphics load (to avoid freezes and crashes when the app runs on more-limited
/// devices).
///
/// For aesthetic effect, we overlay a green plot of the current muSpectrum (replicated from mid-screen to the right edge and from mid-screen to the left edge)
/// on top of the circles.
///
/// A toggle is provided to the developer to render either ovals (wherein all of the shapes are within the visualization pane) or circles (wherein the top and bottom
/// are clipped as outside of the visualization pane)
///
/// My iPad4 could not keep up with the graphics load of rendering 144 circles, so I reduced the circleCount to 36 for iOS devices.
///
/// If the optionOn button is pressed, then this visualization shows oval shapes instead of circle shapes.  This only becomes obvious in short wide panes or tall thin panes.
///
/// Created by Keith Bromley in June 2021. (adapted from his previous java version in the Polaris app).   Significantly updated on 17 Nov 2021.


import SwiftUI


struct Cymbal: View {

    // We observe the instances of the AudioProcessing and Settings classes passed to us from ContentView:
    @EnvironmentObject var audioManager: AudioManager  // Observe the instance of AudioManager passed from ContentView
    @EnvironmentObject var settings: Settings
    
    var body: some View {
    
        // Toggle between black and white as the visualization's background color:
        let backgroundColor: Color = (settings.selectedColorScheme == .dark) ? Color.black : Color.white
        
        GeometryReader { geometry in

            let ellipseCount: Int = 144
            let width:  CGFloat = geometry.size.width
            let height: CGFloat = geometry.size.height
            let halfWidth:  CGFloat =  0.5 * width
            let halfHeight: CGFloat =  0.5 * height
            
            var x : Double = 0.0       // The drawing origin is in the upper left corner.
            var y : Double = 0.0       // The drawing origin is in the upper left corner.
            var mag: Double = 0.0          // used as a preliminary part of the audio amplitude value


            // ---------------------------------------------------------------------------------------------------------
            // Render the 144 concentric ellipses:
            ForEach( 0 ..< ellipseCount, id: \.self) { ellipseNum in      //  0 <= ellipseNum < 144

                // As ellipseNum goes from 0 to ellipseCount, rampUp goes from 0.0 to 1.0:
                let rampUp : Double = Double(ellipseNum) / Double(ellipseCount)

                let hue: Double = Double( ellipseNum%12 ) / 12.0
                let result = settings.HtoRGB(hueValue: hue)
                let red = result.redValue
                let green = result.greenValue
                let blue = result.blueValue
                
                if(settings.optionOn) {
                    Ellipse()
                        .stroke(Color(red: red, green: green, blue: blue),
                                lineWidth: 5.0*max(0.0,Double(audioManager.muSpectrum[6*ellipseNum])))
                        .frame(width: rampUp * width, height: rampUp * height)
                        .position(x: halfWidth, y: halfHeight)
                }else {
                    Ellipse()
                        .stroke(Color(red: 1.0, green: 0.0, blue: 0.0),
                                lineWidth: 5.0*max(0.0,Double(audioManager.muSpectrum[6*ellipseNum])))
                        .frame(width: rampUp * width, height: rampUp * width)
                        .position(x: halfWidth, y: halfHeight)
                }

            }  // end of ForEach() loop over ellipseNum


            // ---------------------------------------------------------------------------------------------------------
            // Now render a four-fold muSpectrum[] across the middle of the pane:
            ForEach( 0 ..< 2, id: \.self) { row in          // We have a lower and an upper row.
                ForEach( 0 ..< 2, id: \.self) { column in   // We have a left and a right column.
                
                    // Make the spectrum negative for the lower row:
                    let spectrumHeight = (row == 0) ? -0.1 * height : 0.1 * height
                    
                    // Make the spectrum go to the left for left column:
                    let spectrumWidth = (column == 0) ? -halfWidth : halfWidth
                        
                    Path { path in
                        path.move(to: CGPoint( x: halfWidth, y: halfHeight ) )
                        
                        for point in 0 ..< sixOctPointCount {
                            let upRamp =  Double(point) / Double(sixOctPointCount)
                            x = halfWidth + upRamp * spectrumWidth
                            mag = Double(audioManager.muSpectrum[point]) * spectrumHeight
                            y = halfHeight + mag
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    .stroke(Color(  (settings.optionOn ? .red : .green) ), lineWidth: 2.0 )

                }  // end of for() loop over column
            }  // end of for() loop over row

            
            // Print on-screen the elapsed time/frame (in milliseconds) (typically about 17)
            if(showMSPF == true) {
                HStack {
                    Text("MSPF: \( settings.monitorPerformance() )")
                    Spacer()
                }
            }
            
        }  // end of GeometryReader
        .background(backgroundColor)  // Toggle between black and white background color.
        
    }  // end of var body: some View{}
}  // end of Cymbal struct
