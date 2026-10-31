//
//  KeyboardTouchModel+TwoFingers.swift
//  Keyboarding
//
//  What the host's two-finger hold (KeyboardTwoFingerHold) does to the keys.
//  Two fingers down is not yet the hold — it is just as often rolling typing,
//  where the first key lifts while the second is still down — so it only keeps
//  either finger from becoming a key's hold. The hold taking is what spends the
//  keys: every press still down then ends there, typing nothing, opening no
//  alternates, gliding nothing. A key that lifted before then has already typed.
//

import Foundation

extension KeyboardTouchModel {
	/// Two fingers are (or are no longer) down. While they are, no key starts a
	/// hold; a finger already down gives up its hold for the rest of its touch.
	func suspendHolds(_ suspended: Bool) {
		holdsSuspended = suspended
		guard suspended else { return }
		for originID in activeTouches.keys {
			holdForfeited.insert(originID)
			cancelLongPress(originID: originID)
		}
	}

	/// The two-finger hold took: every press still down ends without a key.
	func spendActiveTouches() {
		for (originID, touchID) in activeTouches {
			spentTouches.insert(touchID)
			cancel(originID: originID)
		}
	}

	/// A spent touch lifted; it is no longer anything to ignore.
	func forget(touchID: UUID) {
		spentTouches.remove(touchID)
	}
}
