import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// Two-team goal counter. Confirmed on real hardware (Venu Sq 2): extending
// WatchUi.BehaviorDelegate meant the system pre-translated taps and most
// swipes into Behavior calls (onSelect(), onBack(), onNextPage(),
// onPreviousPage()) before onTap()/onSwipe() ever ran, making left/right
// zone scoring by touch impossible. Extending WatchUi.InputDelegate
// directly instead avoids that: every input arrives as a raw event, with
// no translation layer in the way, and onTap()/onSwipe() genuinely fire.
//
// Holding a button doesn't need to be timed by hand: also confirmed on real
// hardware, the firmware itself detects a hold and relabels the key as
// WatchUi.KEY_MENU by the time onKey()/onKeyReleased() are called,
// regardless of which physical button was actually held -- so it's just
// another key value to check for, like KEY_UP or KEY_ESC. (An earlier
// version of this file tried to detect holds itself by timing
// onKeyPressed()/onKeyReleased(); that looked right in the simulator but
// did nothing on a real Venu Sq 2, because it was checking the *original*
// key that was pressed, which isn't what a held release reports.)
//
// Physical buttons:
//   - Watches with dedicated UP/DOWN buttons (fenix, Forerunner,
//     Instinct, ...): UP -> left team, START/ENTER -> right team,
//     DOWN -> reset (with confirmation), BACK/ESC -> exit.
//   - Watches with only two buttons (Venu Sq, D2 Mach, ...):
//     START/ENTER -> left team, BACK/ESC -> right team.
//   - Holding a button opens the Reset/Exit menu -- except START/ENTER on
//     at least the Venu Sq 2, where holding it is claimed by the system's
//     own shortcut menu before this app ever sees it. Every button that
//     isn't START/ENTER is unaffected, so the menu stays reachable by
//     holding any of those instead.
//   - fenix-style watches have a 5th physical button, LIGHT, but it isn't
//     exposed as a distinguishable input by Connect IQ at all (confirmed
//     on a real fenix 5 Plus), so it isn't used here.
// Touch, where available:
//   - Tapping the left/right half of the screen scores that team.
//   - Swiping left/right *undoes* a point for that team instead (an
//     accidental tap or a disqualified goal) -- there's no button
//     equivalent; a button-only watch has to reset and replay the score by
//     hand if it needs correcting.
//   - Swiping up asks to reset; swiping down exits -- the same actions as
//     the DOWN/BACK buttons on a four-button watch, since a two-button
//     touch watch has no physical DOWN/BACK-equivalent swipe otherwise.
class CountScoreDelegate extends WatchUi.InputDelegate {

    // Whether this watch has dedicated UP/DOWN buttons, read once from the
    // official button-inventory bitmask.
    hidden var fourButtonLayout as Boolean;

    function initialize() {
        InputDelegate.initialize();
        var buttons = System.getDeviceSettings().inputButtons;
        fourButtonLayout = ((buttons & System.BUTTON_INPUT_UP) != 0) && ((buttons & System.BUTTON_INPUT_DOWN) != 0);
    }

    // onKeyReleased() (below) does the real work, but onKey() -- the
    // combined "pressed and released" event -- needs its own override too:
    // confirmed on a real Venu Sq 2 that without it, the system's own
    // default action for a key still runs *in addition* to whatever
    // onKeyReleased() does, e.g. ESC both scored a point *and* exited the
    // app from the same press.
    function onKey(keyEvent as KeyEvent) as Boolean {
        return true;
    }

    function onKeyReleased(keyEvent as KeyEvent) as Boolean {
        var key = keyEvent.getKey();

        if (key == WatchUi.KEY_MENU) {
            showMenu();
        } else if (isSelectKey(key)) {
            handleSelect();
        } else if (key == WatchUi.KEY_ESC) {
            handleBack();
        } else if (key == WatchUi.KEY_UP) {
            handlePreviousPage();
        } else if (key == WatchUi.KEY_DOWN) {
            handleNextPage();
        }
        return true;
    }

    function onTap(clickEvent as ClickEvent) as Boolean {
        var coordinates = clickEvent.getCoordinates();
        var width = System.getDeviceSettings().screenWidth;
        if (coordinates[0] < (width / 2)) {
            getApp().incrementA();
        } else {
            getApp().incrementB();
        }
        return true;
    }

    function onSwipe(swipeEvent as SwipeEvent) as Boolean {
        var direction = swipeEvent.getDirection();
        if (direction == WatchUi.SWIPE_LEFT) {
            getApp().decrementA();
        } else if (direction == WatchUi.SWIPE_RIGHT) {
            getApp().decrementB();
        } else if (direction == WatchUi.SWIPE_UP) {
            handleNextPage();
        } else if (direction == WatchUi.SWIPE_DOWN) {
            handlePreviousPage();
        } else {
            return InputDelegate.onSwipe(swipeEvent);
        }
        return true;
    }

    hidden function showMenu() as Void {
        WatchUi.pushView(new Rez.Menus.MainMenu(), new CountScoreMenuDelegate(), WatchUi.SLIDE_UP);
    }

    hidden function isSelectKey(key as Number) as Boolean {
        return key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START;
    }

    hidden function handleSelect() as Void {
        if (fourButtonLayout) {
            getApp().incrementB();
        } else {
            getApp().incrementA();
        }
    }

    hidden function handleBack() as Void {
        if (fourButtonLayout) {
            exitApp();
        } else {
            getApp().incrementB();
        }
    }

    hidden function handlePreviousPage() as Void {
        if (fourButtonLayout) {
            getApp().incrementA();
        } else {
            // Only reachable via a swipe-down gesture on two-button touch
            // watches -- there's no physical UP button to press.
            exitApp();
        }
    }

    hidden function handleNextPage() as Void {
        // Physical DOWN button on four-button watches; a swipe-up gesture
        // on two-button touch watches. Both cases want the same thing.
        confirmReset();
    }

}
