import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class CountScoreView extends WatchUi.View {

    hidden const SCORE_FONT = Graphics.FONT_NUMBER_THAI_HOT;

    function initialize() {
        View.initialize();
    }

    function onUpdate(dc as Dc) as Void {
        var app = getApp();
        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var centerY = height / 2;

        var colorA = app.getTeamAColor();
        var colorB = app.getTeamBColor();

        dc.setColor(colorA, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 0, centerX, height);
        dc.setColor(colorB, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(centerX, 0, width - centerX, height);

        // Each score sits centered in its own half, independent of the dash.
        dc.setColor(contrastColor(colorA), Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX / 2, centerY, SCORE_FONT, app.scoreA.toString(), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(contrastColor(colorB), Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX + ((width - centerX) / 2), centerY, SCORE_FONT, app.scoreB.toString(), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // The dash is two plain rectangles, not a drawn "-" glyph, so its
        // size is ours to pick directly rather than fought over with a
        // clip region. Each half is colored the same as the score text on
        // that side, so it always reads clearly no matter what the two
        // team colors are set to.
        var dashWidth = dc.getTextDimensions("-", SCORE_FONT)[0] + 8;
        var dashHeight = 10;
        var halfDashWidth = dashWidth / 2;
        var dashTop = centerY - (dashHeight / 2);

        dc.setColor(contrastColor(colorA), Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(centerX - halfDashWidth, dashTop, halfDashWidth, dashHeight);

        dc.setColor(contrastColor(colorB), Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(centerX, dashTop, halfDashWidth, dashHeight);
    }

    // Perceived brightness of a 24-bit RGB color, 0 (black) to 255 (white).
    hidden function luma(color as Number) as Number {
        var r = (color >> 16) & 0xFF;
        var g = (color >> 8) & 0xFF;
        var b = color & 0xFF;
        return ((r * 299) + (g * 587) + (b * 114)) / 1000;
    }

    // Picks black or white text, whichever reads better on the given background.
    hidden function contrastColor(background as Number) as Number {
        return luma(background) > 140 ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE;
    }

}
