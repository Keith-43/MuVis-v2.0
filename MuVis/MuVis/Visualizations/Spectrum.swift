///  Spectrum.swift
///  MuVis
///
/// This view renders a visualization of the simple one-dimensional spectrum (using a mean-square amplitude scale) of the music.
///
/// We could render a full Spectrum - that is, rendering all of the 8,192 bins -  covering a frequency range from 0 Hz on the left to about 44,100 / 2 = 22,050 Hz
/// on the right . But instead, we will render the spectrum bins from 12 to 755 - that is the 6 octaves from 32 Hz to 2,033 Hz.
///
/// In the lower plot, the horizontal axis is linear frequency (from 32 Hz on the left to 2,033 Hz on the right). The vertical axis shows (in red) the mean-square
/// amplitude of the instantaneous spectrum of the audio being played. The red peaks are spectral lines depicting the harmonics of the musical notes
/// being played. The blue curve is a smoothed average of the red curve (computed by the findMean function within the SpectralEnhancer class).
/// The blue curve typically represents percussive effects which smear spectral energy over a broad range.
///
/// The upper plot (in green) is the same as the lower plot except the vertical scale is decibels (over an 80 dB range) instead of the mean-square amplitude.
/// This more closely represents what the human ear actually hears.
///
/// Clicking on the Option button adds a piano-keyboard overlay . Note that the keyboard has been purposely distorted in order to represent musical notes on the linear frequency of the plot.  This graphically illustrates the difference between the linear-frequency spectrum produced by the FFT and the logarithmic-frequency spectrum used in music.
///
/// Clicking the Option button also adds small rectangles denoting the real-time spectral peaks.  These move very dynamically since the peak amplitudes change very rapidly from frame-to-frame of the audio.  Displaying them here gives me confidence that they are computed properly.  These peaks concisely capture the melody and harmony of the music.
///
/// Created by Keith Bromley on 20 Nov 2020.  Significantly updated on 28 Oct 2021.

import SwiftUI



struct Spectrum: View {
    @EnvironmentObject var settings: Settings

    var body: some View {

        // Toggle between black and white as the Canvas's background color:
        let backgroundColor: Color = (settings.selectedColorScheme == .dark) ? Color.black : Color.white

        ZStack {
            if(settings.optionOn) { GrayVertRects() }   // The func GrayVertRects() is at the bottom of this file.
            Spectrum_Live()
        }
        .background( (settings.optionOn) ? Color.clear : backgroundColor )
    }
}



struct Spectrum_Live: View {
    @EnvironmentObject var audioManager: AudioManager  // Observe the instance of AudioManager passed from ContentView
    @EnvironmentObject var settings: Settings
    let spectralEnhancer = SpectralEnhancer()
    let noteProc = NoteProcessing()
    
    var body: some View {

        GeometryReader { geometry in
            
            let width: CGFloat  = geometry.size.width
            let height: CGFloat = geometry.size.height
            let halfHeight: CGFloat = height * 0.5
            
            var x: CGFloat = 0.0        // The drawing origin is in the upper left corner.
            var y: CGFloat = 0.0        // The drawing origin is in the upper left corner.
            var upRamp: CGFloat = 0.0
            var magY: CGFloat = 0.0             // used as a preliminary part of the "y" value
            
            // We will render the spectrum bins from 12 to 755 - that is the 6 octaves from 32 Hz to 2,033 Hz.
            let lowerBin: Int = noteProc.octBottomBin[0]    // render the spectrum bins from 12 to 755
            let upperBin: Int = noteProc.octTopBin[5]       // render the spectrum bins from 12 to 755
            
// ---------------------------------------------------------------------------------------------------------------------
            // First, render the rms amplitude spectrum in red in the lower half pane:
            Path { path in
                path.move(to: CGPoint( x: 0.0, y: height - ( CGFloat(audioManager.spectrum[lowerBin]) * halfHeight ) ) )
                
                for bin in lowerBin ... upperBin {
                    // upRamp goes from 0.0 to 1.0 as bin goes from lowerBin to upperBin:
                    upRamp =  Double(bin - lowerBin) / Double(upperBin - lowerBin)
                    x = upRamp * width
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
                path.move(to: CGPoint( x: 0.0, y: height - ( CGFloat(meanSpectrum[lowerBin]) * halfHeight) ) )
                
                for bin in lowerBin ... upperBin {
                    // upRamp goes from 0.0 to 1.0 as bin goes from lowerBin to upperBin:
                    upRamp =  Double(bin - lowerBin) / Double(upperBin - lowerBin)
                    x = upRamp * width
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
                    // upRamp goes from 0.0 to 1.0 as bin goes from lowerBin to upperBin:
                    upRamp =  Double(bin - lowerBin) / Double(upperBin - lowerBin)
                    x = upRamp * width
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
                    // upRamp goes from 0.0 to 1.0 as bin goes from lowerBin to upperBin:
                    upRamp =  Double(bin - lowerBin) / Double(upperBin - lowerBin)
                    x = upRamp * width
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
                Peaks_View()
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
}  // end of Spectrum_Live struct



struct Peaks_View: View {
    @EnvironmentObject var audioManager: AudioManager  // Observe the instance of AudioManager passed from ContentView
    @EnvironmentObject var settings: Settings
    let noteProc = NoteProcessing()
    
    var body: some View {
        Canvas { context, size in
            let width: Double  = size.width
            let height: Double = size.height
            let halfHeight: Double = height * 0.5
            var x : Double = 0.0

            let lowerBin: Int = noteProc.octBottomBin[0]    // render the spectrum bins from 12 to 755
            let upperBin: Int = noteProc.octTopBin[5]       // render the spectrum bins from 12 to 755

            for peakNum in 0 ..< peakCount {   // peaksSorter.peakCount = 16
                 x = width * ( Double(audioManager.peakBinNumbers[peakNum] - lowerBin) / Double(upperBin - lowerBin) )

                context.fill(
                    Path(CGRect(x: x, y: 0.0, width: 2.0, height: 0.1 * halfHeight)),
                    with: .color((settings.selectedColorScheme == .light) ? Color.black : Color.white) )

                context.fill(
                    Path(CGRect(x: x, y: halfHeight, width: 2.0, height: 0.1 * halfHeight)),
                    with: .color((settings.selectedColorScheme == .light) ? Color.black : Color.white) )
            }
        }
    }
}  // end of struct Peaks_View



// The ampToDecibels() func is used in the Spectrum6 and MusicSpectrum6 visualizations.
public func ampToDecibels(inputArray: [Float]) -> ([Float]) {
    var dB: Float = 0.0
    let dBmin: Float =  1.0 + 0.0125 * 20.0 * log10(0.001)
    var amplitude: Float = 0.0
    var outputArray: [Float] = [Float] (repeating: 0.0, count: inputArray.count)

    // I must raise 10 to the power of -4 to get my lowest dB value (0.001) to 20*(-4) = 80 dB
    for bin in 0 ..< inputArray.count {
        amplitude = inputArray[bin]
        if(amplitude < 0.001) { amplitude = 0.001 }
        dB = 20.0 * log10(amplitude)    // As 0.001  < spectrum < 1 then  -80 < dB < 0
        dB = 1.0 + 0.0125 * dB          // As 0.001  < spectrum < 1 then    0 < dB < 1
        dB = dB - dBmin
        dB = min(max(0.0, dB), 1.0)
        outputArray[bin] = dB           // We use this array below in creating the mean spectrum
    }
    return outputArray
}



struct GrayVertRects: View {
    @EnvironmentObject var settings: Settings
    let noteProc = NoteProcessing()
    
    var body: some View {
        GeometryReader { geometry in
            let width: Double  = geometry.size.width
            let height: Double = geometry.size.height

            //                               C      C#    D      D#     E     F      F#    G      G#    A      A#    B
            let accidentalNote: [Bool] = [  false, true, false, true, false, false, true, false, true, false, true, false,
                                            false, true, false, true, false, false, true, false, true, false, true, false,
                                            false, true, false, true, false, false, true, false, true, false, true, false,
                                            false, true, false, true, false, false, true, false, true, false, true, false,
                                            false, true, false, true, false, false, true, false, true, false, true, false,
                                            false, true, false, true, false, false, true, false, true, false, true, false,
                                            false, true, false, true, false, false, true, false, true, false, true, false,
                                            false, true, false, true, false, false, true, false, true, false, true, false ]
            let octaveCount = 6

            ForEach( 0 ..< octaveCount, id: \.self) { oct in        //  0 <= oct < 6

                ForEach( 0 ..< notesPerOctave, id: \.self) { note in        //  0 <= note < 12

                    let cumulativeNotes: Int = oct * notesPerOctave + note  // cumulativeNotes = 0, 1, 2, 3, ... 71

                    if(accidentalNote[cumulativeNotes] == true) {
                        // This condition selects the column values for the notes C#, D#, F#, G#, and A#

                        let leftNoteFreq: Float  = noteProc.leftFreqC1  * pow(noteProc.twelfthRoot2, Float(cumulativeNotes) )
                        let rightFreqC1: Float   = noteProc.freqC1 * noteProc.twentyFourthRoot2
                        let rightNoteFreq: Float = rightFreqC1 * pow(noteProc.twelfthRoot2, Float(cumulativeNotes) )

                        // The x-axis is frequency (in Hz) and covers the 6 octaves from 32 Hz to 2,033 Hz.
                        var x: Double = width * ( ( Double(leftNoteFreq) - 32.0 ) / (2033.42 - 32.0) )

                        Path { path in
                            path.move(   to: CGPoint( x: x, y: height ) )
                            path.addLine(to: CGPoint( x: x, y: 0.0))

                            x = width * ( ( Double(rightNoteFreq) - 32.0 ) / (2033.42 - 32.0) )

                            path.addLine(to: CGPoint( x: x, y: 0.0))
                            path.addLine(to: CGPoint( x: x, y: height))
                            path.closeSubpath()
                        }
                        .foregroundColor( .init( (settings.selectedColorScheme == .light) ?
                                                 Color.lightGray.opacity(0.25) :
                                                 Color.black.opacity(0.25) ) )
                    }
                }  // end of ForEach() loop over note
            }  // end of ForEach() loop over oct
        }
    }
}  // end of struct GrayVertRects
