import SwiftUI

@MainActor
final class BreakContent: ObservableObject {
    @Published var imageData: Data?
    @Published var message: String = ""
    @Published var refreshID = UUID()

    func refresh() {
        message = TimerViewModel.breakMessages.randomElement() ?? "Relájate un momento."
        refreshID = UUID()
        TimerViewModel.fetchCatImage { [weak self] data in
            self?.imageData = data
        }
    }
}

struct FloatingAlertView: View {
    @ObservedObject var breakContent: BreakContent
    let title: String
    let buttonText: String
    let accentColor: Color
    let isBreak: Bool
    let onDismiss: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            if isBreak, let imageData = breakContent.imageData, let nsImage = NSImage(data: imageData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .onTapGesture {
                        breakContent.refresh()
                    }
            } else {
                Image(systemName: accentColor == .red ? "brain.head.profile.fill" : "cup.and.saucer.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(accentColor)
            }

            Text(title)
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)

            Text(isBreak ? breakContent.message : "Ready to focus again?")
                .font(.title3.weight(.medium))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(accentColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .id(breakContent.refreshID)

            if isBreak {
                Button {
                    onDismiss()
                } label: {
                    Text(buttonText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            } else {
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
            }

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
        .padding(.horizontal, isBreak ? 8 : 20)
        .padding(.vertical, 16)
        .frame(width: isBreak ? 380 : 380, height: isBreak ? nil : 280)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
    }
}
