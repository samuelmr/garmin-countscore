import Toybox.Activity;
import Toybox.Lang;
import Toybox.WatchUi;

class CountScoreMenuDelegate extends WatchUi.MenuInputDelegate {

    function initialize() {
        MenuInputDelegate.initialize();
    }

    function onMenuItem(item as Symbol) as Void {
        if (item == :item_reset) {
            // No confirmation here: reaching this item already took a
            // deliberate hold-plus-select, unlike the single-gesture
            // DOWN-button/swipe-up shortcut (see confirmReset()), which
            // still asks first.
            getApp().resetScores();
        } else if (item == :item_exit) {
            exitApp();
        }
    }

}

class CountScoreResetMenuDelegate extends WatchUi.MenuInputDelegate {

    function initialize() {
        MenuInputDelegate.initialize();
    }

    function onMenuItem(item as Symbol) as Void {
        if (item == :item_confirm_reset) {
            getApp().resetScores();
        }
        // :item_cancel_reset (or the back button) needs no handling --
        // the menu just closes on its own.
    }

}

// Shown once at startup (see the app's getInitialView()). Starts a FIT
// recording for the chosen sport, if any, then switches to the actual
// score screen -- this view never comes back once that switch happens.
// Uses Menu2 rather than the legacy Menu used elsewhere in the app because
// only Menu2 supports pre-focusing an item (setFocus()/:focus), which is
// needed to default to whatever was chosen last time.
class CountScoreSportPickerDelegate extends WatchUi.Menu2InputDelegate {

    function initialize(menu as WatchUi.Menu2) {
        Menu2InputDelegate.initialize();
        var focusId = idForSport(getApp().getLastSportChoice());
        if (focusId != null) {
            var index = menu.findItemById(focusId);
            if (index >= 0) {
                menu.setFocus(index);
            }
        }
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var sport = sportFor(item.getId() as Symbol);
        getApp().rememberSportChoice(sport);
        if (sport != null) {
            getApp().startRecording(sport);
        }
        WatchUi.switchToView(new CountScoreView(), new CountScoreDelegate(), WatchUi.SLIDE_IMMEDIATE);
    }

    // Null means "don't record" (:sport_none, or the back button).
    hidden function sportFor(item as Symbol) as Activity.Sport? {
        if (item == :sport_soccer) {
            return Activity.SPORT_SOCCER;
        } else if (item == :sport_basketball) {
            return Activity.SPORT_BASKETBALL;
        } else if (item == :sport_volleyball) {
            return Activity.SPORT_VOLLEYBALL;
        } else if (item == :sport_hockey) {
            return Activity.SPORT_HOCKEY;
        } else if (item == :sport_american_football) {
            return Activity.SPORT_AMERICAN_FOOTBALL;
        } else if (item == :sport_rugby) {
            return Activity.SPORT_RUGBY;
        } else if (item == :sport_lacrosse) {
            return Activity.SPORT_LACROSSE;
        } else if (item == :sport_baseball) {
            return Activity.SPORT_BASEBALL;
        } else if (item == :sport_racket) {
            return Activity.SPORT_RACKET;
        } else if (item == :sport_team_sport) {
            return Activity.SPORT_TEAM_SPORT;
        } else if (item == :sport_running) {
            return Activity.SPORT_RUNNING;
        } else if (item == :sport_other) {
            return Activity.SPORT_GENERIC;
        }
        return null;
    }

    // The reverse of sportFor(), keyed by the stable Number stored by
    // rememberSportChoice() (never a Symbol -- see its comment for why).
    hidden function idForSport(sport as Number) as Symbol? {
        if (sport == NO_SPORT_CHOICE) {
            return :sport_none;
        } else if (sport == Activity.SPORT_SOCCER) {
            return :sport_soccer;
        } else if (sport == Activity.SPORT_BASKETBALL) {
            return :sport_basketball;
        } else if (sport == Activity.SPORT_VOLLEYBALL) {
            return :sport_volleyball;
        } else if (sport == Activity.SPORT_HOCKEY) {
            return :sport_hockey;
        } else if (sport == Activity.SPORT_AMERICAN_FOOTBALL) {
            return :sport_american_football;
        } else if (sport == Activity.SPORT_RUGBY) {
            return :sport_rugby;
        } else if (sport == Activity.SPORT_LACROSSE) {
            return :sport_lacrosse;
        } else if (sport == Activity.SPORT_BASEBALL) {
            return :sport_baseball;
        } else if (sport == Activity.SPORT_RACKET) {
            return :sport_racket;
        } else if (sport == Activity.SPORT_TEAM_SPORT) {
            return :sport_team_sport;
        } else if (sport == Activity.SPORT_RUNNING) {
            return :sport_running;
        } else if (sport == Activity.SPORT_GENERIC) {
            return :sport_other;
        }
        return null;
    }

}
