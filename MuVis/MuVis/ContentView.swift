//
//  ContentView.swift
//  MuVis
//
//  Apple's declarative unified Toolbar API:
//  https://swiftwithmajid.com/2020/07/15/mastering-toolbars-in-swiftui/
//  https://swiftwithmajid.com/2022/09/07/customizing-toolbars-in-swiftui/
//  https://developer.apple.com/documentation/swiftui/toolbars/
//
//  Created by Keith Bromley on 2/28/23.

import SwiftUI
import QuickLook

struct ContentView: View {
    @EnvironmentObject var audioManager: AudioManager
    @EnvironmentObject var settings: Settings

    @State private var visNum: Int = 0      // visualization number - used as an index into the visualizationList array
    @State private var enableSongFileSelection: Bool = false
    @State private var pauseButtonIsPaused: Bool = false
    @State private var previousAudioURL: URL = URL(string: "https://www.apple.com")!

    @State private var userGuideUrl: URL?
    @State private var visualizationsGuideUrl: URL?

    struct Visualization {
        var name: String        // The visualization's name is shown as text in the titlebar
        var location: AnyView   // A visualization's location is the View that renders it.
    }

    let visualizationList: [Visualization] =  [
            Visualization (name: "Spectrum",                    location: AnyView(Spectrum() ) ),
            Visualization (name: "Music Spectrum",              location: AnyView(MusicSpectrum() ) ),
            Visualization (name: "MuSpectrum",                  location: AnyView(MuSpectrum() ) ),
            Visualization (name: "Spectrum Bars",               location: AnyView(SpectrumBars() ) ),
            Visualization (name: "Linear OAS",                  location: AnyView(LinearOAS() ) ),
            Visualization (name: "Overlapped Octaves",          location: AnyView(OverlappedOctaves() ) ),
            Visualization (name: "Octave-Aligned Spectrum",     location: AnyView(OctaveAlignedSpectrum() ) ),
            Visualization (name: "Octave-Aligned MuSpectrum",   location: AnyView(OctaveAlignedMuSpectrum() ) ),
            Visualization (name: "Elliptical OAS",              location: AnyView(EllipticalOAS() ) ),
            Visualization (name: "Spiral OAS",                  location: AnyView(SpiralOAS() ) ),
            Visualization (name: "Harmonic Alignment",          location: AnyView(HarmonicAlignment() ) ),
            Visualization (name: "Harmonic Alignment 2",        location: AnyView(HarmonicAlignment2() ) ),
            Visualization (name: "TriOct Spectrum",             location: AnyView(TriOctSpectrum() ) ),
            Visualization (name: "TriOct MuSpectrum",           location: AnyView(TriOctMuSpectrum() ) ),
            Visualization (name: "Overlapped Harmonics",        location: AnyView(OverlappedHarmonics() ) ),
            Visualization (name: "Harmonograph",                location: AnyView(Harmonograph() ) ),
            Visualization (name: "Harmonograph2",               location: AnyView(Harmonograph2() ) ),
            Visualization (name: "Cymbal",                      location: AnyView(Cymbal() ) ),
            Visualization (name: "Rainbow Spectrum",            location: AnyView(RainbowSpectrum() ) ),
            Visualization (name: "Rainbow Spectrum2",           location: AnyView(RainbowSpectrum2() ) ),
            Visualization (name: "Waterfall",                   location: AnyView(Waterfall() ) ),
            Visualization (name: "Spectrogram",                 location: AnyView(Spectrogram() ) ),
            Visualization (name: "Rainbow OAS",                 location: AnyView(RainbowOAS() ) ),
            Visualization (name: "Rainbow Ellipse",             location: AnyView(RainbowEllipse() ) ),
            Visualization (name: "Spinning Ellipse",            location: AnyView(SpinningEllipse() ) ),
            Visualization (name: "Out of the Rabbit Hole",      location: AnyView(OutOfTheRabbitHole() ) ),
            Visualization (name: "Down the Rabbit Hole",        location: AnyView(DownTheRabbitHole() ) ),
            Visualization (name: "Lava Lamp",                   location: AnyView(LavaLamp() ) ),
            Visualization (name: "Superposition",               location: AnyView(Superposition() ) ) ]

    var body: some View {

        VStack {

//----------------------------------------------------------------------------------------------------------------------
            // The following HStack constitutes the Top Toolbar:
            HStack {
                Text("Gain-")

                Slider(value: $audioManager.userGain, in: 0.0 ... 2.0)
                    .background(Capsule().stroke(Color.red, lineWidth: 2))
                    .onChange(of: audioManager.userGain, perform: {value in
                        audioManager.userGain = Float(value)
                })
                .help("This slider controls the gain of the visualization.")

                Slider(value: $audioManager.userSlope, in: 0.0 ... 0.03)
                    .background(Capsule().stroke(Color.red, lineWidth: 2))
                    .onChange(of: audioManager.userSlope, perform: {value in
                        audioManager.userSlope = Float(value)
                })
                .help("This slider controls the frequency slope of the visualization.")
                
                Text("-Treble")
            }  // end of HStack{}

//----------------------------------------------------------------------------------------------------------------------
            // The following AnyView constitutes the main visualization rendering pane:
            visualizationList[visNum].location
                .drawingGroup() // improves graphics performance by utilizing off-screen buffers
                .colorScheme(settings.selectedColorScheme)  // sets the pane's color scheme to either .dark or .light
                .background( (settings.selectedColorScheme == .light) ? Color.white : Color.darkGray )
                .navigationTitle("MuVis  (Music Visualizer)   -   \(visualizationList[visNum].name)")
        
//----------------------------------------------------------------------------------------------------------------------
            // The following HStack constitutes the Bottom Toolbar:
            HStack {

                // "Previous Visualization" button:
                Group {
                    Button(action: {
                        visNum -= 1
                        if(visNum <= -1) {visNum = visualizationList.count - 1}
                        audioManager.onlyPeaks = false // Changing the visualization turns off the onlyPeaks variation.
                        settings.optionOn = false    // Changing the visualization turns off the optional visualization variation.
                    } ) {
                            Image(systemName: "chevron.left")
                    }
                    .keyboardShortcut(KeyEquivalent.leftArrow, modifiers: [])
                    .help("This button retreats to the previous visualization.")
                    .disabled(pauseButtonIsPaused)      // gray-out "Previous Vis" button if pauseButtonIsPaused is true
                    .padding(.trailing)


                    // "Next Visualization" button:
                    Button( action: {
                        visNum += 1
                        if(visNum >= visualizationList.count) {visNum = 0}
                        audioManager.onlyPeaks = false // Changing the visualization turns off the onlyPeaks variation.
                        settings.optionOn = false    // Changing the visualization turns off the optional visualization variation.
                    } ) {
                            Image(systemName: "chevron.right")
                    }
                    .keyboardShortcut(KeyEquivalent.rightArrow, modifiers: [])
                    .help("This button advances to the next visualization.")
                    .disabled(pauseButtonIsPaused)      // gray-out "Next Vis" button if pauseButtonIsPaused is true
                    .padding(.trailing)
                }


                Spacer()


                // "Pause / Resume" button:
                Button(action: {
                    if(audioManager.isPaused) { audioManager.startMusicPlay() }    // User clicked on "Resume"
                    else { audioManager.pauseMusicPlay() }                         // User clicked on "Pause"
                    audioManager.isPaused.toggle()
                    pauseButtonIsPaused.toggle()
                } ) {
                Text( (pauseButtonIsPaused) ? "Resume" : "Pause" )
                }
                .help("This button pauses or resumes the audio.")
                .padding(.trailing)



                // "Microphone On/Off" button:
                Button( action: {
                    // It is crucial that micEnabled and filePlayEnabled are opposite - never both true or both false.
                    audioManager.micEnabled.toggle()      // This is the only place in MuVis that micEnabled changes.
                    audioManager.filePlayEnabled.toggle() // This is the only place in MuVis that filePlayEnabled changes.
                    audioManager.stopMusicPlay()
                    audioManager.setupAudio()
                    } ) {
                    Text( (audioManager.micEnabled) ? "Mic Off" : "Mic On")
                }
                .help("This button turns the microphone on and off.")
                .disabled(pauseButtonIsPaused)   // gray-out "Mic On/Off" button if pauseButtonIsPaused is true
                .padding(.trailing)



                // "Select Song" button:
                Button( action: {
                    previousAudioURL.stopAccessingSecurityScopedResource()
                    if(audioManager.filePlayEnabled) {enableSongFileSelection = true} } ) {
                    Text("Song")
                }
                .help("This button opens a pop-up pane to select a song file.")
                .disabled(audioManager.micEnabled)  // gray-out "Select Song" button if mic is enabled
                .disabled(pauseButtonIsPaused)      // gray-out "Select Song" button if pauseButtonIsPaused is true
                .fileImporter(
                    isPresented: $enableSongFileSelection,
                    allowedContentTypes: [.audio],
                    allowsMultipleSelection: false
                    ) { result in
                    if case .success = result {
                        do {
                            let audioURL: URL = try result.get().first!
                            previousAudioURL = audioURL
                            if audioURL.startAccessingSecurityScopedResource() {
                                audioManager.filePath = audioURL.path
                                if(audioManager.filePlayEnabled) {
                                    audioManager.stopMusicPlay()
                                    audioManager.setupAudio()
                                }
                            }
                        } catch {
                            let nsError = error as NSError
                            fatalError("File Import Error \(nsError), \(nsError.userInfo)")
                        }
                    } else {
                            print("File Import Failed")
                    }
                }
                .padding(.trailing)



                // "only Peaks / Normal" button:
                Button(action: { audioManager.onlyPeaks.toggle() } ) {
                    Text( (audioManager.onlyPeaks == true) ? "Normal" : "Peaks")
                }
                .help("This button enhances the peaks by subtracting the background spectrum.")
                .disabled(pauseButtonIsPaused)   // gray-out "Peaks/Normal" button if pauseButtonIsPaused is true
                .padding(.trailing)


                
                // "Option On/Off" button:
                Button(action: { settings.optionOn.toggle() } ) {
                    Text( (settings.optionOn == true) ? "Option Off" : "Option On")
                }
                .help("This button shows a variation of the visualization.")
                .keyboardShortcut(KeyEquivalent.downArrow, modifiers: []) // downArrow key toggles "Option On" button
                .padding(.trailing)


                
                // "Light/Dark Color Scheme" button:
                Button( action: self.toggleColorScheme ) {
                    Text( (settings.selectedColorScheme == .dark) ? "Light" : "Dark")
                }
                .keyboardShortcut(KeyEquivalent.upArrow, modifiers: [])
                .help("This button chooses light- or dark-mode.")
                .padding(.trailing)



                // "Display User Guide" button:
                Button(action: {
                    userGuideUrl = Bundle.main.url( forResource: "UserGuide",
                                                    withExtension: "pdf")
                } ) {
                    Text("UserG")
                }
                .help("This button displays the User Guide.")
                .quickLookPreview($userGuideUrl)
                // https://developer.apple.com/documentation/swiftui/view/quicklookpreview(_:)?language=objc_9
                // https://stackoverflow.com/questions/70341461/how-to-use-quicklookpreview-modifier-in-swiftui


                // "Display Visualizations Guide" button:
                Button(action: {
                    visualizationsGuideUrl = Bundle.main.url( forResource: "Visualizations",
                                                              withExtension: "pdf")
                } ) {
                    Text("VisG")
                }
                .help("This button displays the Visualizations Guide.")
                .quickLookPreview($visualizationsGuideUrl)

            }  // end of HStack
            
        }  // end of VStack

    }  // end of var body: some View
    

    
    // https://stackoverflow.com/questions/61912363/swiftui-how-to-implement-dark-mode-toggle-and-refresh-all-views
    func toggleColorScheme() {
        settings.selectedColorScheme = (settings.selectedColorScheme == .dark) ? .light : .dark
    }

}  // end of ContentView struct
