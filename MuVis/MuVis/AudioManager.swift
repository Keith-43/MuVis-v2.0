//
//  AudioManager.swift
//  MuVis
//
/// The AudioManager class handles the playing, capture, and processing of audio data in real time.  This version of the AudioManager uses the BASS audio library from www.un4seen.com .
///
/// When this class is first run, it plays the song file named music.mp3 located in the app's bundle .  Pressing the "Select Song" button in the ContentView struct allows the user to change to any song file located on his device.  Also, pressing the "MicOn" button, changes the micEnabled variable to true, and causes this class to processes live audio data from the microphone.
///
///  The input audio signal is sampled at 44,100 samples per second.
///  Our FFT window of 16,384 samples has a duration of 16,384 / 44,100 = 0.37152 seconds.
///  We calculate a new spectrum every 1/60 seconds, hence our window overlap factor is (0.37152-0.16666)/0.37152 = 55%
///
///  Created by Keith Bromley on 2/24/23.

import Accelerate

class AudioManager: ObservableObject {
    
    static let audioManager = AudioManager() // This singleton instantiates the AudioManager class and runs setupAudio()
    let settings = Settings()
    let spectralEnhancer = SpectralEnhancer()
    let peaksSorter = PeaksSorter()
    let noteProc = NoteProcessing()
    
    static let sampleRate: Double = 44100.0     // We will process the audio data at 44,100 samples per second.
    static let fftLength: Int =  16384          // The number of audio samples inputted to the FFT operation each frame.
    static let binCount: Int = fftLength/2      // The number of frequency bins provided in the FFT output
                                                // binCount = 8,192 for fftLength = 16,384
    static let binFreqWidth: Double = (sampleRate/2.0 ) / Double(binCount) // binFreqWidth = (44100/2)/8192 = 2.69165 Hz

    var isPaused: Bool = false          // When paused, don't overwrite the previous rendering with all-zeroes:
    var micEnabled: Bool = false        // true means microphone is on and its audio is being captured.
    var filePlayEnabled: Bool = true    // Either micEnabled or filePlayEnabled is always true (but not both).

    // Play this song when the MuVis app starts:
    var filePath = Bundle.main.path(forResource: "music", ofType: "mp3")    // changed in ContentView by Button("Song")
    
    var userGain: Float = getGain()         // The getGain() func is located at the bottom of this file.
    var userSlope: Float = getSlope()       // The getSlope() func is located at the bottom of this file.
    var onlyPeaks: Bool = getOnlyPeaks()    // The getOnlyPeaks() func is located at the bottom of this file.

    // Declare arrays of the final values (for this frame) that we will publish to the various visualizations:
    
    // Declare an array to contain the first 3,022 binValues of the current window of audio spectral data:
    @Published var spectrum: [Float] = [Float](repeating: 0.0, count: NoteProcessing.binCount8)   // binCount8 = 3,022
    
    // Declare an array to contain the 96 * 12 = 1,152 points of the current muSpectrum of the audio data:
    @Published var muSpectrum = [Float](repeating: 0.0, count: eightOctPointCount)
    
    // Declare two arrays to store the 16 loudest peak bin numbers and their amplitudes of the spectrum:
    @Published var peakBinNumbers  = [Int] (repeating: 0,   count: peakCount)   // bin numbers of the spectral peaks
    @Published var peakAmps  = [Double] (repeating: 0.0, count: peakCount)      // amplitudes of the spectral peaks

    // Declare a circular buffer to store the past 48 blocks of the first six octaves of the spectrum.
    // It stores 48 * 756 = 36,288 bins
    @Published var spectrumHistory: [Float] = [Float](repeating: 0.0, count: historyCount * NoteProcessing.binCount6)
    
    // Declare a circular array to store the past 48 blocks of the first six octaves of the muSpectrum.
    // It stores 48 * 72 * 12 = 41,472 points
    @Published var muSpecHistory: [Float] = [Float](repeating: 0.0, count: historyCount * sixOctPointCount)
    
    // Declare a circular array to store the past 100 blocks of the 16 loudest peak bin numbers of the spectrum:
    // It stores 100 * 16 = 1,600 bin numbers
    @Published var peaksHistory: [Int] = [Int](repeating: 0, count: peaksHistCount * peakCount)     // 100 * 16 = 1,600
    
    let timeInterval: Double = 1.0 / 60.0		// 60 frames per second
    
    var stream: HSTREAM = 0
    
    func startMusicPlay() { BASS_Start() }
    func pauseMusicPlay() { BASS_Pause() }
    func stopMusicPlay()  { BASS_Stop(); BASS_Free() }
    
    init() { setupAudio() }



    // ----------------------------------------------------------------------------------------------------------------
    func setupAudio(){

        // Initialize the output device (i.e., speakers) that BASS should use:
        BASS_Init(  -1,                                 // device: -1 is the default device
                     UInt32(AudioManager.sampleRate),   // freq: output sample rate is 44,100 sps
                     0,                                 // flags: DWORD
                     nil,                               // win: 0 = the desktop window (for console applications)
                     nil)                               // dsguid: Unused, set to nil
        // The sample format specified in the freq and flags parameters has no effect on the output on macOS or iOS.
        // The device's native sample format is automatically used.

        if(micEnabled == true) {

            // Initialize the input device (i.e., microphone) that BASS should use:
            BASS_RecordInit(-1)     // device = -1 is the default input device

            stream = BASS_RecordStart(  44100,          // freq: the sample rate to record at
                                        1,              // chans: number of audio channels, 1 = mono
                                        0,              // flags:
                                        myRecordProc,   // callback proc:
                                        nil)            // user:

            func myRecordProc(_: HRECORD, _: UnsafeRawPointer?, _: DWORD, _: UnsafeMutableRawPointer?) -> BOOL32{
                return BOOL32(truncating: true)     // continue recording
            }

        } else {

            // Create a sample stream from our MP3 song file:
            stream = BASS_StreamCreateFile( BOOL32(truncating: false),  // mem: false = stream the file from a filename
                                            filePath,                   // file:
                                            0,                          // offset:
                                            0,                          // length: 0 = use all data up to end of file
                                            0)                          // flags:

            BASS_ChannelPlay(stream, -1) // starts the output
        }

        // Declare an array to contain all 8,192 binValues of the current window of audio spectral data:
        var fullSpectrum: [Float] = [Float](repeating: 0.0, count: AudioManager.binCount)   // binCount  = 8,192

        // Compute the 8192-bin spectrum of the song waveform every 1/60 seconds:
        Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { time in
            BASS_ChannelGetData(self.stream, &fullSpectrum, BASS_DATA_FFT16384)

            // Normalize the rms amplitudes to be loosely within the range 0.0 to 1.0:
            for bin in 0 ..< NoteProcessing.binCount8 {
                let scalingFactor: Float = 5.0 * ( self.userGain + self.userSlope * Float(bin) )
                self.spectrum[bin] = scalingFactor * fullSpectrum[bin]
            }
            
            if(self.onlyPeaks == true) {self.spectrum = self.spectralEnhancer.enhance(inputArray: self.spectrum) }

            //----------------------------------------------------------------------------------------------------------
            // Calculate the sixteen loudest spectral peaks within the 6-octave spectrum:
            // Get the sortedPeakBinNumbers for our 6-octave spectrum:
            let lowerBin: Int = self.noteProc.octBottomBin[0]    // lowerBin =  12
            let upperBin: Int = self.noteProc.octTopBin[5]       // upperBin = 755

            let result = self.peaksSorter.getSortedPeaks(binValues: self.spectrum, bottomBin: lowerBin, topBin: upperBin, peakThreshold: 0.1)
            self.peakBinNumbers = result.sortedPeakBinNumbers
            self.peakAmps = result.sortedPeakAmplitudes

            //----------------------------------------------------------------------------------------------------------
            // Enhance the spectrum to the muSpectrum:
            self.muSpectrum = self.noteProc.computeMuSpectrum(inputArray: self.spectrum)
            
            //----------------------------------------------------------------------------------------------------------
            
            // Store the first 756 bins of the current spectrum array into the spectrumHistory array (48 * 756 bins):
            let spectrum6 = Array( self.spectrum[0 ..< NoteProcessing.binCount6] ) // binBuffer6 has the first 756 elements of binBuffer
            self.spectrumHistory.removeFirst(NoteProcessing.binCount6) // requires that 0 <= binCount6 <= spectrumHistoryBuffer.count
            self.spectrumHistory.append(contentsOf: spectrum6)
            // Note that the newest data is at the end of the spectrumHistory array.
            
            // Store the current muSpectrum6 array (72*12 points) into the pointHistoryBuffer array (48*72*12 points):
            let muSpectrum6  = Array( self.muSpectrum[0 ..< sixOctPointCount] )  // Reduce pointCount from 1152 to 864
            self.muSpecHistory.removeFirst(sixOctPointCount)    // requires that  0 <= sixOctPointCount <= pointHistoryBuffer.count
            self.muSpecHistory.append(contentsOf: muSpectrum6)
            // Note that the newest data is at the end of the muSpecHistory array.
            
            // Store the current sortedPeakBinNumbers array (16 bin numbers) into the peaksHistoryBuffer array (100*16 binNums):
            self.peaksHistory.removeFirst(peakCount)    // requires that  0 <= peakCount <= peaksHistoryBuffer.count
            self.peaksHistory.append(contentsOf: self.peakBinNumbers)
            // Note that the newest data is at the end of the peaksHistory array.

        }  // end of Timer()
    }  // end of func setupAudio()

}  // end of class AudioManager



// ---------------------------------------------------------------------------------------------------------------------
func getGain() -> Float {
    let serialQueue = DispatchQueue(label: "...")
    // https://www.raywenderlich.com/books/concurrency-by-tutorials/v2.0/chapters/5-concurrency-problems

    var tempUserGain: Float = 1.0
    var userGain: Float {    // the user's choice for "gain"  (0.0  <= userGain  <= 2.0 ) Changed in ContentView
        get { return serialQueue.sync { tempUserGain } }
        set { serialQueue.sync { tempUserGain = newValue } }
    }
    return tempUserGain
}



func getSlope() -> Float {
    let serialQueue = DispatchQueue(label: "...")
    // https://www.raywenderlich.com/books/concurrency-by-tutorials/v2.0/chapters/5-concurrency-problems
    
    var tempUserSlope: Float = 0.015
    var userSlope: Float {   // the user's choice for "slope" (0.00 <= userSlope <= 0.03) Changed in ContentView
        get { return serialQueue.sync { tempUserSlope } }
        set { serialQueue.sync { tempUserSlope = newValue } }
    }
    return userSlope
}



func getOnlyPeaks() -> Bool {
    let serialQueue = DispatchQueue(label: "...")
    // https://www.raywenderlich.com/books/concurrency-by-tutorials/v2.0/chapters/5-concurrency-problems
    
    // Allow the user to choose to see normal spectrum or only peaks (with percussive noises removed).
    var tempOnlyPeaks = false
    var onlyPeaks: Bool {   // the user's choice for "onlyPeaks" (true or false).  Changed in ContentView
        get { return serialQueue.sync { tempOnlyPeaks } }
        set { serialQueue.sync { tempOnlyPeaks = newValue } }
    }
    return onlyPeaks
}
