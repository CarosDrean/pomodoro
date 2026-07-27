import SwiftUI

struct FloatingAlertView: View {
    let title: String
    let message: String
    let buttonText: String
    let accentColor: Color
    let isBreak: Bool
    let imageData: Data?
    let onDismiss: () -> Void
    let onSkip: () -> Void
    let onImageTap: (() -> Void)?

    @State private var imageWidth: CGFloat = 380

    private var adaptiveWidth: CGFloat {
        max(380, imageWidth)
    }

    var body: some View {
        VStack(spacing: 16) {
            if isBreak, let imageData, let nsImage = NSImage(data: imageData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .onTapGesture {
                        onImageTap?()
                    }
                    .onAppear {
                        let rep = NSBitmapImageRep(data: imageData)
                        if let w = rep?.size.width, let h = rep?.size.height, h > 0 {
                            let ratio = w / h
                            let screenH = NSScreen.main?.frame.height ?? 900
                            let maxH = screenH * 2 / 3 - 180
                            imageWidth = max(380, maxH * ratio + 60)
                        }
                    }
            } else {
                Image(systemName: accentColor == .red ? "brain.head.profile.fill" : "cup.and.saucer.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(accentColor)
            }

            Text(title)
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)

            Text(message)
                .font(.title3.weight(.medium))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(accentColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

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
        .padding(30)
        .frame(width: isBreak ? adaptiveWidth : 380, height: isBreak ? nil : 280)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
    }
}
