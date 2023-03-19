/// OverlappedHarmonics.swift
/// MuVis
///
/// The OverlappedHarmonics visualization is similar to the OverlappedOctaves visualization - except, instead of rendering just one actave in each of six rows, it renders 3 octaves in each of two rows. Both show a six-octave muSpectrum.  Immediately in front of this "fundamental" muSpectrum is the muSpectrum of the first harmonic (which is one octave above the fundamental spectrum) in a different color.  Immediately in front of this first-harmonic muSpectrum is the muSpectrum of the second harmonic (which is 19 notes higher than the fundamental muSpectrum) in a different color.  Immediately in front of this second-harmonic is the muSpectrum of the third-harmonic (which is 24 notes above the fundamental.)  And so on.
///
/// The on-screen display format has a downward-facing spectrum in the lower half-screen covering the lower three octaves, and an upward-facing spectrum in the upper half-screen covering the upper three octaves. The specific frequencies are:
///
/// *         262 Hz                                   523 Hz                                    1046 Hz                            1976 Hz
/// *          C4                                          C5                                           C6                                       B6
/// *           |                                               |                                               |                                          |
/// *          W B W B W W B W B W B W W B W B W W B W B W B W W B W B W W B W B W B W
/// *
/// *          W B W B W W B W B W B W W B W B W W B W B W B W W B W B W W B W B W B W
/// *           |                                               |                                               |                                          |
/// *          C1                                          C2                                            C3                                      B3
/// *          33Hz                                   65 Hz                                       130 Hz                               247 Hz
///
///
/// For the fundamental muSpectrum, the spectral peaks comprising each note are a separate color, and the colors of the grid are consistent across all octaves -
/// hence all octaves of a "C" note are red; all octaves of an "E" note are green, and all octaves of a "G" note are light blue, etc.
/// We have added note names for the white notes at the top and bottom.
///
/// A novel feature of the OverlappedHarmonics visualization is the rendering of the harmonics beneath each note. We are rendering 6 harmonics of each note.
/// We will start counting from 1 - meaning that harm=1 refers to the fundamental. If the fundamental is note C1, then:
///
///	harm=1  is  C1  fundamental
///	harm=2  is  C2  octave                                               harm=3  is  G2
///	harm=4  is  C3  two octaves         harm=5  is  E3      harm=6  is  G3
/// So, harmonicCount = 6 and  harm = 1, 2, 3, 4, 5, 6.
/// The harmonic increment (harmIncrement) for our 6 rendered harmonics is 0, 12, 19, 24, 28, 31 notes.
///
/// As described above, the fundamental (harm=1) (the basic octave-aligned muSpectrum) is shown with a separate color for each note.
///
/// The first harmonic (harm=2) shows as orange; the second harmonic (harm=3) is yellow; and the third harmonic harm=4) is green, and so on.
///
/// For each audio frame, we will render a total of 6 + 6 = 12 polygons - one for each harmonic of each tri-octave.
/// totalPointCount =  96 * 12 = 1,152   // total number of points provided by the interpolator
/// sixOctPointCount = 72 * 12 =  864   // total number of points of the 72 possible fundamentals
///
/// This copies the OverlappedHarmonics2 visualization in the Polaris project.
/// Created by Keith Bromley on 29  Dec 2021.  Animated in Aug 2022.


import SwiftUI


struct OverlappedHarmonics: View {
    
    var body: some View {
        ZStack {
            ColorRectangles(columnCount: 36)                            // struct code in VisUtilities file
            OverlappedHarmonics_Live()
            VerticalLines(columnCount: 36)                              // struct code in VisUtilities file
            HorizontalLines(rowCount: 2, offset: 0.0)                   // struct code in VisUtilities file
            HorizontalNoteNames(rowCount: 2, octavesPerRow: 3)          // struct code in VisUtilities file
        }
    }
}



struct OverlappedHarmonics_Live: View {
    @EnvironmentObject var audioManager: AudioManager  // Observe the instance of AudioManager passed from ContentView
    @EnvironmentObject var settings: Settings

    var body: some View {

        let now = Date()
        let time = now.timeIntervalSinceReferenceDate
        let frequency: Double = 0.05  // 1 cycle per 20 seconds
        let myOffset: Double = 0.5 * ( 1.0 + cos(2.0 * Double.pi * frequency * time )) // oscillates between 0 and +1
        let harmonicCount: Int = 6  // The total number of harmonics rendered.    0 <= har <= 5     1 <= harm <= 6
        let harmHueOffset: Double = 1.0 / ( Double(harmonicCount) ) // harmHueOffset = 1/6

        // Convert the observed array-of-Floats into an AnimatableVector:
        let muSpectrumA = AnimatableVector(values: audioManager.muSpectrum)

        ForEach( 0 ... 1, id: \.self) { rowNum in        //  rowNum = 0, 1  refers to the lower and upper halfpane
            DoubleMuSpectrumA_Live_Shape(vector: muSpectrumA,
                                         row: rowNum,
                                         offset: myOffset )
                .foregroundColor( (settings.selectedColorScheme == .light) ? Color.white : Color.darkGray )
                .animation(Animation.linear, value: muSpectrumA)
        }

        
        // Now, paint the space between the vertOffsets with the fillColor:
        Fill_Gap_Shape(offset: myOffset)
            .foregroundColor( (settings.selectedColorScheme == .light) ? Color.white : Color.darkGray )
            .animation(Animation.linear, value: myOffset)

        // This concludes the rendering of the fundamental (harm==1) muSpectrum on the upper and lower screen halves.

        ForEach( 0 ... 1, id: \.self) { rowNum in        //  rowNum = 0, 1  refers to the lower and upper halfpane
            ForEach( 1 ..< harmonicCount, id: \.self) { har in      // We rendered the har=0 fundamental spectrum above.
                let hueIndex: Double = Double(har) * harmHueOffset          // hueIndex = 1/6, 2/6, 3/6, 4/6, 5/6
                OverlappedHarmonics_Live_Shape(settings: self._settings,
                                                vector: muSpectrumA,
                                                row: rowNum,
                                                offset: myOffset,
                                                har: har )
                    .fill( Color(hue: hueIndex, saturation: 1.0, brightness: 1.0 ),
                           strokeColor: Color( (settings.selectedColorScheme == .dark) ? .black : .white ),
                           lineWidth: 1 )       // See the extension to Shape() at the bottom of this file.
                    .animation(Animation.linear, value: muSpectrumA)
            } // end of ForEach(har)
        } // end of ForEach(rowNum)
    }
}



struct DoubleMuSpectrumA_Live_Shape: Shape {
    var vector: AnimatableVector        // Declare a variable called vector of type Animatable vector
    var row: Int
    var offset: Double

    public var animatableData: AnimatableVector {
        get { vector }
        set { vector = newValue }
    }
    
    public func path(in rect: CGRect) -> Path {
        let width: Double  = rect.width
        let height: Double = rect.height
        let halfHeight: Double = height * 0.5
        let quarterHeight: Double = height * 0.25
        var x : Double = 0.0       // The drawing origin is in the upper left corner.
        var y : Double = 0.0       // The drawing origin is in the upper left corner.
        var upRamp : Double = 0.0
        var magY: Double = 0.0     // used as a preliminary part of the "y" value
        let octavesPerRow: Int = 3
        let pointsPerRow: Int = pointsPerNote * notesPerOctave * octavesPerRow  //  12 * 12 * 3 = 432
        let vertOffset: Double = offset * quarterHeight

        // Render lower 3 octaves in the bottom halfpane, and the upper 3 octaves in the upper halfplane:
        var path = Path()
        if (row == 0) {
            path.move   ( to: CGPoint( x: width, y: halfHeight) )   // right midpoint
            path.addLine( to: CGPoint( x: width, y: height))        // right bottom
            path.addLine( to: CGPoint( x: 0.0,   y: height))        // left bottom
            path.addLine( to: CGPoint( x: 0.0,   y: halfHeight))    // left midpoint
        } else {
            path.move   ( to: CGPoint( x: width, y: halfHeight) )   // right midpoint
            path.addLine( to: CGPoint( x: width, y: 0.0))           // right top
            path.addLine( to: CGPoint( x: 0.0,   y: 0.0))           // left top
            path.addLine( to: CGPoint( x: 0.0,   y: halfHeight))    // left midpoint
        }

        for point in 1 ..< pointsPerRow {
            // upRamp goes from 0.0 to 1.0 as point goes from 0 to pointsPerRow:
            upRamp =  Double(point) / Double(pointsPerRow)
            x = upRamp * width
            let spectrumPoint: Double = row==0 ? Double(vector[point]) : Double(vector[pointsPerRow + point])
            magY = spectrumPoint * halfHeight
            magY = min(max(0.0, magY), halfHeight)
            y = row==0 ? halfHeight + vertOffset + magY : halfHeight - vertOffset - magY
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.addLine( to: CGPoint( x: width, y: halfHeight + vertOffset ) )
        path.closeSubpath()
        return path
    }
}



struct Fill_Gap_Shape: Shape {
    var offset: Double
    
    public func path(in rect: CGRect) -> Path {
        let width: Double  = rect.width
        let height: Double = rect.height
        let halfHeight: Double = height * 0.5
        let quarterHeight: Double = height * 0.25
        let vertOffset: Double = offset * quarterHeight

        // Generate a closed path denoting the space between the vertOffsets:
        var path = Path()  // start at the upper right
        path.move   ( to: CGPoint( x: width,  y: halfHeight - vertOffset) )    // upper right
        path.addLine( to: CGPoint( x: 0.0,    y: halfHeight - vertOffset))     // upper left
        path.addLine( to: CGPoint( x: 0.0,    y: halfHeight + vertOffset))     // lower left
        path.addLine( to: CGPoint( x: width,  y: halfHeight + vertOffset))     // lower right
        path.closeSubpath()
        return path
    }
}



struct OverlappedHarmonics_Live_Shape: Shape {
    @EnvironmentObject var settings: Settings
    var vector: AnimatableVector        // Declare a variable called vector of type Animatable vector
    var row: Int
    var offset: Double
    var har: Int
    
    public var animatableData: AnimatableVector {
        get { vector }
        set { vector = newValue }
    }
    
    public func path(in rect: CGRect) -> Path {
        let width: Double  = rect.width
        let height: Double = rect.height
        let halfHeight: Double = height * 0.5
        let quarterHeight: Double = height * 0.25
        let vertOffset: Double = offset * quarterHeight
        var upRamp : Double = 0.0
        
        var x : Double = 0.0       // The drawing origin is in the upper left corner.
        var y : Double = 0.0       // The drawing origin is in the upper left corner.

        let harmonicCount: Int = 6  // The total number of harmonics rendered.    0 <= har <= 5     1 <= harm <= 6
        let harmIncrement: [Int]  = [ 0, 12, 19, 24, 28, 31 ]   // The increment (in notes) for the six harmonics:
        //                           C1  C2  G2  C3  E3  G3
        
        let offsetFraction: Double = Double(harmonicCount-1 - har) / Double(harmonicCount-1) // 4/5, 3/5, 2/5, 1/5, 0/5
        let harmOffset: Double = offsetFraction * vertOffset

        let octavesPerRow: Int = 3
        let pointsPerRow: Int = pointsPerNote * notesPerOctave * octavesPerRow  //  12 * 12 * 3 = 432
        
        var path = Path()
        path.move( to: CGPoint( x: 0.0, y: row==0 ? halfHeight+harmOffset : halfHeight-harmOffset))  // left baseline

        for point in 0 ..< pointsPerRow {                   // pointsPerRow = 12 * 12 * 3 = 432
            upRamp =  Double(point) / Double(pointsPerRow)  // upRamp goes from 0.0 to 1.0 as point goes from 0 to pointsPerRow
            x = upRamp * width
            /*
            Optionally, in order to decrease the visual clutter (and to be more musically meaningfull),
            we multiply the value of the harmonics (har = 1 through 5) by the value of the fundamental (har = 0).
            So, if there is no meaningful amplitude for the fundamental, then its harmonics are not shown
            (or at least shown only with low amplitude).
            */
            let fundamentalAmp = (settings.optionOn == false) ? 1.0 : Double(vector[row==0 ? point : pointsPerRow+point])
            let newPoint: Int = ( pointsPerNote * harmIncrement[har] ) + point
            var cumulativePoints: Int = row==0 ? newPoint : pointsPerRow + newPoint
            if(cumulativePoints >= eightOctPointCount) { cumulativePoints = eightOctPointCount-1 }
        
            var magY: Double = Double(vector[cumulativePoints]) * halfHeight * fundamentalAmp
            if( cumulativePoints == eightOctPointCount-1 ) { magY = 0 }
            y = row==0 ? halfHeight + harmOffset + magY : halfHeight - harmOffset - magY
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.addLine( to: CGPoint( x: width, y: row==0 ? halfHeight+harmOffset : halfHeight-harmOffset ) ) // right baseline
        path.addLine( to: CGPoint( x: 0.0,   y: row==0 ? halfHeight+harmOffset : halfHeight-harmOffset ) ) // left baseline
        path.closeSubpath()
        return path
    }
}



// https://stackoverflow.com/questions/56786163/swiftui-how-to-draw-filled-and-stroked-shape
extension Shape {
    public func fill<Shape: ShapeStyle>(
        _ fillContent: Shape,
        strokeColor  : Color,
        lineWidth    : CGFloat

    ) -> some View {
        ZStack {
            self.fill(fillContent)
            self.stroke( strokeColor, lineWidth: lineWidth)

        }
    }
}
