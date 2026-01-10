import SwiftUI

struct SpeakingOverlay: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack(spacing: 12) {
            // Speaker icon with animation
            SpeakerWaveView(isSpeaking: appState.isSpeaking)
            
            Text("Speaking...")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
        }
        .frame(width: 180, height: 50)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 8)
    }
}

struct SpeakerWaveView: View {
    let isSpeaking: Bool
    
    @State private var animationPhase: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 4) {
            // Speaker icon
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: 18))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.2, green: 0.9, blue: 0.6),
                            Color(red: 0.1, green: 0.7, blue: 0.8)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            // Animated sound waves
            HStack(spacing: 3) {
                ForEach(0..<4, id: \.self) { index in
                    SoundWaveBar(
                        index: index,
                        phase: animationPhase,
                        isSpeaking: isSpeaking
                    )
                }
            }
        }
        .onAppear {
            if isSpeaking {
                startAnimation()
            }
        }
        .onChange(of: isSpeaking) { _, speaking in
            if speaking {
                startAnimation()
            }
        }
    }
    
    private func startAnimation() {
        withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
            animationPhase = 1
        }
    }
}

struct SoundWaveBar: View {
    let index: Int
    let phase: CGFloat
    let isSpeaking: Bool
    
    private var animatedHeight: CGFloat {
        guard isSpeaking else { return 0.2 }
        
        let offset = Double(index) * 0.25
        let wave = sin((phase * .pi * 2) + (offset * .pi * 2))
        return 0.3 + (CGFloat(wave) + 1) * 0.35
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.2, green: 0.9, blue: 0.6),
                        Color(red: 0.1, green: 0.7, blue: 0.8)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 3, height: animatedHeight * 24)
            .animation(.easeInOut(duration: 0.15), value: animatedHeight)
    }
}

#Preview("Speaking") {
    SpeakingOverlay()
        .environmentObject({
            let state = AppState()
            state.isSpeaking = true
            return state
        }())
        .padding(40)
        .background(Color.gray.opacity(0.5))
}
