/// Wormhole.swift
/// MuVis
///
/// This "OutOfTheRabbitHole" visualization renders the time-history of the music's spectrum across a sequence of circles.
///
/// The following activities are performed during each rendering cycle:
/// 1. The 6-octave muSpectrum is computed.  It extends from C1 at 33 Hz to B6 at 1976 Hz. The binCount6 = 755
/// 2. These spectral values are written into a buffer memory.
/// 3. The most recent 48 spectra are read from this buffer memory and rendered along the 48 concentric circles.
///   Each spectrum is rendered clockwise starting at the twelve o'clock position.
///
/// Again, the colors change with time. The color travels inward with the peaks.   If the optionOn button is selected, then a color gradient is applied to
/// each circle such that the notes within an octave are colored similarly to the standard "hue" color cycle.
///
/// For enhanced visual dynamics, we make the center of the ellipses move both vertically and horizontally.
///
/// Created by Keith Bromley on 1 June 2021. (adapted from his previous java version in the Polaris app)
/// Significantly updated on 26 Nov 2021.


import SwiftUI

struct OutOfTheRabbitHole: View {

    @EnvironmentObject var audioManager: AudioManager  // Observe the instance of AudioManager passed from ContentView
    @EnvironmentObject var settings: Settings
    let noteProc = NoteProcessing()
    
    static var hueOld: [Double] = [Double](repeating: 0.0, count: 64)
    static var colorIndex: Int = 0
    
    var body: some View {
    
        // Toggle between black and white as the Canvas's background color:
        let backgroundColor: Color = (settings.selectedColorScheme == .dark) ? Color.black : Color.white
        
        Canvas { context, size in
 
            let width: Double  = size.width
            let height: Double = size.height
            let X0: Double = 0.5 * width   // the origin of the ellipses
            let Y0: Double = 0.5 * height  // the origin of the ellipses
            
            var startX: Double = 0.0        // horizontal center of the innermost ellipse
            var startY: Double = 0.0        // vertical   center of the innermost ellipse
            let endX: Double = X0           // horizontal center of the outermost ellipse
            let endY: Double = Y0           // vertical   center of the outermost ellipse
            
            let endRadius: Double = 0.8 * sqrt(X0 * X0 + Y0 * Y0)      // stretches from center to almost the corner
            let startRadius: Double = endRadius * 0.02                 // starting radius value
            let rangeRadius = endRadius - startRadius                  // range of the radius value
            
            var x : Double = 0.0       // The drawing origin is in the upper left corner.
            var y : Double = 0.0       // The drawing origin is in the upper left corner.
            var xOld : Double = 0.0
            var yOld : Double = 0.0
            
            var mag:  Double = 0.0         // used as a preliminary part of the audio amplitude value
            var magX: Double = 0.0         // used as a preliminary part of the audio amplitude value
            var magY: Double = 0.0         // used as a preliminary part of the audio amplitude value

            // ellipseCount is the number of ellipses rendered to show the history of each spectrum
            let ellipseCount: Int = 32     // ellipseCount must be <= historyCount
            let oldestHist: Int = historyCount - ellipseCount
            
            let colorSize: Int = 50    // This determines the frequency of the color change over time.
            OutOfTheRabbitHole.colorIndex = (OutOfTheRabbitHole.colorIndex >= colorSize) ? 0 : OutOfTheRabbitHole.colorIndex + 1
            let startHue360: Int = Int( 360.0 * Double(OutOfTheRabbitHole.colorIndex) / Double(colorSize) )

            // The following variables control the movement of the ellipse centers:
            let now = Date()
            let time = now.timeIntervalSinceReferenceDate
            let frequency: Double = 0.05  // 1 cycle per 20 seconds
            let offsetX: Double = cos(2.0 * Double.pi * 3.0*frequency * time ) // oscillates between -1 and +1
            let offsetY: Double = cos(2.0 * Double.pi *     frequency * time ) // oscillates between -1 and +1
            
            
// ---------------------------------------------------------------------------------------------------------------------
            for ellipseNum in 0 ..< ellipseCount {       //  0 <= ellipseNum < 48

                // ellipseNum == 0 is the innermost ellipse.  It has the oldest line of data.

                // As ellipseNum goes from 0 to ellipseCount, ellipseRampUp goes from 0.0 to 1.0:
                let rampUp: Double = Double(ellipseNum) / Double(ellipseCount)
                let rampUp2: Double = rampUp * rampUp          // Deliberate non-linear radius.

                // As ellipseNum goes from 0 to ellipseCount, ellipseRampDown goes from 1.0 to 0.0:
                let rampDown: Double = Double(ellipseCount - ellipseNum) / Double(ellipseCount)
                
                let radius: Double = startRadius + (rampUp2 * rangeRadius) // non-linear radius

                // Just for enhanced visual dynamics, make the center of the ellipses go up and down:
                startX = X0 + offsetX * (width  * 0.05)
                startY = Y0 + offsetY * (height * 0.05)
                
                xOld = rampDown * startX + rampUp * endX            // Start at the twelve o'clock position
                yOld = rampDown * startY + rampUp * endY - radius   // Start at the twelve o'clock position

                // Now ensure that we read the correct spectral data from the muSpecHistory[] array:
                let hist: Int = ellipseNum
                let histOffset: Int = (oldestHist + hist) * sixOctPointCount      // use this for inward  flowing spectra

                let hue: Double = (ellipseNum == ellipseCount-1) ? Double(startHue360) / 360.0 : OutOfTheRabbitHole.hueOld[ellipseNum+1]   // 0.0 <= hue < 1.

                var path = Path()
                path.move( to: CGPoint( x: xOld, y: yOld ) )

                // Render the 864 points in each ellipse:
                for point in 0 ..< sixOctPointCount {
                    let tempIndex: Int = histOffset + point
                    mag = 0.1 * Double( audioManager.muSpecHistory[tempIndex] )
                    mag = min(max(0.0, mag), 1.0)   // Limit over- and under-saturation.
                    magX = mag * rampUp2 * width    // The spectral peaks get bigger at the outer rings
                    magY = mag * rampUp2 * height   // The spectral peaks get bigger at the outer rings
                    // Set to point=0 being at the twelve o'clock position:
                    x = (rampDown * startX + rampUp * endX) + (radius - magX) * noteProc.sin2PiTheta[point]
                    y = (rampDown * startY + rampUp * endY) - (radius - magY) * noteProc.cos2PiTheta[point]
                    path.addLine(to: CGPoint(x: x,  y: y ) )
                }  // end of for() loop over point
    
                if(settings.optionOn == false) {
                    context.stroke( path,
                                    with: .color( Color(hue: hue, saturation: 1.0, brightness: 1.0) ),
                                    lineWidth: 0.5 +  rampUp2 * 4.0 )
                }
                else {
                    // Stroke the 48 paths with an angular gradient cycling through 6 cycles of the "hue" colors:
                    context.stroke( path,
                                    with: .conicGradient( settings.hue6Gradient,
                                                          center: CGPoint( x: startX, y: startY ),
                                                          angle: Angle(degrees: 270.0) ),
                                    lineWidth: 0.5 +  rampUp2 * 4.0 )
                    // https://devtechie.medium.com/new-in-swiftui-3-canvas-269c64ef5efc
                    // https://swiftui-lab.com/swiftui-animations-part5/
                }

                OutOfTheRabbitHole.hueOld[ellipseNum] = hue

            }  // end of for() loop over ellipseNum



            // Print on-screen the elapsed duration-per-frame (in milliseconds) (typically about 50)
            if(showMSPF == true) {
                let frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                context.draw(Text("MSPF: \( settings.monitorPerformance() )"), in: frame )

                #if os(macOS)
                    context.draw(Text("os: macOS"), at: CGPoint(x: 0.96*width, y: 0.01*height) )
                #endif

                #if os(iOS)
                    // https://stackoverflow.com/questions/61113923/how-to-detect-current-device-using-swiftui
                    // UIDevice is only available in UIKit
                    let deviceName = UIDevice.current.name       // the name of the device
                    let modelName = UIDevice.current.model       // the model of the device
                    let OSName = UIDevice.current.systemName     // the name of the operating system
                    context.draw(Text("device: \(deviceName)"), at: CGPoint(x: 0.92*width, y: 0.03*height) )
                    context.draw(Text("model:  \(modelName)" ), at: CGPoint(x: 0.92*width, y: 0.06*height) )
                    context.draw(Text("os:     \(OSName)"    ), at: CGPoint(x: 0.92*width, y: 0.09*height) )
                #endif
            }


        }  // end of Canvas{}
        .background(backgroundColor)  // Toggle between black and white background color.
        
    }  // end of var body: some View{}
}  // end of OutOfTheRabbitHole{} struct



struct OutOfTheRabbitHole_Previews: PreviewProvider {
    static var previews: some View {
        OutOfTheRabbitHole()
    }
}

