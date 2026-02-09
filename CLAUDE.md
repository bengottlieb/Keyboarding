# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Keyboarding** is a Swift Package Manager (SPM) library for iOS and macOS that provides custom keyboard implementations with hardware keyboard detection. It bridges SwiftUI views with UIKit's keyboard system to enable custom on-screen keyboards while seamlessly handling hardware keyboard connections.

Platforms:
- iOS 17+
- macOS 15+

## Build Commands

```bash
# Build the package
swift build

# Open test harness in Xcode
open TestHarness/KeyboardTestHarness.xcodeproj
```

## Architecture

### Core Components

The framework is organized into three main areas:

#### 1. Keyboard Hosting (`Sources/Keyboarding/Keyboard Hosting/`)
Manages the integration between SwiftUI and UIKit keyboard systems.

- **View.addKeyboard.swift**: Primary API - View extensions that attach keyboards to any SwiftUI view. Three variants:
  - Custom keyboard view with keymap
  - Keymap-based keyboard (uses built-in KeyboardView)
  - System keyboard only (no custom view)

- **KeyboardProviding.swift**: Core UIViewRepresentable bridge. Wraps content in a UIViewController and manages focus state, keyboard visibility, and key event routing through a Coordinator pattern.

- **KeyboardProviding.Container.swift**: UIView subclass conforming to UIKeyInput. Acts as the first responder that receives keyboard input. Handles the `UseSystemKeyboard` logic to switch between custom and system keyboards based on hardware keyboard connection state.

- **HardwareKeyboard.swift**: ObservableObject singleton tracking hardware keyboard connection via GameKit's GCKeyboard notifications. Exposes `keyboardIsConnected` property used throughout the framework.

- **SendKey.swift**: Defines the `KeySender` type and `HandleKeyPress` callback pattern. Key presses flow through the environment (`.sendKey`) to allow parent views to handle input.

- **UseSystemKeyboard.swift**: Enum controlling keyboard behavior (`.always`, `.ifHardware`, `.never`).

#### 2. Keyboard View (`Sources/Keyboarding/Keyboard View/`)
Visual representation and data model for on-screen keyboards.

- **KeyboardView.swift**: SwiftUI view that renders a keyboard from a Keymap. Calculates key sizing based on geometry, positions keys in rows. iOS-only with macOS stub.

- **Keymap.swift**: Data structure defining keyboard layout as 2D array of KeyDefinitions. Includes presets like `.qwerty` and `.qwertyWithDismiss`.

- **KeyDefinition.swift**: Represents a single key with type classification (letter, delete, dismiss, tab, enter, space, navigation), optional string value, and optional KeyPress. Can be created from string literals or KeyType enum.

- **KeyCapView.swift**: Individual key button view (not examined in detail).

#### 3. Key Styles (`Sources/Keyboarding/Key Styles/`)
ButtonStyles for keyboard keys.

- **RoundKeyboardKeyButtonStyle.swift**: Custom button styling for keyboard keys.

### Key Data Flow

1. User calls `.addKeyboard(isFocused:useSystemKeyboard:keymap:handleKeyPress:)` on a SwiftUI view
2. KeyboardProviding wraps the view in a UIViewRepresentable container
3. Container becomes first responder when focused
4. Key presses (from custom or system keyboard) are converted to KeyDefinition
5. KeyDefinition is sent through the `sendKey` environment value
6. Parent's `handleKeyPress` closure receives KeyDefinition and returns KeyPress.Result
7. Hardware keyboard events are captured via `.onKeyPress` modifier and converted to KeyDefinition

### Important Integration Details

- The framework uses Suite framework's `Gestalt.isHardwareKeyboardConnected` property (extension in KeyboardProviding.Container.swift)
- Focus state is bidirectional: both the view and the coordinator track focus changes
- The Container cycles first responder status when `useSystemKeyboard` changes to update the `inputView`
- KeyDefinition can be created from KeyPress to enable hardware keyboard integration

## Dependencies

- **Suite** (1.2.50+): ios-tooling/Suite.git - Provides Gestalt utility and macro support
- **GameKit**: Used for hardware keyboard detection (GCKeyboard) on iOS

## Testing

The TestHarness Xcode project provides a working example. Run it to see the keyboard in action and test different configurations.
