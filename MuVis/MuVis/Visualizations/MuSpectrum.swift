/// MuSpectrum.swift
/// MuVis
///
/// This view renders a visualization of the muSpectrum (using a mean-square amplitude scale) of the music. I have coined the name muSpectrum for the
/// exponentially-resampled version of the spectrum to more closely represent the notes of the musical scale.
///
/// In the lower plot, the horizontal axis is exponential frequency - from the note C1 (about 33 Hz) on the left to the note B7 (about 3,951 Hz) on the right.
/// The vertical axis shows (in red) the mean-square amplitude of the instantaneous muSpectrum of the audio being played. The red peaks are spectral lines
/// depicting the harmonics of the musical notes being played - and cover seven octaves. The blue curve is a smoothed average of the red curve (computed by the
/// findMean function within the SpectralEnhancer class). The blue curve typically represents percussive effects which smear spectral energy over a broad range.
///
/// The upper plot (in green) is the same as the lower plot except the vertical scale is decibels (over an 80 dB range) instead of the mean-square amplitude.
/// This more closely represents what the human ear actually hears.
///
/// Created by Keith Bromley on 20 Nov 2020.

import SwiftUI



struct MuSpectrum: View {
    @EnvironmentObject var settings: Settings

    var body: some View {

        // Toggle between black and white as the Canvas's background color:
        let backgroundColor: Color = (settings.selectedColorScheme == .dark) ? Color.black : Color.white

        ZStack {
            if(settings.optionOn) {
                GrayVertRectangles(columnCount: 72)                     // struct code in VisUtilities file
                HorizontalNoteNames(rowCount: 2, octavesPerRow: 6) }    // struct code in VisUtilities file
            MuSpectrum_Live()
        }
        .background( (settings.optionOn) ? Color.clear : backgroundColor )
    }
}



struct MuSpectrum_Live: View {

    @EnvironmentObject var audioManager: AudioManager  // Observe the instance of AudioManager passed from ContentView
    @EnvironmentObject var settings: Settings
    let spectralEnhancer = SpectralEnhancer()

    var body: some View {
    
        GeometryReader { geometry in

            let width: CGFloat  = geometry.size.width
            let height: CGFloat = geometry.size.height
            let halfHeight: CGFloat = height * 0.5

            var x: CGFloat = 0.0       // The drawing origin is in the upper left corner.
            var y: CGFloat = 0.0       // The drawing origin is in the upper left corner.
            var upRamp: CGFloat = 0.0
            var amplitude: Float = 0.0
            var dB: Float = 0.0
            let dBmin: Float =  1.0 + 0.0125 * 20.0 * log10(0.001)
            var magY: CGFloat = 0.0             // used as a preliminary part of the "y" value

            var meanMuSpectrum: [Float]     = [Float](repeating: 0.0, count: eightOctPointCount)  // totalPointCount = 96 * 12 = 1,152
            var dB_muSpectrum: [Float]      = [Float](repeating: 0.0, count: eightOctPointCount)  // the dB-scale muSpectrum
            var mean_dB_muSpectrum: [Float] = [Float](repeating: 0.0, count: eightOctPointCount)  // the mean of the dB-scale muSpectrum

// ---------------------------------------------------------------------------------------------------------------------
            // First, render the muSpectrum in red in the lower half pane:
            Path { path in
                
                path.move( to: CGPoint( x: CGFloat(0.0), y: height ) )
                
                for point in 0 ..< eightOctPointCount {
                    // upRamp goes from 0.0 to 1.0 as point goes from 0 to totalPointCount
                    upRamp =  CGFloat(point) / CGFloat(eightOctPointCount)
                    x = upRamp * width
                    magY = CGFloat(audioManager.muSpectrum[point]) * halfHeight
                    magY = min(max(0.0, magY), halfHeight)
                    y = height - magY
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(lineWidth: 2.0)
            .foregroundColor(.init(red: 1.0, green: 0.0, blue: 0.0, opacity: 1.0))  // foreground color = red

// ---------------------------------------------------------------------------------------------------------------------
            // Second, render the mean of the muSpectrum in blue:
            Path { path in
            
                meanMuSpectrum = spectralEnhancer.findMean(inputArray: audioManager.muSpectrum)
                            
                path.move( to: CGPoint( x: CGFloat(0.0), y: height - CGFloat(meanMuSpectrum[0]) * height ) )
                
                for point in 0 ..< eightOctPointCount {
                    upRamp =  CGFloat(point) / CGFloat(eightOctPointCount)   // upRamp goes from 0.0 to 1.0 as point goes from 0 to sixOctPointCount
                    x = upRamp * width
                    magY = CGFloat(meanMuSpectrum[point]) * halfHeight
                    magY = min(max(0.0, magY), height)
                    y = height - magY
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(lineWidth: 2.0)
            .foregroundColor(.init(red: 0.0, green: 0.0, blue: 1.0, opacity: 1.0))  // foreground color = blue
            
// ---------------------------------------------------------------------------------------------------------------------
            // Third, render the decibel-scale muSpectrum in green in the upper half pane:
            Path { path in
                
                path.move( to: CGPoint( x: CGFloat(0.0), y: halfHeight ) )
                    
                for point in 0 ..< eightOctPointCount {
                    upRamp =  CGFloat(point) / CGFloat(eightOctPointCount)   // upRamp goes from 0.0 to 1.0 as point goes from 0 to totalPointCount
                    x = upRamp * width
                    
                    // I must raise 10 to the power of -4 to get my lowest dB value (0.001) to 20*(-4) = 80 dB
                    amplitude = audioManager.muSpectrum[point]
                    if(amplitude < 0.001) { amplitude = 0.001 }
                    dB = 20.0 * log10(amplitude)    // As 0.001  < spectrum < 1 then  -80 < dB < 0
                    dB = 1.0 + 0.0125 * dB          // As 0.001  < spectrum < 1 then    0 < dB < 1
                    dB = dB - dBmin
                    dB = min(max(0.0, dB), 1.0)
                    dB_muSpectrum[point] = dB           // We use this array below in creating the mean spectrum
                    magY = CGFloat(dB) * halfHeight
                    y = halfHeight - magY
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(lineWidth: 2.0)
            .foregroundColor(.init(red: 0.0, green: 1.0, blue: 0.0, opacity: 1.0))  // foreground color = green
            
            
// ---------------------------------------------------------------------------------------------------------------------
            // Fourth, render the mean of the decibel-scale muSpectrum in blue:
            Path { path in
            
                mean_dB_muSpectrum = spectralEnhancer.findMean(inputArray: dB_muSpectrum)
                            
                path.move( to: CGPoint( x: CGFloat(0.0), y: halfHeight - CGFloat(mean_dB_muSpectrum[0]) * halfHeight ) )
                
                for point in 0 ..< eightOctPointCount {
                    upRamp =  CGFloat(point) / CGFloat(eightOctPointCount)   // upRamp goes from 0.0 to 1.0 as point goes from 0 to totalPointCount
                    x = upRamp * width
                    magY = CGFloat(mean_dB_muSpectrum[point]) * halfHeight
                    magY = min(max(0.0, magY), halfHeight)
                    y = halfHeight - magY
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(lineWidth: 2.0)
            .foregroundColor(.init(red: 0.0, green: 0.0, blue: 1.0, opacity: 1.0))  // foreground color = blue

            // Print on-screen the elapsed time/frame (in milliseconds) (typically about 17)
            if(showMSPF == true) {
                HStack {
                    Text("MSPF: \( settings.monitorPerformance() )")
                    Spacer()
                }
            }

        }  // end of GeometryReader
    }  // end of var body: some View
}  // end of MuSpectrum struct
