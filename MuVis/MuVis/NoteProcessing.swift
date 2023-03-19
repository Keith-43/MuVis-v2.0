///  NoteProcessing.swift
///  MuVis
///
///  The NoteProcessing class specified some constants and variable specific to musical notes.
///  When MuVis starts running, the function calculateParameters() is run to calculate a number of variables used throughout the entire project.
///
///  From the spectrum of the audio signal, we are interested in the frequencies between note C1 (about 33 Hz) and note B8 (about 7,902 Hz).
///  These 96 notes cover 8 octaves.
///
///  Created by Keith Bromley on 16 Feb 2021.


import Accelerate


class NoteProcessing {

    static let noteProc = NoteProcessing()  // This singleton instantiates the NoteProcessing class

    init() { calculateParameters() }

    let twelfthRoot2      : Float = pow(2.0, 1.0 / 12.0)     // twelfth root of two = 1.059463094359
    let twentyFourthRoot2 : Float = pow(2.0, 1.0 / 24.0)     // twenty-fourth root of two = 1.029302236643
    
    // variables used to transform the spectrum into an "octave-aligned" spectrum:
    var freqC1: Float = 0.0         // The lowest note of interest is C1 (about 33 Hz Hz)
    var leftFreqC1: Float = 0.0
    var leftFreqC2: Float = 0.0
    var freqB8: Float = 0.0
    var rightFreqB8: Float = 0.0
    
    // To capture 6 octaves, the highest note is B6 = 1,976 Hz      rightFreqB6 = 2,033.42 Hz   topBin = 755
    static let binCount6: Int =  756        // binCount6 = octTopBin[5] + 1 =  755 + 1 = 756

    // To capture 8 octaves, the highest note is B8 = 7,902 Hz      rightFreqB8 = 8,133.68 Hz   topBin = 3,021
    static let binCount8: Int = 3022        // binCount8 = octTopBin[7] + 1 = 3021 + 1 = 3022
    
    // The 8-octave spectrum covers the range from leftFreqC1 = 31.77 Hz to rightFreqB8 = 8133.84 Hz.
    // That is, from bin = 12 to bin = 3,021
    // The FFT provides us with 8,192 bins.  We will ignore the bin values above 3,022.
    var leftOctFreq  = [Double](repeating: 0.0, count: 8) // frequency at the left window border for a given octave
    var rightOctFreq = [Double](repeating: 0.0, count: 8) // frequency at the right window border for a given octave
    var octBinCount  = [Int](repeating: 0, count: 8)   // number of spectral bins in each octave
    var octBottomBin = [Int](repeating: 0, count: 8)   // the bin number of the bottom spectral bin in each octave
    var octTopBin    = [Int](repeating: 0, count: 8)   // the bin number of the top spectral bin in each octave

    // This is an array of scaling factors to multiply the octaveWidth to get the x coordinate:
    var binXFactor:  [Double] = [Double](repeating: 0.0, count: binCount8)  // binCount8 = 3,022
    var binXFactor6: [Double] = [Double](repeating: 0.0, count: binCount6)  // binCount6 =   756
    var binXFactor8: [Double] = [Double](repeating: 0.0, count: binCount8)  // binCount8 = 3,022
    
    var theta: Double = 0.0                                     // 0 <= theta < 1 is the angle around the ellipse
    let pointIncrement: Double = 1.0 / Double(sixOctPointCount)         // pointIncrement = 1 / 864
    var cos2PiTheta = [Double](repeating: 0.0, count: sixOctPointCount) // cos(2 * Pi * theta)
    var sin2PiTheta = [Double](repeating: 0.0, count: sixOctPointCount) // sin(2 * Pi * theta)
    
    
    // -----------------------------------------------------------------------------------------------------------------
    // Let's calculate a few frequency values and bin values common to many of the music visualizations:
    func calculateParameters() {

        // Calculate the lower bound of our frequencies-of-interest:
        freqC1 = 55.0 * pow(twelfthRoot2, -9.0)     // C1 = 32.7032 Hz
        leftFreqC1 = freqC1 / twentyFourthRoot2     // leftFreqC1 = 31.772186 Hz
        leftFreqC2 = 2.0 * leftFreqC1               // C1 = 32.7032 Hz    C2 = 65.4064 Hz
    
        // Calculate the upper bound of our frequencies-of-interest:
        freqB8  = 7040.0 * pow(twelfthRoot2, 2.0)   // B8 = 7,902.134 Hz
        rightFreqB8 = freqB8 * twentyFourthRoot2    // rightFreqB8 = 8,133.684 Hz

        // For each octave, calculate the left-most and right-most frequencies:
        for oct in 0 ..< 8 {    // 0 <= oct < 8
            let octD = Double(oct)
            let pow2oct: Double = pow( 2.0, octD )
            leftOctFreq[oct]  = pow2oct * Double( leftFreqC1 ) // 31.77  63.54 127.09 254.18  508.35 1016.71 2033.42 4066.84 Hz
            rightOctFreq[oct] = pow2oct * Double( leftFreqC2 ) // 63.54 127.09 254.18 508.35 1016.71 2033.42 4066.84 8133.68 Hz
        }

        let binFreqWidth = (Double(AudioManager.sampleRate)/2.0) / Double(AudioManager.binCount) // (44100/2)/8192=2.69165 Hz

        // Calculate the number of bins in each octave:
        for oct in 0 ..< 8 {    // 0 <= oct < 8
            var bottomBin: Int = 0
            var topBin: Int = 0
            var startNewOct: Bool = true

            for bin in 0 ..< AudioManager.binCount {
                let binFreq: Double = Double(bin) * binFreqWidth
                if (binFreq < leftOctFreq[oct]) { continue } // For each row, ignore bins with frequency below the leftFreq.
                if (startNewOct) { bottomBin = bin; startNewOct = false }
                if (binFreq > rightOctFreq[oct]) {topBin = bin-1; break} // For each row, ignore bins with frequency above the rightFreq.
            }
            octBottomBin[oct] = bottomBin               // 12, 24, 48,  95, 189, 378,  756,  1511
            octTopBin[oct] = topBin                     // 23, 47, 94, 188, 377, 755, 1510,  3021
            octBinCount[oct] = topBin - bottomBin + 1   // 12, 24, 47,  94, 189, 378,  756,  1511
        }

        // Calculate the exponential x-coordinate scaling factor:
        for oct in 0 ..< 8 {    // 0 <= oct < 8
            for bin in octBottomBin[oct] ... octTopBin[oct] {
                let binFreq: Double = Double(bin) * binFreqWidth
                let binFraction: Double = (binFreq - leftOctFreq[oct]) / (rightOctFreq[oct] - leftOctFreq[oct]) // 0 < binFraction < 1.0
                let freqFraction: Double = pow(Double(twelfthRoot2), 12.0 * binFraction) // 1.0 < freqFraction < 2.0

                // This is an array of scaling factors to multiply the octaveWidth to get the x coordinate:
                // That is, binXFactor goes from 0.0 to 1.0 within each octave.
                binXFactor[bin] =  (2.0 - (2.0 / freqFraction))
                // If freqFraction = 1.0 then binXFactor = 0; If freqFraction = 2.0 then binXFactor = 1.0

                // As bin goes from 12 to 3021, binXFactor8 goes from 0.0 to 1.0
                binXFactor8[bin] = ( Double(oct) + binXFactor[bin] ) / Double(8)

                // As bin goes from 12 to 755, binXFactor6 goes from 0.0 to 1.0
                if(oct < 6) {binXFactor6[bin] = ( Double(oct) + binXFactor[bin] ) / Double(6) }
                // print(oct,   bin,   binXFactor[bin],    binXFactor8[bin])
            }
        }

        // Calculate the angle theta from dividing a circle into sixOctPointCount angular increments:
        for point in 0 ..< sixOctPointCount {           // sixOctPointCount = 72 * 12 = 864
            theta = Double(point) * pointIncrement
            cos2PiTheta[point] = cos(2.0 * Double.pi * theta)
            sin2PiTheta[point] = sin(2.0 * Double.pi * theta)
        }

    }  // end of calculateParameters() func



    // -----------------------------------------------------------------------------------------------------------------
    // This function calculates the muSpectrum array:
    public func computeMuSpectrum(inputArray: [Float]) -> [Float] {
        // The inputArray is typically an audio spectrum from the AudioManager.
        
        var outputIndices   = [Float] (repeating: 0.0, count: eightOctPointCount) // eightOctPointCount = 96*12 = 1,152
        var pointBuffer     = [Float] (repeating: 0.0, count: eightOctPointCount) // eightOctPointCount = 96*12 = 1,152
        let tempFloat1: Float = leftFreqC1
        let tempFloat2: Float = Float(notesPerOctave * pointsPerNote)
        let tempFloat3: Float = Float(AudioManager.binFreqWidth)

        for point in 0 ..< eightOctPointCount {
            outputIndices[point] = ( tempFloat1 * pow( 2.0, Float(point) / tempFloat2 ) ) / tempFloat3
        }
        // print(outputIndices)
        
        vDSP_vqint( inputArray,                             // inputVector1
                    &outputIndices,                         // inputVector2 (with indices and fractional parts)
                    vDSP_Stride(1),                         // stride for inputVector2
                    &pointBuffer,                           // outputVector
                    vDSP_Stride(1),                         // stride for outputVector
                    vDSP_Length(eightOctPointCount),        // outputVector.count
                    vDSP_Length(NoteProcessing.binCount8))  // inputVector1.count

        return pointBuffer
    }

}  // end of NoteProcessing class
