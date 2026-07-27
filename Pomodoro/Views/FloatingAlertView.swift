import SwiftUI

struct FloatingAlertView: View {
    let title: String
    let message: String
    let buttonText: String
    let accentColor: Color
    let isBreak: Bool
    let onDismiss: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: accentColor == .red ? "brain.head.profile.fill" : "cup.and.saucer.fill")
                .font(.system(size: 48))
                .foregroundStyle(accentColor)

            Text(title)
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)

            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                onDismiss()
            } label: {
                Text(buttonText)
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)

            if isBreak {
                Button {
                    onSkip()
                } label: {
                    Text("Skip break")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(40)
        .frame(width: 380, height: isBreak ? 310 : 280)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
    }
}
