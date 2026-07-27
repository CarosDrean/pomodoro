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
            updateIcon()
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
            .combineLatest(timerVM.$timeRemaining)
            .combineLatest(timerVM.$isRunning)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, _ in
                self?.updateIcon()
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

    private func updateIcon() {
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

        if timerVM.phase != .idle {
            button.title = " \(timerVM.formattedTime)"
        } else {
            button.title = ""
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
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Floating Alert

    private func showFloatingAlert(_ info: AlertInfo) {
        dismissFloatingAlert()

        NSApp.activate(ignoringOtherApps: true)

        let alertView = FloatingAlertView(
            title: info.title,
            message: info.message,
            buttonText: info.buttonText,
            accentColor: info.color,
            isBreak: info.isBreak,
            imageData: info.imageData
        ) { [weak self] in
            if info.isBreak {
                self?.hideBreakAlertForPause()
            } else {
                self?.timerVM.acknowledgeAlert()
            }
        } onSkip: { [weak self] in
            self?.timerVM.skip()
        } onImageTap: { [weak self] in
            guard let self else { return }
            TimerViewModel.fetchCatImage { data in
                Task { @MainActor in
                    guard var currentInfo = self.timerVM.alertInfo else { return }
                    currentInfo.imageData = data
                    self.timerVM.alertInfo = currentInfo
                }
            }
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
            let contentHeight = windowHeight - 60

            var windowWidth: CGFloat = 380
            if let imageData = info.imageData, let rep = NSBitmapImageRep(data: imageData) {
                let imgW = rep.size.width
                let imgH = rep.size.height
                if imgH > 0 {
                    let ratio = imgW / imgH
                    windowWidth = max(380, contentHeight * ratio + 60)
                }
            }

            let x = (screen.frame.width - windowWidth) / 2
            let y = (screenHeight - windowHeight) / 2
            window.setFrame(NSRect(x: x, y: y, width: windowWidth, height: windowHeight), display: true)
            hostingView.view.frame = NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight)
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
                NSApp.activate()
                NSRunningApplication.current.activate(options: [.activateIgnoringOtherApps])
            }
        }
    }

    private func dismissFloatingAlert() {
        reappearTimer?.invalidate()
        reappearTimer = nil
        pauseTimer?.invalidate()
        pauseTimer = nil
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

                TimerViewModel.fetchCatImage { data in
                    Task { @MainActor in
                        guard var info = self.timerVM.alertInfo else { return }
                        info.imageData = data
                        self.timerVM.alertInfo = info

                        guard let win = self.floatingWindow else { return }
                        win.orderFrontRegardless()
                        NSApp.activate()
                        NSRunningApplication.current.activate(options: [.activateIgnoringOtherApps])

                        self.reappearTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
                            Task { @MainActor in
                                guard let self = self, self.timerVM.alertInfo != nil else { return }
                                guard let win = self.floatingWindow else { return }
                                win.orderFrontRegardless()
                                NSApp.activate()
                                NSRunningApplication.current.activate(options: [.activateIgnoringOtherApps])
                            }
                        }
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
