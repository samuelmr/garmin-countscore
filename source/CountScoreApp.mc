import Toybox.Activity;
import Toybox.ActivityRecording;
import Toybox.Application;
import Toybox.Application.Properties;
import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class CountScoreApp extends Application.AppBase {

    var scoreA as Number = 0;
    var scoreB as Number = 0;

    hidden var activitySession as ActivityRecording.Session?;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
        var storedA = Storage.getValue("scoreA");
        var storedB = Storage.getValue("scoreB");
        if (storedA instanceof Number) {
            scoreA = storedA;
        }
        if (storedB instanceof Number) {
            scoreB = storedB;
        }
    }

    function onStop(state as Dictionary?) as Void {
        // Best-effort only: onStop() isn't guaranteed to run if the app is
        // killed abruptly. exitApp() (below) is the real, reliable path for
        // stopping and saving a recording -- this just avoids leaving one
        // orphaned in the more common case of a clean shutdown that still
        // doesn't go through our own Exit menu item.
        stopRecording();
    }

    function onSettingsChanged() as Void {
        WatchUi.requestUpdate();
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        // Only offer to record an activity on devices that actually support
        // it -- skip straight to the score screen otherwise.
        if (Toybox has :ActivityRecording) {
            var menu = new Rez.Menus.SportMenu();
            return [ menu, new CountScoreSportPickerDelegate(menu) ];
        }
        return [ new CountScoreView(), new CountScoreDelegate() ];
    }

    function incrementA() as Void {
        scoreA += 1;
        saveScores();
        WatchUi.requestUpdate();
    }

    function incrementB() as Void {
        scoreB += 1;
        saveScores();
        WatchUi.requestUpdate();
    }

    // Touch-only undo for an accidental point or a disqualified goal (see
    // CountScoreDelegate's onSwipe()) -- there's no button equivalent, so a
    // button-only watch has to fall back to resetting and replaying the
    // score by hand.
    function decrementA() as Void {
        if (scoreA > 0) {
            scoreA -= 1;
            saveScores();
            WatchUi.requestUpdate();
        }
    }

    function decrementB() as Void {
        if (scoreB > 0) {
            scoreB -= 1;
            saveScores();
            WatchUi.requestUpdate();
        }
    }

    function resetScores() as Void {
        scoreA = 0;
        scoreB = 0;
        saveScores();
        WatchUi.requestUpdate();
    }

    hidden function saveScores() as Void {
        Storage.setValue("scoreA", scoreA);
        Storage.setValue("scoreB", scoreB);
    }

    function getTeamAColor() as Number {
        return Properties.getValue("TeamAColor") as Number;
    }

    function getTeamBColor() as Number {
        return Properties.getValue("TeamBColor") as Number;
    }

    // Called once, right after the sport picker closes. Does nothing if a
    // recording is already running or the device doesn't support it.
    function startRecording(sport as Activity.Sport) as Void {
        if (!(Toybox has :ActivityRecording) || (activitySession != null)) {
            return;
        }
        activitySession = ActivityRecording.createSession({
            :name => WatchUi.loadResource(Rez.Strings.AppName) as String,
            :sport => sport,
            :subSport => Activity.SUB_SPORT_GENERIC
        });
        activitySession.start();
    }

    // Stops and saves whatever's currently recording, if anything. Safe to
    // call even when nothing is recording.
    function stopRecording() as Void {
        if (activitySession == null) {
            return;
        }
        activitySession.stop();
        activitySession.save();
        activitySession = null;
    }

    // Remembers the sport picker's choice so it can be pre-focused next
    // launch (see CountScoreSportPickerDelegate). `sport` is null for
    // "don't record". Deliberately stored as a plain Number rather than the
    // menu item's Symbol id -- Garmin's own docs warn that Symbol values
    // "should not be used for persistent data" since they can change
    // across builds.
    function rememberSportChoice(sport as Activity.Sport?) as Void {
        Storage.setValue("lastSportChoice", sport != null ? (sport as Number) : NO_SPORT_CHOICE);
    }

    function getLastSportChoice() as Number {
        var stored = Storage.getValue("lastSportChoice");
        return (stored instanceof Number) ? stored : NO_SPORT_CHOICE;
    }

}

// Sentinel meaning "don't record" -- used both when that was explicitly
// chosen and when nothing has been chosen yet (a first-ever launch), since
// both should pre-focus the menu on :sport_none.
const NO_SPORT_CHOICE = -1;

function getApp() as CountScoreApp {
    return Application.getApp() as CountScoreApp;
}

// Shared by the menu's "Reset score" item and the DOWN button/swipe-up
// gesture, so resetting always goes through a confirmation step and can't
// happen from a single accidental button press or touch. This uses the same
// Menu widget as the main menu (rather than WatchUi.Confirmation) so the
// "Reset"/"Cancel" choice lays out and behaves exactly like every other
// menu in the app, on every device.
function confirmReset() as Void {
    WatchUi.pushView(new Rez.Menus.ResetConfirmMenu(), new CountScoreResetMenuDelegate(), WatchUi.SLIDE_UP);
}

// The one place the app actually exits, so a recording in progress is
// always stopped and saved first rather than left orphaned and
// uncontrollable (see the app's getInitialView()/startRecording() comments
// -- once the process exits, there's no API to reattach to a session).
function exitApp() as Void {
    getApp().stopRecording();
    System.exit();
}
