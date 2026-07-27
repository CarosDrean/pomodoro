import SwiftUI
import Combine

@main
struct PomodoroApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    let timerVM = TimerViewModel()
    private var localMonitor: Any?
    private var cancellables = Set<AnyCancellable>()
    private var floatingWindow: NSWindow?
    private var reappearTimer: Timer?
    private var pauseTimer: Timer?
    private var imageResizeCancellable: AnyCancellable?
    let breakContent = BreakContent()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupPopover()
        setupStatusItem()
        setupLocalMonitor()
        observeTimer()
        observeAlert()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.showPopover()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showPopover()
        return false
    }

    // MARK: - Setup

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 280, height: 350)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(
            rootView: PopoverContent(viewModel: timerVM)
        )
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            updateIconImage()
            button.action = #selector(iconClicked)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    private func setupLocalMonitor() {
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self else { return event }
            if self.popover.isShown,
               let window = event.window,
               window != self.popover.contentViewController?.view.window,
               window != self.statusItem.button?.window {
                self.popover.performClose(nil)
            }
            return event
        }
    }

    // MARK: - Observers

    private func observeTimer() {
        timerVM.$phase
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateIconImage()
            }
            .store(in: &cancellables)

        timerVM.$timeRemaining
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateIconTitle()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.timerVM.checkDayChange()
            }
            .store(in: &cancellables)
    }

    private func observeAlert() {
        timerVM.$alertInfo
            .receive(on: DispatchQueue.main)
            .sink { [weak self] alertInfo in
                if let info = alertInfo {
                    self?.showFloatingAlert(info)
                } else {
                    self?.dismissFloatingAlert()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Icon

    private func updateIconImage() {
        guard let button = statusItem.button else { return }

        let symbolName: String
        switch timerVM.phase {
        case .work:
            symbolName = "brain.head.profile.fill"
        case .shortBreak:
            symbolName = "cup.and.saucer.fill"
        case .longBreak:
            symbolName = "moon.zzz.fill"
        case .idle:
            symbolName = "timer"
        }

        let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Pomodoro")?
            .withSymbolConfiguration(config) {
            image.isTemplate = true
            button.image = image
        }
        button.contentTintColor = nil
        updateIconTitle()
    }

    private func updateIconTitle() {
        guard let button = statusItem.button else { return }
        if timerVM.phase != .idle {
            let font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.menuBarFont(ofSize: 0).pointSize, weight: .regular)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font
            ]
            button.attributedTitle = NSAttributedString(string: " \(timerVM.formattedTime)", attributes: attrs)
        } else {
            button.attributedTitle = NSAttributedString(string: "")
        }
    }

    // MARK: - Popover

    @objc private func iconClicked() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem.button else { return }
        timerVM.checkDayChange()
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Floating Alert

    private func showFloatingAlert(_ info: AlertInfo) {
        dismissFloatingAlert()

        NSApp.activate(ignoringOtherApps: true)

        if info.isBreak {
            breakContent.refresh()
        }

        let alertView = FloatingAlertView(
            breakContent: breakContent,
            title: info.title,
            message: info.message,
            buttonText: info.buttonText,
            accentColor: info.color,
            isBreak: info.isBreak
        ) { [weak self] in
            if info.isBreak {
                self?.hideBreakAlertForPause()
            } else {
                self?.timerVM.acknowledgeAlert()
            }
        } onSkip: { [weak self] in
            self?.timerVM.skip()
        }

        let hostingView = NSHostingController(rootView: alertView)

        let window = NSWindow(contentViewController: hostingView)
        window.styleMask = [.borderless]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = true
        window.hasShadow = true

        if info.isBreak, let screen = NSScreen.main {
            let screenHeight = screen.frame.height
            let windowHeight = screenHeight * 2 / 3
            let windowWidth: CGFloat = 380

            let x = (screen.frame.width - windowWidth) / 2
            let y = (screenHeight - windowHeight) / 2
            window.setFrame(NSRect(x: x, y: y, width: windowWidth, height: windowHeight), display: true)
            hostingView.view.frame = NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight)

            imageResizeCancellable = breakContent.$imageData
                .receive(on: DispatchQueue.main)
                .sink { [weak window] imageData in
                    guard let window, let imageData, let rep = NSBitmapImageRep(data: imageData) else { return }
                    let imgW = rep.size.width
                    let imgH = rep.size.height
                    guard imgH > 0 else { return }
                    let ratio = imgW / imgH
                    let contentHeight = windowHeight - 120
                    let imageWidth = contentHeight * ratio
                    let newWidth = max(380, imageWidth + 16)
                    let screen = NSScreen.main!
                    let x = (screen.frame.width - newWidth) / 2
                    let y = (screenHeight - windowHeight) / 2
                    window.setFrame(NSRect(x: x, y: y, width: newWidth, height: windowHeight), display: true)
                }
        } else {
            hostingView.view.frame = CGRect(x: 0, y: 0, width: 380, height: 280)
            window.center()
        }

        window.makeKeyAndOrderFront(nil)

        floatingWindow = window

        let interval: TimeInterval = timerVM.phase == .work ? 5.0 : 0.5
        reappearTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, self.timerVM.alertInfo != nil else { return }
                guard let win = self.floatingWindow else { return }
                win.orderFrontRegardless()
                if self.timerVM.phase != .work {
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
        }
    }

    private func dismissFloatingAlert() {
        reappearTimer?.invalidate()
        reappearTimer = nil
        pauseTimer?.invalidate()
        pauseTimer = nil
        imageResizeCancellable?.cancel()
        imageResizeCancellable = nil
        floatingWindow?.close()
        floatingWindow = nil
    }

    private func hideBreakAlertForPause() {
        reappearTimer?.invalidate()
        reappearTimer = nil
        floatingWindow?.orderOut(nil)

        pauseTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, self.timerVM.alertInfo != nil else { return }

                self.breakContent.refresh()

                guard let win = self.floatingWindow else { return }
                win.orderFrontRegardless()
                NSApp.activate()
                NSRunningApplication.current.activate(options: [.activateIgnoringOtherApps])

                self.reappearTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
                    Task { @MainActor in
                        guard let self = self, self.timerVM.alertInfo != nil else { return }
                        guard let win = self.floatingWindow else { return }
                        win.orderFrontRegardless()
                        NSApp.activate(ignoringOtherApps: true)
                    }
                }
            }
        }
    }
}

private extension NSEvent {
    var isOptionKeyDown: Bool {
        modifierFlags.contains(.option)
    }
}
