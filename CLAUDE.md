# magicMice — Project Specification

> An iOS app that transforms your iPad into a hardware keyboard + gesture control surface when used with an external display.

-----

## 1. Concept

When an iPad is connected to an external monitor via USB-C, Stage Manager moves apps to the big screen — but the iPad screen sits idle. **magicMice** reclaims that screen as a fully interactive control surface: a custom software keyboard, a gesture trackpad zone, and a macro bar. No jailbreak. App Store compliant.

The experience goal: pick up the iPad, set the external display as your workspace, and never reach for a physical keyboard again.

-----

## 2. Target Users

- iPad Pro / iPad Air users with external monitors
- Minimalist desk setups (no physical keyboard)
- Users who want macro/shortcut keys that a hardware keyboard can’t offer
- Power users who hot-swap between touch and keyboard workflows

-----

## 3. Platform & Requirements

|Item            |Detail                                                      |
|----------------|------------------------------------------------------------|
|Platform        |iOS / iPadOS 17.0+                                          |
|Language        |Swift 5.9+                                                  |
|UI Framework    |SwiftUI (primary) + UIKit (gesture internals)               |
|Device target   |iPad only (iPhone excluded)                                 |
|External display|Stage Manager required (M1 iPad Pro / M2+ iPad Air or later)|
|Orientation     |Landscape only (keyboard surface)                           |
|Distribution    |App Store                                                   |

-----

## 4. Core Features

### 4.1 Keyboard Surface

- Full QWERTY layout rendered in SwiftUI
- Keys send input via UIKeyInput / insertText() to the currently focused app on external display
- Modifier keys: `⌘` `⌥` `⌃` `⇧` — sticky (tap to arm, tap again to release)
- Function row: esc F1–F12 (collapsed by default, swipe up to reveal)
- Number row visible by default
- Special keys: tab caps lock delete return
- Key repeat on long press (with haptic tick via `UIImpactFeedbackGenerator`)
- Keyboard layouts: QWERTY, AZERTY, QWERTZ (switchable in settings)

### 4.2 Gesture / Scroll Zone

- Occupies the bottom ~28% of the iPad screen **below** the keyboard (MacBook-style: keyboard above, trackpad below)
- Single finger pan → scroll (vertical and horizontal)
- Two finger pan → scroll with inertia (mimics trackpad momentum)
- Two finger pinch → zoom (maps to `⌘+` / `⌘-`)
- Two finger rotate → not used (reserved)
- Three finger swipe left/right → `⌘[` / `⌘]` (back/forward)
- Three finger swipe up → App Exposé / app switcher (`⌘Tab`)
- Tap → UITouch tap at pointer location (limited to scroll context)
- Visual: subtle grid texture, animated ripple on touch

### 4.3 Macro Bar

- Horizontal scrollable strip between gesture zone and keyboard
- 8 default slots + unlimited custom slots
- Each slot: custom label + key combo
- Defaults: ⌘Z ⌘X ⌘C ⌘V ⌘S ⌘A ⌘W ⌘T
- Long press any slot → edit mode (label + key combo picker)
- Drag to reorder
- Haptic feedback on activation

### 4.4 Layout Modes

Switchable via a floating toggle pill:

|Mode             |Description                                          |
|-----------------|-----------------------------------------------------|
|**Full**         |Gesture zone + macro bar + keyboard                  |
|**Keyboard only**|Macro bar + keyboard (more key real estate)          |
|**Trackpad only**|Full screen gesture zone (for scroll-heavy tasks)    |
|**Macro pad**    |4×4 grid of macro buttons (presentation / media mode)|

### 4.5 External Display Detection

- App detects when a second screen is connected (`UIScreen.screens.count > 1`)
- Shows an onboarding prompt if no external display is detected
- Reminds user to enable Stage Manager
- Gracefully works without external display (keyboard still functional on iPad itself)

-----

## 5. Input Injection Architecture

### Text Input

User taps key
    → magicMice captures touch
    → Builds UIKeyCommand or calls insertText()
    → Dispatches to first responder via UIApplication.shared.sendAction

### Modifier Keys

- Maintained as @State var activeModifiers: UIKeyModifierFlags
- Composited onto next keypress then cleared (unless caps lock)
- Visual state: key lights up when armed

### Scroll / Pan

UIPanGestureRecognizer on gesture zone
    → translation delta → UIScrollView synthetic scroll
    → Posted via UIApplication event queue

### Shortcuts

Gesture recognized (e.g. 3-finger swipe up)
    → Maps to UIKeyCommand equivalent
    → Dispatched via sendAction(_:to:from:for:)

-----

## 6. App Architecture

magicMice/
├── App/
│   ├── magicMiceApp.swift          # App entry, scene setup
│   └── AppDelegate.swift
│
├── Core/
│   ├── InputEngine/
│   │   ├── KeyDispatcher.swift     # insertText, UIKeyCommand dispatch
│   │   ├── ModifierState.swift     # Sticky modifier logic
│   │   ├── GestureTranslator.swift # Pan/pinch → scroll/shortcut
│   │   └── HapticEngine.swift      # UIImpactFeedbackGenerator wrapper
│   │
│   ├── DisplayMonitor.swift        # UIScreen observation, Stage Manager detection
│   └── MacroStore.swift            # Macro persistence (SwiftData)
│
├── UI/
│   ├── RootView.swift              # Layout mode switcher, top-level
│   ├── GestureZone/
│   │   ├── GestureZoneView.swift
│   │   └── GestureZoneViewModel.swift
│   ├── Keyboard/
│   │   ├── KeyboardView.swift      # Full keyboard layout
│   │   ├── KeyView.swift           # Individual key with press animation
│   │   ├── FunctionRowView.swift   # F1–F12 collapsible row
│   │   └── KeyboardLayout.swift    # QWERTY/AZERTY/QWERTZ definitions
│   ├── MacroBar/
│   │   ├── MacroBarView.swift
│   │   ├── MacroSlotView.swift
│   │   └── MacroEditSheet.swift
│   └── Settings/
│       ├── SettingsView.swift
│       └── LayoutPickerView.swift
│
├── Models/
│   ├── Key.swift                   # Key model (label, keyCode, modifiers)
│   ├── MacroSlot.swift             # SwiftData model
│   └── LayoutMode.swift            # Enum: full, keyboardOnly, trackpadOnly, macroPad
│
└── Resources/
    ├── Assets.xcassets
    └── Localizable.strings

-----

## 7. UI Design Direction

**Aesthetic: Refined Dark Hardware**

- Inspired by high-end mechanical keyboards and Apple’s own Magic Keyboard
- Dark background (`#0A0A0F`) with subtle key surfaces (`#1C1C24`)
- Key labels in clean monospaced font (`SF Mono` or `JetBrains Mono`)
- Pressed state: key illuminates with a cool blue-white glow + depth press animation
- Modifier keys armed: amber/orange tint
- Gesture zone: dark glass texture with subtle animated grain
- Macro bar: frosted glass pill strip
- No gradients, no rounded-everything — geometric precision

**Key press animation:**

swift
// Scale down slightly + shadow shrink on press
.scaleEffect(isPressed ? 0.94 : 1.0)
.shadow(radius: isPressed ? 1 : 4)
.animation(.spring(response: 0.08, dampingFraction: 0.7), value: isPressed)

**Color tokens:**

swift
background:      #0A0A0F
keySurface:      #1C1C24
keyBorder:       #2E2E3E
keyLabel:        #E8E8F0
modifierArmed:   #F5A623
accentBlue:      #4A9EFF
gestureZone:     #111118
macroBar:        #16161E (frosted)

-----

## 8. Permissions & Entitlements

|Permission                             |Reason                          |
|---------------------------------------|--------------------------------|
|No special entitlements needed         |Input via public UIKit APIs only|
|`UIRequiredDeviceCapabilities` → `ipad`|iPad only                       |
|No microphone / camera / location      |Not needed                      |

This is intentionally clean — no controversial entitlements that could trigger App Store review issues.

-----

## 9. Settings

- Keyboard layout (QWERTY / AZERTY / QWERTZ)
- Key click sound (on/off)
- Haptic intensity (light / medium / heavy / off)
- Gesture zone sensitivity (1–5 scale, affects pan velocity multiplier)
- Scroll direction (natural / reversed)
- Macro slots management (add / remove / reorder / export)
- Layout mode default
- Theme (Dark only for v1.0)

-----

## 10. SwiftData Models

swift
@Model
class MacroSlot {
    var id: UUID
    var label: String
    var systemImage: String?        // SF Symbol name
    var keyCode: Int                // UIKeyboardHIDUsage raw value
    var modifiers: Int              // UIKeyModifierFlags raw value
    var sortOrder: Int
    var colorHex: String?
}

-----

## 11. Onboarding Flow

**Screen 1 — Welcome**

- App name + tagline: “Your iPad. Reimagined as a keyboard.”
- Illustration of iPad + external display setup

**Screen 2 — Connect Display**

- Step-by-step: connect USB-C → enable Stage Manager
- Live detection: green checkmark when second screen found

**Screen 3 — Try it**

- Interactive demo: tap keys, try gesture zone
- “You’re ready” CTA

-----

## 12. Explicit Non-Goals (v1.0)

- ❌ Bluetooth HID peripheral mode (iOS blocks third-party access)
- ❌ Pointer / cursor XY injection (no public API)
- ❌ Mouse emulation
- ❌ iPhone support
- ❌ iCloud sync (local only for v1.0)
- ❌ Multiple language IME (English only for v1.0)

-----

## 13. Future Roadmap (v1.x+)

- **v1.1** — Custom themes / key colors per row
- **v1.2** — iCloud sync for macro sets
- **v1.3** — App-aware profiles (different macro set per app via `UIApplication.shared.connectedScenes`)
- **v1.4** — Apple Pencil support on gesture zone for precision scroll
- **v2.0** — Companion Mac app for full pointer injection over LAN (same architecture as BT-KVM, different transport)

-----

## 14. App Store Metadata

**Name:** magicMice  
**Subtitle:** Keyboard & Gestures for iPad  
**Category:** Productivity  
**Keywords:** keyboard, trackpad, external display, stage manager, shortcuts, macro, ipad pro  
**Age Rating:** 4+

**Description (short):**

> magicMice turns your iPad screen into a full keyboard and gesture control surface — perfect
