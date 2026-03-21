import XCTest
@testable import magicMice

final class ModifierStateTests: XCTestCase {
    func testToggleOn() {
        let state = ModifierState()
        state.toggle(.command)
        XCTAssertTrue(state.isCommandArmed)
    }

    func testToggleOff() {
        let state = ModifierState()
        state.toggle(.command)
        state.toggle(.command)
        XCTAssertFalse(state.isCommandArmed)
    }

    func testConsumeAfterKeypress_clearesNonCaps() {
        let state = ModifierState()
        state.toggle(.command)
        state.toggle(.shift)
        state.toggle(.alphaShift)
        state.consumeAfterKeypress()
        XCTAssertFalse(state.isCommandArmed)
        XCTAssertFalse(state.isShiftArmed)
        XCTAssertTrue(state.isCapsLockOn)  // caps lock persists
    }
}

final class MacroSlotDefaultsTests: XCTestCase {
    func testDefaultSlotsCount() {
        let slots = MacroSlot.makeDefaults()
        XCTAssertEqual(slots.count, 8)
    }

    func testDefaultSlotsSortOrder() {
        let slots = MacroSlot.makeDefaults()
        XCTAssertEqual(slots.map(\.sortOrder), Array(0..<8))
    }
}
