//
//  ContentView.swift
//  GuessTheFlag
//
//  Created by Chloe Van on 2024-01-11.
//
import SwiftUI

// custom modifier for specific set of modifiers for flag image
struct FlagImage: ViewModifier {
    func body(content: Content) -> some View {
        content
            .clipShape(.capsule)
            .shadow(radius: 5)
    }
}

// makes it easier to use our own modifier by making it an extension of the View
extension View {
    func flagStyle() -> some View {
        modifier(FlagImage())
    }
}

//Immutability in SwiftUI Views
//When we say a SwiftUI view (like ContentView) is immutable, we mean that the properties and layout defined within its body are fixed at the time of the view's creation. You cannot change these properties directly once they are set. However, SwiftUI allows for dynamic UIs through the use of property wrappers like @State, @Binding, @ObservedObject, etc.

// ContentView: This is a struct that conforms to the View protocol. In SwiftUI, everything that makes up your UI is a view, including ContentView. It's a user-defined component that can contain other views and define the layout and behavior of a part of your UI.

struct ContentView: View {
    // @State are property wrappers to manage the state of the view
    // A state, in SwiftUI, represents a piece of data that can change over time and affect the view's appearance or behavior. When a state changes, SwiftUI automatically recreates the view to reflect the new state.
    // @State: allows a view to re-render when the data changes. The view struct itself is still immutable, but the @State property can change, triggering a refresh of the view's body.
    @State var countries = ["Estonia", "France", "Germany", "Ireland", "Italy", "Nigeria", "Poland", "Spain", "UK", "Ukraine", "US"].shuffled()
    @State var correctAnswer = Int.random(in: 0...2)
    @State private var playerScore = 0
    @State private var showingScore = false
    @State private var scoreTitle = ""
    //This means showingScore and scoreTitle are mutable pieces of data that's external to the ContentView struct.
    //The struct itself doesn't change; rather, SwiftUI watches for changes and recreates the body of ContentView when changes.
    
    @State private var endGame = false
    @State private var roundCount = 1
    @State private var showEndGameAlert = false
    
    // originally used a single rotationAmount but that rotated all the flags once one was pressed.. because this var was being shared across all flags so when it changes, all flags reflect that change
    @State private var rotationAmounts = [0.0, 0.0, 0.0]
    @State private var opacities = [1.0, 1.0, 1.0]
    
    //  body: The body property is a crucial part of the View protocol. It's where you define the view's content and layout. SwiftUI expects every view to have a body property that returns some view. This returned view can be a combination of other views, like Text, Button, etc.
    var body: some View {
        ZStack {
            //            LinearGradient(colors: [.blue, .black], startPoint: .top, endPoint: .bottom)
            //                .ignoresSafeArea()
            
            // if you create two stops that are identical, the gradient goes away over time because it switches from one to the other
            
            RadialGradient(stops: [
                .init(color: Color(red: 0.1, green: 0.2, blue: 0.45), location: 0.3),
                .init(color: Color(red: 0.76, green: 0.15, blue: 0.26), location: 0.3)
            ],center: .top, startRadius: 200, endRadius: 700)
            .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                Text("Guess the Flag")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                
                // this VStack has 30 points spacing between the views inside it
                VStack(spacing:15) {
                    VStack {
                        // this has default spacing now
                        Text("Tap the flag of")
                            .foregroundStyle(.secondary) // secondary allows a little bit of the background color to shine through
                            .font(.subheadline.weight(.heavy))
                        
                        // subheadline and largeTitle are built-in sizes from iOs which are dynamic type, get bigger or smaller according to the user's settings
                        
                        Text(countries[correctAnswer])
//                            .foregroundStyle(.white)
                            .font(.largeTitle.weight(.semibold))
                    }
                    
                    // In SwiftUI, a closure is a block of code that can be passed around and executed at a later time.
                    ForEach(0..<3) { number in
                        // Button component is UI element that can trigger specific action when tapped. Takes in 1. Action as closure, and 2. Label as a view that defines the content of the button
                        Button { // the {} after Button defines the closure for button's action
                            // when flag is tapped
                            flagTapped(number) // this is a function call within the closure
                        } label: {
                            Image(countries[number])
                                .flagStyle()
                                /*.clipShape(.capsule)*/ // gives round edges
                                /*.shadow(radius: 5)*/ // gives tiny shadow, if no color specified its a light black color
                                .opacity(opacities[number])
                        }
                        .rotation3DEffect(
                            .degrees(rotationAmounts[number]), axis: /*@START_MENU_TOKEN@*/(x: 0.0, y: 1.0, z: 0.0)/*@END_MENU_TOKEN@*/
                        )
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(.regularMaterial)
                .clipShape(.rect(cornerRadius: 20))
                
                // remember spacers divide themselves up evenly. if we have four spacer() in this stack, they will take all the remaining space left, divide that space by four, and give each space one quarter.
                Spacer()
                
                Text("Score: \(playerScore)")
                    .foregroundStyle(.white)
                    .font(.title.bold())
                
                Text("Round: \(roundCount) of 8")
                    .foregroundStyle(.white)
                    .font(.caption)
            }
            .padding()
        }
        
        // we show alerts by making their isPresented condition true
        // reminder that $ denotes binding to a state variable, a binding provides both read and write access to the variable.You use $ when you want to create a two-way connection between a SwiftUI control and a state variable. This means that changes to the control's value will update the state variable and vice versa.
        .alert(scoreTitle, isPresented: $showingScore) {
            Button("Continue", action: {
                askQuestion()
                if showEndGameAlert {
                    endGame = true
                    showEndGameAlert = false
                }
            })
        } message: {
            //  There's no need for a binding to playerScore since you're only displaying the value, not modifying it. you use the variable without $ when you need to read its value or pass its value to a function or a control that doesn't require a Binding.
            Text("Your score is \(playerScore)")
        }
        
        // alert for end of the game
        // when alert is dismissed swiftUI will automatically set isPresented back to false?
        .alert("End Game", isPresented: $endGame) {
            Button("Restart", action: resetGame)
        } message: {
            Text("Your final score is \(playerScore)")
        }
    }
    
    
    // playerScore in this view does not require a binding because you are within the same view that owns playerScore. You're not setting up a two-way communication between playerScore and another view or component; you're just changing its value directly.
    func flagTapped(_ number: Int) {
        if number == correctAnswer {
            scoreTitle = "Correct"
            playerScore += 1
            // spin only if correct flag chosen
            withAnimation(.spring(duration:1, bounce: 0.5)) {
                rotationAmounts[number] += 360
                opacities = opacities.indices.map { $0 == number ? 1.0 : 0.25 }
            }
        } else {
            scoreTitle = "Wrong! Thats the flag of \(countries[number])"
        }
        
        if (roundCount < 8) {
            roundCount += 1
            showingScore = true
        } else {
            // show result of the last answer first
            showingScore = true
            // set flag to show end game alert
            showEndGameAlert = true
        }
    }
    
    func askQuestion() {
        if !endGame {
            countries.shuffle()
            correctAnswer = Int.random(in: 0...2)
            opacities = [1.0, 1.0, 1.0]
        }
    }
    
    func resetGame() {
        // reset score board and round count
        playerScore = 0
        roundCount = 1
        askQuestion()
    }
}

#Preview {
    ContentView()
}


//Recap
//ContentView and its body are immutable in the sense that their structure, once defined, cannot change.
//@State allows specific pieces of data to be mutable and for the view to update reactively when this data changes.
//SwiftUI manages the recreation of the view's body when @State properties change, allowing for dynamic and responsive UIs while maintaining the overall immutability of the view structures themselves.
