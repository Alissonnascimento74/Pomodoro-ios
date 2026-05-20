import SwiftUI
struct ContentView: View {
    // MARK: - State.
    
    /// Time left on the current timer, in seconds. Starts at 25 minutes (1500s).
    @State private var remainingSeconds: Int = 1500
    
    /// Whether the timer is currently counting down.
    @State private var isRunning: Bool = false
    
    /// Reference to the active Timer so we can invalidate it later.
    @State private var timer: Timer? = nil
    
    /// True during a focus session, false during a break session.
    @State private var isWorkSession: Bool = true
    
    /// How many focus sessions the user has finished in the current cycle.
    @State private var completedSessions: Int = 0
    
    // MARK: - Constants.
    
    /// Length of a focus session in seconds (25 min).
    let workDuration: Int = 1500
    
    /// Length of a break session in seconds (5 min).
    let breakDuration: Int = 300
    
    /// Total focus sessions per cycle before a long rest.
    let maxSessions: Int = 4
    
    // MARK: - Colors.
    
    /// App background - very dark almost black.
    let backgroundColor = Color(red: 0.010, green: 0.04, blue: 0.010)
    
    /// Accent color used during a focus session.
    let goldColor       = Color(red: 1.00, green: 0.84, blue:0.00)
    
    /// Accent color used during a break session.
    let purpleColor     = Color(red: 0.60, green: 0.20, blue:0.90)
    
    
    // MARK: - Computed properties.
    
    /// Total seconds for the active session (focus or break).
    /// Used to calculate progress.
    var totalDuration: Int {
        isWorkSession ? workDuration : breakDuration
    }
    
    /// Ring progress from 0.0 (just started) to 1.0 (finished).
    var progress: Double {
        1.0 - Double(remainingSeconds) / Double(totalDuration)
    }
    
    /// Ring color changes depending on focus or break mode.
    var ringColor: Color {
        isWorkSession ? goldColor : purpleColor
    }
    
    /// Label shown above the timer ("FOCUS" or "BREAK").
    var sessionLabel: String {
        isWorkSession ? "FOCUS" : "BREAK"
    }
    
    /// Remaining time formatted as "MM:SS".
    var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes , seconds)
    }
    
    // MARK: - Body.
    
    var body: some View {
        ZStack {
            // Full-screen dark background behind everything.
            backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 36){
                // App title at the top.
                Text("POMODORO")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(goldColor)
                    .kerning(4)
                
                // Session label ("FOCUS" or "BREAK"), color follows the current mode.
                Text(sessionLabel)
                    .font(.system(size:20,weight: .medium, design: . monospaced))
                    .foregroundColor(isWorkSession ? goldColor.opacity(0.6): purpleColor.opacity(0.8))
                    .kerning(2.0)
                
                // Progress ring + countdown text stacked together.
                ZStack{
                    // Faint background ring (the "track").
                    Circle ()
                        .stroke(Color .white.opacity(0.06), lineWidth: 14)
                        .frame(width:250, height:250)
                    
                    // Foreground ring that fills as time passes.
                    // The -90° rotation makes it start filling from the top (12 o'clock).
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(ringColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                        .frame(width: 250, height: 250)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1.0), value: progress)
                    
                    // Countdown text in the middle of the ring.
                    Text(formattedTime)
                        .font(.system(size: 65, weight: .thin, design: .monospaced))
                        .foregroundColor(.white)
                }
                
                // Row of 4 dots showing how many focus sessions are complete.
                HStack(spacing:10){
                    ForEach(0..<maxSessions, id: \.self) { index in
                        Circle()
                            .fill(index < completedSessions ? goldColor : Color.white.opacity(0.12))
                            .frame(width: 10 , height:10)
                            .animation(.easeInOut, value: completedSessions)
                    }}
                
                    // Caption with the current progress.
                    Text("\(completedSessions) of \(maxSessions) sessions complete")
                        .font(.system(size:14, weight: .regular, design: .monospaced))
                        .foregroundColor(.white.opacity(0.22))
                        .kerning(2)
                    
                    // Control Buttons : reset, play/pause, skip.
                    HStack(spacing:44){
                        Button { resetTimer() } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size:20, weight: .light))
                                .foregroundColor(.white.opacity(0.45))
                                .frame(width: 54, height: 54)
                                .background(Color.white.opacity(0.05))
                                .clipShape(Circle())
                        }
                        
                        // Play/Pause - main action, big circle in the accent color.
                        Button {
                            if isRunning { stopTimer() } else {startTimer()}
                        } label : {
                            Image(systemName: isRunning ? "pause.fill" : "play.fill")
                                .font(.system(size:28, weight: .regular ))
                                .foregroundColor(backgroundColor)
                                .frame(width: 80, height: 80)
                                .background(ringColor)
                                .clipShape(Circle())
                                .shadow(color: ringColor.opacity(0.45),radius: 20)
                        }
                        
                        // Skip - jumps straight to the next session.
                        Button{ skipSession() } label : {
                            Image(systemName: "forward.end.fill")
                                .font(.system(size: 20, weight: .light))
                                .foregroundStyle(Color.white.opacity(0.45))
                                .frame(width: 54, height: 54)
                                .background(Color.white.opacity(0.05))
                                .clipShape(Circle())
                        }
                    }
                
            }
        }
    }

        // MARK: -  Timer actions.
    
        /// Starts the countdown. Fires once every second until time runs out.
        func startTimer(){
            isRunning = true
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true){ _ in
                if self.remainingSeconds > 0{
                    self.remainingSeconds -= 1
                }else{
                    // Time hit zero - move on to the next session.
                    self.sessionCompleted()
                }
            }
        }
    
        /// Pauses the countdown and releases the active timer.
        func stopTimer(){
            timer?.invalidate()
            timer = nil
            isRunning = false
        }
    
        /// Stops the timer and refills the clock to the current session's duration.
        func resetTimer(){
            stopTimer()
            remainingSeconds = isWorkSession ? workDuration : breakDuration
        }
    
        /// Called automatically when the timer reaches zero.
         /// Increments the sessions count (if it was a focus session) and switches mode.
        func sessionCompleted(){
            stopTimer()
            if isWorkSession{
                completedSessions = min(completedSessions + 1, maxSessions)
            }
            isWorkSession.toggle()
            remainingSeconds = isWorkSession ? workDuration : breakDuration
        }
    
        /// Triggered by the user when they want to skip the current session manually.
        func skipSession(){
            stopTimer()
            if isWorkSession{
                completedSessions = min(completedSessions + 1, maxSessions)
            }
            isWorkSession.toggle()
            remainingSeconds = isWorkSession ? workDuration : breakDuration
        }
    }
#Preview{
        ContentView()
    }
    
    
