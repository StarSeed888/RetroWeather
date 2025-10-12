import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Math;
using Toybox.Application.Storage as Storage;
// imports: Position/Weather removed because countdown/sun-event functionality was removed
using Toybox.Application.Properties;

class RetroWeatherView extends WatchUi.WatchFace {

    // countdown/sun-event removed; no weather controller
    // Theme colors (will be set by loadColorTheme)
    var _matrixGreen = 0x00FF41;
    var _darkGreen = 0x008F11;
    var _brightGreen = 0x80FF80;
    var _black = 0x000000;
    var _weatherCtrl = null;
     private var _settingsPollCounter;


    // Tracks the currently observed sun event so we can compute a stable initial duration
    var _sunEventId = 0;
    var _sunEventTotalSecs = 0;
    // Hysteresis for visible bar changes to avoid immediate drops
    var _sunVisiblePrev = 0;
    var _sunVisibleStableCount = 0;

    function initialize() {
        WatchFace.initialize();
        // Initialize weather controller (will internally cache/refresh)
        try {
            _weatherCtrl = new WeatherControl();
        } catch (ex) {
            _weatherCtrl = null;
        }
        // Load color theme based on user settings (if present)
        loadColorTheme();
        // Restore any persisted sun-event state so visible bars stay consistent
        loadSunEventState();

        // settings poll counter
        _settingsPollCounter = 0;

    }

    // Restore persisted sun event id and initial seconds from Storage
    function loadSunEventState() as Void {
        try {
            var sid = Storage.getValue("SunEventId");
            var ssecs = Storage.getValue("SunEventInitialSecs");
            if (sid != null) {
                try {
                    _sunEventId = sid.toNumber();
                } catch (ex) { _sunEventId = 0; }
            }
            if (ssecs != null) {
                try {
                    _sunEventTotalSecs = ssecs.toNumber();
                } catch (ex) { _sunEventTotalSecs = 0; }
            }
            if (_sunEventTotalSecs <= 0) { _sunEventTotalSecs = 0; }
        } catch (ex) {
            // ignore storage errors
            _sunEventId = 0; _sunEventTotalSecs = 0;
        }
    }

    // Load color theme based on application property "ColorTheme"
    function loadColorTheme() as Void {
        var colorTheme = Properties.getValue("ColorTheme");
        if (colorTheme == null) {
            colorTheme = 0; // Default to Matrix Green
        }
        // If value comes back as string, try to coerce to number
        // (simple best-effort; property store may return number already)
        try {
            colorTheme = colorTheme.toNumber();
        } catch (ex) {
            // leave as-is if conversion fails
        }

        switch (colorTheme) {
            case 0: // Matrix Green
                _matrixGreen = 0x00FF41;
                _darkGreen = 0x008F11;
                _brightGreen = 0x80FF80;
                break;
            case 1: // Retro Cyan
                _matrixGreen = 0x00FFFF;
                _darkGreen = 0x008F8F;
                _brightGreen = 0x80FFFF;
                break;
            case 2: // Retro Amber
                _matrixGreen = 0xFFB000;
                _darkGreen = 0x8F6000;
                _brightGreen = 0xFFE080;
                break;
            case 3: // Retro Purple
                _matrixGreen = 0xBF40FF;
                _darkGreen = 0x6F258F;
                _brightGreen = 0xE080FF;
                break;
            case 4: // Retro Red
                _matrixGreen = 0xFF4040;
                _darkGreen = 0x8F2525;
                _brightGreen = 0xFF8080;
                break;
            case 5: // Retro Blue
                _matrixGreen = 0x4080FF;
                _darkGreen = 0x25508F;
                _brightGreen = 0x80B0FF;
                break;
            case 6: // Retro Orange (Commodore 64 style)
                _matrixGreen = 0xFF8000;
                _darkGreen = 0x8F4000;
                _brightGreen = 0xFFB050;
                break;
            case 7: // Retro Pink (Synthwave)
                _matrixGreen = 0xFF40A0;
                _darkGreen = 0x8F2560;
                _brightGreen = 0xFF80C0;
                break;
            case 8: // Retro Yellow (Amber alternative)
                _matrixGreen = 0xFFFF00;
                _darkGreen = 0x8F8F00;
                _brightGreen = 0xFFFF80;
                break;
            case 9: // Retro White (Classic terminal)
                _matrixGreen = 0xE0E0E0;
                _darkGreen = 0x808080;
                _brightGreen = 0xFFFFFF;
                break;
            default:
                _matrixGreen = 0x00FF41;
                _darkGreen = 0x008F11;
                _brightGreen = 0x80FF80;
        }
    // _black remains constant; no-op here to keep compatibility
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
        // Restore any persisted sun-event state so visible bars stay consistent
        loadColorTheme();
    
    }
    


    function getWindUnitString() as String {

    var windUnit = Properties.getValue("WindSpeedUnit");
    if (windUnit == null) {
        windUnit = 2; // default to mph
    }
    switch (windUnit) {
        case 0: return "m/s";
        case 1: return "km/h";
        case 2: return "mph";
        default: return "km/h";
    }
}





    // Update the view
    function onUpdate(dc as Dc) as Void {
        // Get and show the current time
        View.onUpdate(dc);

        _settingsPollCounter = (_settingsPollCounter + 1) % 5; // adjust 10 => poll interval
        if (_settingsPollCounter == 0) {
            loadColorTheme();
        }



        _weatherCtrl.refreshConditions();
        var clockTime = System.getClockTime();
        var view = View.findDrawableById("TimeLabel") as Text;
        // hide the small layout label because we draw a large block time instead
        view.setText("");

    // countdown removed

        // compute formatted time string according to device 12/24-hour setting
        var hour = clockTime.hour;
        var minute = clockTime.min.format("%02d");
        var is24Hour = System.getDeviceSettings().is24Hour;
        var displayHour = hour;
        var ampm = "";
        if (!is24Hour) {
            ampm = (displayHour >= 12) ? "PM" : "AM";
            if (displayHour == 0) { displayHour = 12; }
            else if (displayHour > 12) { displayHour = displayHour - 12; }
        }
    var timeMain = displayHour.format("%02d") + ":" + minute;
    var ampmText = "";
    if (!is24Hour) { ampmText = ampm; }

    var cx = dc.getWidth() / 2;
    var cy = dc.getHeight() / 2;
    var w = dc.getWidth();
    var h = dc.getHeight();
    var radius = (w < h) ? w/2 : h/2;
        // place the time slightly lower than vertical center (70% of centerY as requested)
    drawBlockText(dc, timeMain, cx, (cy * 0.70).toNumber(), 28, _matrixGreen);

    // perimeter seconds ticks removed

    // draw AM/PM as tiny separate text to the right of the block time
    if (ampmText != "") {
        var smallX = (cx + (radius * 0.50)).toNumber();
        var smallY = ((cy * 0.70) + (radius * 0.08)).toNumber();
        dc.setColor(_brightGreen, Graphics.COLOR_TRANSPARENT);
        dc.drawText(smallX * 1.10, smallY *0.75, Graphics.FONT_SYSTEM_SMALL, ampmText, Graphics.TEXT_JUSTIFY_CENTER);
    }

    // draw retro instruments around the time
    var temp = null; var wind = null; var windDir = null;
    if (_weatherCtrl != null) {
        try { _weatherCtrl.refreshConditions(); } catch (ex) {}
    temp = _weatherCtrl.getTemperature();
    wind = _weatherCtrl.getWindSpeed();
    windDir = _weatherCtrl.getWindBearing();
    }

    // Proportional positions
    var tempX = (cx - radius * 0.65).toNumber();
    var rightX = (cx + radius * 0.65).toNumber();
    

   
    // Wind gauge (right of time)
    drawWind(dc, (rightX * 0.60).toNumber(), (cy * .58).toNumber(), (radius * 0.36).toNumber(), wind, windDir);

    // Temperature gauge (left of time)
    drawTemperature(dc, (tempX * 2.95).toNumber(), (cy * .75).toNumber(), (radius * 0.36).toNumber(), temp);

    // Humidity icon: place in the lower 80% of the screen, aligned with the temperature gauge
    var humidity = null;
    if (_weatherCtrl != null) {
        try { humidity = _weatherCtrl.getHumidity(); } catch (ex) { humidity = null; }
    }
    drawHumidity(dc, (tempX * 2.95).toNumber(), (cy * .70).toNumber(), (radius * 0.36).toNumber(), humidity);

    // Consolidated small data strip below the main time (Temp | Humidity | Wind | Pressure)
    var pressure = null;
    if (_weatherCtrl != null) {
        try { pressure = _weatherCtrl.getPressure(); } catch (ex) { pressure = null; }
    }
    // Respect user property "ShowDataStrip" (0 = off, 1 = on). Default to 1 (on).
    var showData = Properties.getValue("ShowDataStrip");
    var showVal = 1;
    if (showData != null) {
        try { showVal = showData.toNumber(); } catch (ex) { showVal = 1; }
    }
    if (showVal != 0) {
        drawConsolidatedLabels(dc, cx, (cy * 1.35).toNumber(), (radius * 0.12).toNumber(), temp, humidity, wind, windDir, pressure);
    }

    // Sun event countdown bar (below the big time) - drawn by its own function
    var sunEvent = null;
    if (_weatherCtrl != null) {
        try { sunEvent = _weatherCtrl.getSunEventTime(); } catch (ex) { sunEvent = null; }
    }
    drawSunCountdown(dc, (cx * 1.03).toNumber(), (cy * 0.80 ).toNumber(), (radius * 0.36).toNumber(), sunEvent);

    // date display removed


        
    }

    // desaturate helper removed


    // countdown/sun-event removed

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // Draw block/wireframe text (colored outline, black fill) centered at (x,y)
    function drawBlockText(dc as Dc, text as String, x as Number, y as Number, size as Number, color as Number) as Void {
        // Select font based on size parameter
        var font;
        if (size >= 24) {
            font = Graphics.FONT_NUMBER_HOT;
        } else if (size >= 16) {
            font = Graphics.FONT_LARGE;
        } else {
            font = Graphics.FONT_MEDIUM;
        }

        // Draw subtle shadow for depth
        dc.setColor(_darkGreen, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + 2, y + 2, font, text, Graphics.TEXT_JUSTIFY_CENTER);

        // Draw colored outline by drawing the text at offsets
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        var stroke = (dc.getWidth() / 120).toNumber(); if (stroke < 1) { stroke = 1; }
        dc.setPenWidth(1);
        dc.drawText(x - stroke, y, font, text, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(x + stroke, y, font, text, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(x, y - stroke, font, text, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(x, y + stroke, font, text, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(x - stroke, y - stroke, font, text, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(x + stroke, y - stroke, font, text, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(x - stroke, y + stroke, font, text, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(x + stroke, y + stroke, font, text, Graphics.TEXT_JUSTIFY_CENTER);

        // Fill interior with black to achieve wireframe look
        dc.setColor(_black, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, text, Graphics.TEXT_JUSTIFY_CENTER);
       
    }

    
    // Draw a simple wind gauge: direction letter and speed bars
    function drawWind(dc as Dc, x as Number, y as Number, size as Number, speed as Number, dir as Number) as Void {
    // direction glyph (label disabled; keep gauge rendering)
    dc.setColor(_matrixGreen, Graphics.COLOR_TRANSPARENT);

        // speed bars
        var maxBars = 10;  // choose how many blocks maximum
        var divisor = 4.0;   

        var bars = 0;
        if (speed != null) {
            var candidate = Math.ceil(speed.toNumber()/divisor).toNumber();
            if (candidate > maxBars) {
                candidate = maxBars;
            }
            bars = candidate;
        }
        var bw = (size * 0.12).toNumber();
        if (bw < 3) {
            bw = 3;
        }
        // Determine user's wind unit so we can pick the correct threshold
        var unitVal = Properties.getValue("WindSpeedUnit");
        if (unitVal == null) { unitVal = 2; }
        try { unitVal = unitVal.toNumber(); } catch (ex) { unitVal = 2; }
        var speedThreshold = 30; // mph default
        if (unitVal == 2) { speedThreshold = 30; } // mph
        else if (unitVal == 3) { speedThreshold = 48; } // km/h
        else { speedThreshold = 13; } // m/s

        for (var i = 0; i < maxBars; i++) {
             var bx = (x - ((maxBars-1) * bw / 2) + i*(bw+2)).toNumber(); // centers bars around x
            var by = (y + size*0.15).toNumber();
            if (i < bars) {
                // Default to a dimmer theme color for filled bars; override to red when wind is strong
                var fillColor = _matrixGreen;
                try {
                    if (speed != null && speed.toNumber() >= speedThreshold) {
                        fillColor = 0xFF4040;
                    }
                } catch (ex) {}
                dc.setColor(fillColor, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(bx, by, bw, bw);
            } else {
                dc.setColor(_darkGreen, Graphics.COLOR_TRANSPARENT);
                dc.drawRectangle(bx, by, bw, bw);
            }
        }

    // numeric speed label (disabled in favor of consolidated strip)
    }

    // Draw temperature gauge: bars centered at freezing (0°C or 32°F)
    function drawTemperature(dc as Dc, x as Number, y as Number, size as Number, temp as Number) as Void {
            var barW = (size * 0.12).toNumber();
            if (barW < 3) {
                barW = 3;
            }
            var spacing = 2;

            // Determine freezing point depending on unit
            var unitVal = Properties.getValue("TemperatureUnit");
            if (unitVal == null) {
                unitVal = 1;
            } else {
                try {
                    unitVal = unitVal.toNumber();
                } catch (ex) {
                    unitVal = 1;
                }
            }
            var freeze = (unitVal == 2) ? 32 : 0; // F or C

            // Temperature availability
            var haveTemp = false;
            var t = 0;
            if (temp != null) {
                haveTemp = true;
                t = temp.toNumber();
            }

            // Static marker ranges based on unit selection
            var minV = -30; var maxV = 50; var step = 5;
            if (unitVal == 2) {
                // Fahrenheit: -30 .. 120 step 10
                minV = -30; maxV = 120; step = 10;
            }

            // Compute marker count
            var span = (maxV - minV).toNumber();
            var markerCount = Math.floor(span / step).toNumber() + 1;

            // Center markers at x
            var startX = (x - ((markerCount - 1) * (barW + spacing) / 2)).toNumber();
            var by = (y - barW / 2).toNumber();

            // (freeze marker not needed explicitly for static markers)

            // High temperature override threshold: 82F or 27C
            var highThreshold = (unitVal == 2) ? 82 : 27;

            // Draw markers left-to-right and fill up to temperature
            for (var i = 0; i < markerCount; i++) {
                var val = minV + i * step;
                var bx = (startX + i * (barW + spacing)).toNumber();
                var drawFilled = false;
                if (haveTemp) {
                    if (t >= val) {
                        drawFilled = true;
                    }
                }

                if (drawFilled) {
                    // If overall temp exceeds highThreshold, override to red
                    if (haveTemp && t >= highThreshold) {
                        dc.setColor(0xFF4040, Graphics.COLOR_TRANSPARENT);
                    } else if (val >= freeze) {
                        dc.setColor(_matrixGreen, Graphics.COLOR_TRANSPARENT);
                    } else {
                        dc.setColor(0x2F80FF, Graphics.COLOR_TRANSPARENT);
                    }
                    dc.fillRectangle(bx, by, barW, barW);
                } else {
                    dc.setColor(_darkGreen, Graphics.COLOR_TRANSPARENT);
                    dc.drawRectangle(bx, by, barW, barW);
                }
            }

            // numeric label above (current temperature) intentionally disabled; consolidated strip used instead

    }


    // Draw a tiny forecast icon (sun/cloud/rain) using pixel blocks
    function drawForecastIcon(dc as Dc, x as Number, y as Number, size as Number, cond as String) as Void {
        // very small 5x5 pixel style
        var block = (size * 0.18).toNumber();
        if (block < 2) {
            block = 2;
        }
        var startX = (x - (2.5*block)).toNumber();
        var startY = (y - (2.5*block)).toNumber();
        // Determine rain either from numeric condition codes or simple string heuristics
        var isRain = false;
        if (cond != null) {
            // Try to interpret cond as a number (weather condition code). If that fails,
            // skip numeric checks and assume non-rain.
            try {
                var cnum = cond.toNumber();
                // Common weather codes that indicate rain or showers
                var rainCodes = [3, 14, 15, 25, 26, 45, 50];
                for (var i = 0; i < rainCodes.size(); i++) {
                    if (rainCodes[i] == cnum) {
                        isRain = true;
                        break;
                    }
                }
            } catch (ex) {
                // Non-numeric condition; leave isRain false (safe fallback)
            }
        }
        if (isRain) {
            dc.setColor(_brightGreen, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(startX + block*1, startY + block*1, block, block*2);
            dc.fillRectangle(startX + block*3, startY + block*2, block, block*2);
        } else {
            dc.setColor(_brightGreen, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(startX + block*2, startY + block*1, block, block);
            dc.fillRectangle(startX + block*1, startY + block*2, block, block);
            dc.fillRectangle(startX + block*3, startY + block*2, block, block);
            dc.fillRectangle(startX + block*2, startY + block*3, block, block);
        }
    }

    // Draw a sun event countdown using a fixed array of 18 markers.
    // Visible bars = ceil(secsLeft / (initialTotalSecs / 18)). We store the initial total seconds
    // when a new sunEvent is observed so the 20% rule is computed against that initial duration.
    function drawSunCountdown(dc as Dc, x as Number, y as Number, size as Number, sunEvent as Time.Moment or Null) as Void {
        var totalBars = 16;
    var barW = (size * 0.12).toNumber(); if (barW < 3) { barW = 3; }
        var spacing = 2;

        // compute seconds left
        var secsLeft = -1;
        if (sunEvent != null) {
            try {
                var nowSec = Time.now().value();
                var sunSec = sunEvent.value();
                secsLeft = (sunSec - nowSec).toNumber();
            } catch (ex) {
                secsLeft = -1;
            }
        }

        var startX = (x - ((totalBars - 1) * (barW + spacing) / 2)).toNumber();
        var by = (y - barW / 2).toNumber();

        // If no valid event or seconds left is non-positive, draw placeholder outline bars and label
        if (secsLeft <= 0 || sunEvent == null) {
            for (var p = 0; p < totalBars; p++) {
                var px = (startX + p * (barW + spacing)).toNumber();
                dc.setColor(_darkGreen, Graphics.COLOR_TRANSPARENT);
                dc.drawRectangle(px, by, barW, barW);
            }
            dc.setColor(_matrixGreen, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x, (by + barW + 8).toNumber(), Graphics.FONT_SYSTEM_XTINY, "", Graphics.TEXT_JUSTIFY_CENTER);
            // reset stored event so we reinitialize on the next valid event
            _sunEventId = 0; _sunEventTotalSecs = 0;
            try {
                Storage.deleteValue("SunEventId");
                Storage.deleteValue("SunEventInitialSecs");
            } catch (ex) {}
            return;
        }

        // If this is a new sun event (different moment), capture the initial total seconds
        var thisEventId = sunEvent.value().toNumber();
        if (thisEventId != _sunEventId || _sunEventTotalSecs <= 0) {
            _sunEventId = thisEventId;
            _sunEventTotalSecs = secsLeft;
            if (_sunEventTotalSecs <= 0) { _sunEventTotalSecs = 1; }
            try {
                Storage.setValue("SunEventId", _sunEventId);
                Storage.setValue("SunEventInitialSecs", _sunEventTotalSecs);
            } catch (ex) {}
        }

    // Compute how many bars should be visible using an exact ratio to avoid
    // rounding artifacts: visible = ceil((secsLeft / initialTotal) * totalBars)
    var visible = Math.ceil((secsLeft * totalBars) / (_sunEventTotalSecs * 1.0)).toNumber();
    //System.println("Sun event secsLeft=" + secsLeft + " totalSecs=" + _sunEventTotalSecs + " visible=" + visible);
    if (visible < 0) { visible = 0; }
    if (visible > totalBars) { visible = totalBars; }

        // Red threshold: when remaining time is ≤ 20% of the initial total
        var redThreshold = Math.floor(_sunEventTotalSecs * 0.20).toNumber();

        for (var i = 0; i < totalBars; i++) {
            var bx = (startX + i * (barW + spacing)).toNumber();
            // Bars are drawn left-to-right; leftmost are the furthest from the event.
            // We show 'visible' bars starting from the left. Bars beyond 'visible' are blacked-out.
            if (i < visible) {
                // Determine color: red if secsLeft <= redThreshold, else theme
                if (secsLeft <= redThreshold) {
                    dc.setColor(0xFF4040, Graphics.COLOR_TRANSPARENT);
                } else {
                    dc.setColor(_matrixGreen, Graphics.COLOR_TRANSPARENT);
                }
                dc.fillRectangle(bx, by, barW, barW);
            } else {
                dc.setColor(_darkGreen, Graphics.COLOR_TRANSPARENT);
                dc.drawRectangle(bx, by, barW, barW);
            }
        }

    // Event time label intentionally disabled in favor of minimal UI
    }


    

    // Draw a horizontal barometer with a center 'normal' marker and numeric label
    function drawBarometer(dc as Dc, x as Number, y as Number, width as Number, pressure as Number) as Void {
        var hw = (width/2).toNumber();
        var h = (width * 0.06).toNumber();
        if (h < 6) {
            h = 6;
        }
        var left = (x - hw).toNumber();
    // right = (x + hw).toNumber(); // unused - labels disabled

        // outline base
        dc.setColor(_darkGreen, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(left, y - h/2, width, h);

        // normalize pressure to typical range 960..1040 hPa
        var pct = 0.5;
        if (pressure != null) {
            var p = pressure.toNumber();
            var minP = 960; var maxP = 1040;
            if (p < minP) {
                p = minP;
            }
            if (p > maxP) {
                p = maxP;
            }
            pct = ((p - minP) / (maxP - minP)).toNumber();
        }

        var fillW = (width * pct).toNumber();
        dc.setColor(_brightGreen, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(left, y - h/2 + 1, fillW, h - 1);

        // center normal marker
        var normalX = x;
        dc.setColor(_matrixGreen, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(normalX, y - h, normalX, y + h + 2);

    // numeric label right side intentionally disabled; consolidated strip will show pressure
    }

    // Draw humidity as a single horizontal row of bars (proportional fill)
    function drawHumidity(dc as Dc, x as Number, y as Number, size as Number, humidity as Number) as Void {
        // Use same bar sizing rule as other gauges
        var barW = (size * 0.12).toNumber();
        if (barW < 3) { barW = 3; }
        var spacing = 2;

        var totalBars = 16; // match sun countdown

        // Compute how many bars should be filled from humidity (0..100)
        var filled = 0;
        if (humidity != null) {
            var hv = humidity.toNumber();
            filled = Math.round((hv / 100.0) * totalBars).toNumber();
        }

        // Choose theme color based on humidity ranges (low/medium/high)
        var fillColor = _matrixGreen;
        if (humidity != null) {
            var hv2 = humidity.toNumber();
            if (hv2 <= 33) {
                fillColor = _darkGreen; // low
            } else if (hv2 <= 66) {
                fillColor = _matrixGreen; // medium
            } else {
                fillColor = _brightGreen; // high
            }
        }

        var startX = (x - ((totalBars - 1) * (barW + spacing) / 2)).toNumber();
        var by = (y - barW / 2).toNumber();

        // Draw bars left-to-right
        for (var i = 0; i < totalBars; i++) {
            var bx = (startX + i * (barW + spacing)).toNumber();
            if (i < filled) {
                dc.setColor(fillColor, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(bx, by, barW, barW);
            } else {
                dc.setColor(_darkGreen, Graphics.COLOR_TRANSPARENT);
                dc.drawRectangle(bx, by, barW, barW);
            }
        }
    }

    // perimeter seconds feature removed

    // The user has just looked at their watch. Timers and animations may be started here.
    // Draw a tiny consolidated label line: "T° | H% | Wspd | Prs"
    function drawConsolidatedLabels(dc as Dc, x as Number, y as Number, size as Number, temp as Number, humidity as Number, wind as Number, windDir as Number, pressure as Number) as Void {
        // Compose short tokens
        var tLabel = (temp == null) ? "--" : temp.format("%0.0f");
        var hLabel = (humidity == null) ? "--%" : humidity.format("%0.0f") + "%";
        var wLabel = (wind == null) ? "--" : wind.format("%0.0f");
        // append wind unit and direction (short compass) if available
        //var windUnit = getWindUnitString();
        if (wLabel != "--") { wLabel = wLabel; }
        if (windDir != null) {
            try {
                var d = windDir.toNumber();
                var dirs = ["N","NE","E","SE","S","SW","W","NW"];
                var idx = Math.floor((d + 22.5) / 45).toNumber() % 8;
                var dirLabel = dirs[idx];
                wLabel = wLabel + " " + dirLabel;
            } catch (ex) {
                // ignore on parse error
            }
        }
        var pLabel = (pressure == null) ? "--" : pressure.format("%0.0f");

        // Units: append small unit markers where sensible (° for temp)
        var unitVal = Properties.getValue("TemperatureUnit");
        var tempUnit = "°C";
        try {
            if (unitVal != null && unitVal.toNumber() == 2) { tempUnit = "°F"; }
        } catch (ex) {}
        tLabel = tLabel + tempUnit;

        // Compose pipe-separated string; keep it very small
        var sep = " | ";
        var line = tLabel + sep + hLabel + sep + wLabel + sep + pLabel;

        // Choose a very small font and proportional x offset
    var font = Graphics.FONT_SYSTEM_XTINY;
        dc.setColor(_matrixGreen, Graphics.COLOR_TRANSPARENT);
        // Center the whole line at x
        dc.drawText(x, y, font, line, Graphics.TEXT_JUSTIFY_CENTER);
    }

    function onExitSleep() as Void {
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
    }

}

