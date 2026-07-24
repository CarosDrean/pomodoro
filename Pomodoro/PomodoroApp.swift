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

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupPopover()
        setupStatusItem()
        setupLocalMonitor()
        observeTimer()

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

    private func updateIcon() {
        guard let button = statusItem.button else { return }

        let symbolName: String
        let color: NSColor

        if timerVM.phase != .idle {
            switch timerVM.phase {
            case .work:
                symbolName = "brain.head.profile.fill"
                color = timerVM.isRunning ? .systemRed : .systemRed
            case .shortBreak:
                symbolName = "cup.and.saucer.fill"
                color = timerVM.isRunning ? .systemGreen : .systemGreen
            case .longBreak:
                symbolName = "moon.zzz.fill"
                color = timerVM.isRunning ? .systemBlue : .systemBlue
            case .idle:
                symbolName = "timer"
                color = .labelColor
            }
        } else {
            symbolName = "timer"
            color = .labelColor
        }

        let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Pomodoro")?
            .withSymbolConfiguration(config)
        button.image = image
        button.contentTintColor = color

        if timerVM.phase != .idle {
            button.title = " \(timerVM.formattedTime)"
        } else {
            button.title = ""
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
}

private extension NSEvent {
    var isOptionKeyDown: Bool {
        modifierFlags.contains(.option)
    }
}
