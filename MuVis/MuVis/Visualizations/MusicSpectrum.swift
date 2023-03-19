///  Spectrum.swift
///  MuVis
///
/// This view renders a visualization of the simple one-dimensional spectrum (using a mean-square amplitude scale) of the music. However, the horizontal scale is
/// rendered logarithmically to account for the logarithmic relationship between spectrum bins and musical octaves.  The spectrum covers 6 octaves from
/// leftFreqC1 = 32 Hz to rightFreqB8 = 2033 Hz -  that is from bin = 12 to bin = 755.
///
/// This visualization is identical to the Spectrum file except that the horizontal axis is specified by settings.binXFactor6[bin]
///
/// In the lower plot, the vertical axis shows (in red) the mean-square amplitude of the instantaneous spectrum of the audio being played. The red peaks are spectral
/// lines depicting the harmonics of the musical notes being played. The blue curve is a smoothed average of the red curve (computed by the findMean function
/// within the SpectralEnhancer class).  The blue curve typically represents percussive effects which smear spectral energy over a broad range.
///
/// The upper plot (in green) is the same as the lower plot except the vertical scale is decibels (over an 80 dB range) instead of the mean-square amplitude.
/// This more closely represents what the human ear actually hears.
///
/// Created by Keith Bromley on 4 Nov 2021. Animated in Aug 2022.

import SwiftUI


struct MusicSpectrum: View {
    @EnvironmentObject var settings: Settings
    
    var body: some View {
        
        // Toggle between black and white as the Canvas's background color:
        let backgroundColor: Color = (settings.selectedColorScheme == .dark) ? Color.black : Color.white
        
        ZStack {
            if(settings.optionOn) {
                GrayVertRectangles(columnCount: 72)                     // struct code in VisUtilities file
                HorizontalNoteNames(rowCount: 2, octavesPerRow: 6) }    // struct code in VisUtilities file
            MusicSpectrum_Live()
        }
        .background( (settings.optionOn) ? Color.clear : backgroundColor )
    }
}



struct MusicSpectrum_Live: View {
    @EnvironmentObject var audioManager: AudioManager  // Observe the instance of AudioManager passed from ContentView
    @EnvironmentObject var settings: Settings
    let spectralEnhancer = SpectralEnhancer()
    let noteProc = NoteProcessing()
    
    var body: some View {

        GeometryReader { geometry in
            
            let width: CGFloat  = geometry.size.width
            let height: CGFloat = geometry.size.height
            let halfHeight: CGFloat = height * 0.5

            var x: CGFloat = 0.0         // The drawing origin is in the upper left corner.
            var y: CGFloat = 0.0         // The drawing origin is in the upper left corner.
            var magY: CGFloat = 0.0      // used as a preliminary part of the "y" value

            // We will render the spectrum bins from 12 to 755 - that is the 6 octaves from 32 Hz to 2,033 Hz.
            let lowerBin: Int = noteProc.octBottomBin[0]    // render the spectrum bins from 12 to 755
            let upperBin: Int = noteProc.octTopBin[5]       // render the spectrum bins from 12 to 755
            
// ---------------------------------------------------------------------------------------------------------------------
            // First, render the rms amplitude spectrum in red in the lower half pane:
            Path { path in
                path.move(to: CGPoint( x: 0.0, y: height - ( CGFloat(audioManager.spectrum[lowerBin]) * halfHeight ) ) )
                
                for bin in lowerBin ... upperBin {
                    x = width * noteProc.binXFactor6[bin]
                    magY = CGFloat(audioManager.spectrum[bin]) * halfHeight
                    magY = min(max(0.0, magY), halfHeight)
                    y = height - magY
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(lineWidth: 2.0)
            .foregroundColor(.init(red: 1.0, green: 0.0, blue: 0.0, opacity: 1.0))  // foreground color = red
            
// ---------------------------------------------------------------------------------------------------------------------
            // Second, render the mean of the rms amplitude spectrum in blue:
            let meanSpectrum = spectralEnhancer.findMean(inputArray: audioManager.spectrum)
            Path { path in
                path.move(to: CGPoint( x: 0.0, y: height - ( CGFloat(meanSpectrum[lowerBin]) * halfHeight ) ) )
                
                for bin in lowerBin ... upperBin {
                    x = width * noteProc.binXFactor6[bin]
                    magY = CGFloat(meanSpectrum[bin]) * halfHeight
                    magY = min(max(0.0, magY), halfHeight)
                    y = height - magY
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(lineWidth: 2.0)
            .foregroundColor(.init(red: 0.0, green: 0.0, blue: 1.0, opacity: 1.0))  // foreground color = blue
            
// ---------------------------------------------------------------------------------------------------------------------
            // Third, render the decibel-scale spectrum in green in the upper half pane:
            let decibelSpectrum = ampToDecibels(inputArray: audioManager.spectrum)
            Path { path in
                path.move(to: CGPoint( x: 0.0, y: halfHeight - ( CGFloat(decibelSpectrum[lowerBin]) * halfHeight ) ) )
                
                for bin in lowerBin ... upperBin {
                    x = width * noteProc.binXFactor6[bin]
                    magY = CGFloat(decibelSpectrum[bin]) * halfHeight
                    magY = min(max(0.0, magY), halfHeight)
                    y = halfHeight - magY
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(lineWidth: 2.0)
            .foregroundColor(.init(red: 0.0, green: 1.0, blue: 0.0, opacity: 1.0))  // foreground color = green
            
// ---------------------------------------------------------------------------------------------------------------------
            // Fourth, render the mean of the decibel-scale spectrum in blue:
            let meanDecibelSpectrum = spectralEnhancer.findMean(inputArray: decibelSpectrum)
            Path { path in
                path.move(to: CGPoint( x: 0.0, y: halfHeight - ( CGFloat(meanDecibelSpectrum[lowerBin]) * halfHeight ) ) )

                for bin in lowerBin ... upperBin {
                    x = width * noteProc.binXFactor6[bin]
                    magY = CGFloat(meanDecibelSpectrum[bin]) * halfHeight
                    magY = min(max(0.0, magY), halfHeight)
                    y = halfHeight - magY
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(lineWidth: 2.0)
            .foregroundColor(.init(red: 0.0, green: 0.0, blue: 1.0, opacity: 1.0))  // foreground color = blue

// ---------------------------------------------------------------------------------------------------------------------
            // Fifth, optionally render the peaks in black at the top of the view:
            if(settings.optionOn) {
                MusicSpectrumPeaks_View()
            }

            // Print on-screen the elapsed time/frame (in milliseconds) (typically about 17)
            if(showMSPF == true) {
                HStack {
                    Text("MSPF: \( settings.monitorPerformance() )")
                    Spacer()
                }
            }

        }  // end of GeometryReader
    }  // end of var body: some View
}  // end of MusicSpectrum_Live struct



struct MusicSpectrumPeaks_View: View {
    @EnvironmentObject var audioManager: AudioManager  // Observe the instance of AudioManager passed from ContentView
    @EnvironmentObject var settings: Settings
    var noteProc = NoteProcessing()
    
    var body: some View {
        Canvas { context, size in
            let width: CGFloat  = size.width
            let height: CGFloat = size.height
            let halfHeight: CGFloat = height * 0.5
            var x: CGFloat = 0.0

            for peakNum in 0 ..< peakCount {                                            // peakCount = 16

                x = width * noteProc.binXFactor6[audioManager.peakBinNumbers[peakNum]]

                context.fill(
                    Path(CGRect(x: x, y: 0.0, width: 2.0, height: 0.1 * halfHeight)),
                    with: .color((settings.selectedColorScheme == .light) ? Color.black : Color.white) )

                context.fill(
                    Path(CGRect(x: x, y: halfHeight, width: 2.0, height: 0.1 * halfHeight)),
                    with: .color((settings.selectedColorScheme == .light) ? Color.black : Color.white) )
            }
        }
    }
}
