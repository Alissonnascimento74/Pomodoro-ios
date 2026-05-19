import SwiftUI

struct ContentView: View {
    
    // MARK: - State
    @State private var remainingSeconds: Int = 1500   // tempo atual em segundos
    @State private var isRunning: Bool = false        // timer rodando ou pausado
    @State private var timer: Timer? = nil            // referência ao timer (nil = nenhum ativo)
    @State private var isWorkSession: Bool = true     // true = foco, false = pausa
    @State private var completedSessions: Int = 0     // quantos pomodoros concluídos

    // MARK: - Constants
    
    let workDuration: Int = 1500   // 25 minutos em segundos
    let breakDuration: Int = 300   // 5 minutos em segundos
    let maxSessions: Int = 4       // meta de 4 pomodoros

    // MARK: - Colors (preto, roxo, dourado)
    let backgroundColor = Color(red: 0.06, green: 0.04, blue: 0.10)
    let goldColor       = Color(red: 1.00, green: 0.84, blue: 0.00)
    let purpleColor     = Color(red: 0.60, green: 0.20, blue: 0.90)

    // MARK: - Computed Properties
    // Propriedades computadas: calculam o valor toda vez que são acessadas

    // duração total da sessão atual
    var totalDuration: Int {
        isWorkSession ? workDuration : breakDuration
    }

    // progresso de 0.0 a 1.0 para o anel circular
    var progress: Double {
        1.0 - Double(remainingSeconds) / Double(totalDuration)
    }

    // cor do anel muda conforme a sessão
    var ringColor: Color {
        isWorkSession ? goldColor : purpleColor
    }

    // label de sessão
    var sessionLabel: String {
        isWorkSession ? "FOCUS" : "BREAK"
    }

    // converte segundos em "MM:SS"
    var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Body
    var body: some View {
        ZStack {

            // --- Fundo escuro cobrindo toda a tela ---
            backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 36) {

                // --- Título com espaçamento entre letras (kerning) ---
                Text("POMODORO")
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .foregroundColor(goldColor)
                    .kerning(8)

                // --- Label da sessão atual ---
                Text(sessionLabel)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(isWorkSession ? goldColor.opacity(0.6) : purpleColor.opacity(0.8))
                    .kerning(6)

                // --- Anel de progresso circular ---
                ZStack {

                    // Trilho do anel (fundo quase invisível)
                    Circle()
                        .stroke(Color.white.opacity(0.06), lineWidth: 8)
                        .frame(width: 280, height: 280)

                    // Anel de progresso (cresce conforme o tempo passa)
                    // .trim(from:to:) = desenha só uma fatia do círculo
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            ringColor,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 280, height: 280)
                        .rotationEffect(.degrees(-90))              // começa no topo
                        .animation(.linear(duration: 1), value: progress) // animação suave

                    // Timer no centro do anel
                    Text(formattedTime)
                        .font(.system(size: 70, weight: .thin, design: .monospaced))
                        .foregroundColor(.white)
                }

                // --- Pontinhos de sessões completadas ---
                HStack(spacing: 10) {
                    ForEach(0..<maxSessions, id: \.self) { index in
                        Circle()
                            .fill(index < completedSessions ? goldColor : Color.white.opacity(0.12))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut, value: completedSessions)
                    }
                }

                // --- Botões: Reset · Play/Pause · Skip ---
                HStack(spacing: 44) {

                    // Botão Reset
                    Button {
                        resetTimer()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 20, weight: .light))
                            .foregroundColor(.white.opacity(0.45))
                            .frame(width: 54, height: 54)
                            .background(Color.white.opacity(0.05))
                            .clipShape(Circle())
                    }

                    // Botão principal Play / Pause
                    Button {
                        if isRunning { stopTimer() } else { startTimer() }
                    } label: {
                        Image(systemName: isRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(backgroundColor)
                            .frame(width: 80, height: 80)
                            .background(ringColor)
                            .clipShape(Circle())
                            .shadow(color: ringColor.opacity(0.45), radius: 20)
                    }

                    // Botão Skip
                    Button {
                        skipSession()
                    } label: {
                        Image(systemName: "forward.end.fill")
                            .font(.system(size: 20, weight: .light))
                            .foregroundColor(.white.opacity(0.45))
                            .frame(width: 54, height: 54)
                            .background(Color.white.opacity(0.05))
                            .clipShape(Circle())
                    }
                }

                // --- Contador de sessões em texto ---
                Text("\(completedSessions) of \(maxSessions) sessions completed")
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundColor(.white.opacity(0.22))
                    .kerning(2)
            }
        }
    }

    // MARK: - Functions

    func startTimer() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if self.remainingSeconds > 0 {
                self.remainingSeconds -= 1
            } else {
                self.sessionCompleted()
            }
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    func resetTimer() {
        stopTimer()
        remainingSeconds = isWorkSession ? workDuration : breakDuration
    }

    // Chamada quando o tempo chega a zero
    func sessionCompleted() {
        stopTimer()
        if isWorkSession {
            // Só conta ponto ao terminar sessão de foco
            completedSessions = min(completedSessions + 1, maxSessions)
        }
        // Alterna entre foco e pausa
        isWorkSession.toggle()
        remainingSeconds = isWorkSession ? workDuration : breakDuration
    }

    // Chamada pelo botão Skip
    func skipSession() {
        stopTimer()
        if isWorkSession {
            completedSessions = min(completedSessions + 1, maxSessions)
        }
        isWorkSession.toggle()
        remainingSeconds = isWorkSession ? workDuration : breakDuration
    }
}

#Preview {
    ContentView()
}
