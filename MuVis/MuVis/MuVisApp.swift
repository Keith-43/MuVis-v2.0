//
//  MuVisApp.swift
//  MuVis
//
//  Created by Keith Bromley on 2/28/23.
//

import SwiftUI

// Declare and intialize global constants and variables:
var showMSPF: Bool = false       // display the Performance Monitor's "milliseconds per frame"
var micEnabled: Bool = false    // true means microphone is on and its audio is being captured.

let notesPerOctave   = 12       // An octave contains 12 musical notes.
let pointsPerNote    = 12       // The number of frequency samples within one musical note.
let pointsPerOctave  = notesPerOctave * pointsPerNote  // 12 * 12 = 144

let eightOctNoteCount   = 96    // from C1 to B8 is 96 notes  (  0 <= note < 96 ) (This covers 8 octaves.)
let eightOctPointCount  = eightOctNoteCount * pointsPerNote  // 96 * 12 = 1,152  // number of points in 8 octaves

let sixOctNoteCount  = 72       // the number of notes within six octaves
let sixOctPointCount = sixOctNoteCount * pointsPerNote  // 72 * 12 = 864   // number of points within six octaves

let historyCount    = 48        // Keep the 48 most-recent values of muSpectrum[point] in a circular buffer
let peakCount       = 16        // We only consider the loudest 16 spectral peaks.
let peaksHistCount  = 100       // Keep the 100 most-recent values of peakBinNumbers in a circular buffer

@main
struct MuVisApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AudioManager.audioManager)
                .environmentObject(Settings.settings)
                .frame( minWidth:  100.0, idealWidth:  800.0, maxWidth:  .infinity,
                        minHeight: 100.0, idealHeight: 800.0, maxHeight: .infinity, alignment: .center)
        }
    }
}
