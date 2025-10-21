import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Math;
using Toybox.Application.Storage as Storage;
using Toybox.Application.Properties;

class RetroWeatherView extends WatchUi.WatchFace {

    // Vintage instrument panel theme colors
    var _matrixGreen = 0x00FF41;
    var _darkGreen = 0x008F11;
    var _brightGreen = 0x80FF80;
    var _black = 0x000000;
    var _statusGreen = 0x00FF00;
    var _statusYellow = 0xFFFF00;
    var _statusRed = 0xFF0000;
    
    // Controllers
    var _weatherCtrl = null;
    var _settingsCtrl = null;

    // Tracks the currently observed sun event so we can compute a stable initial duration
    var _sunEventId = 0;
    var _sunEventTotalSecs = 0;

    function initialize() {
        WatchFace.initialize();
        
        // Initialize controllers
        try {
            _weatherCtrl = new WeatherControl();
            _settingsCtrl = new SettingsController();
        } catch (ex) {
            _weatherCtrl = null;
            _settingsCtrl = null;
        }
        
        // Load initial theme colors
        loadColorTheme();
        // Restore any persisted sun-event state
        loadSunEventState();
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

    // Load color theme based on settings controller
    function loadColorTheme() as Void {
        var colorTheme = 0;
        if (_settingsCtrl != null) {
            colorTheme = _settingsCtrl.getColorTheme();
        }

        switch (colorTheme) {
            case 0: // Matrix Green
                _matrixGreen = 0x00FF41;
                _darkGreen = 0x008F11;
                _brightGreen = 0x80FF80;
                _statusGreen = 0x00FF00;
                _statusYellow = 0xFFFF00;
                _statusRed = 0xFF0000;
                break;
            case 1: // Retro Cyan
                _matrixGreen = 0x00FFFF;
                _darkGreen = 0x008F8F;
                _brightGreen = 0x80FFFF;
                _statusGreen = 0x00FFFF;
                _statusYellow = 0xFFFF80;
                _statusRed = 0xFF8080;
                break;
            case 2: // Retro Amber
                _matrixGreen = 0xFFB000;
                _darkGreen = 0x8F6000;
                _brightGreen = 0xFFE080;
                _statusGreen = 0xFFB000;
                _statusYellow = 0xFFFF00;
                _statusRed = 0xFF4000;
                break;
            case 3: // Retro Purple
                _matrixGreen = 0xBF40FF;
                _darkGreen = 0x6F258F;
                _brightGreen = 0xE080FF;
                _statusGreen = 0xBF40FF;
                _statusYellow = 0xFF80FF;
                _statusRed = 0xFF4080;
                break;
            case 4: // Retro Red
                _matrixGreen = 0xFF4040;
                _darkGreen = 0x8F2525;
                _brightGreen = 0xFF8080;
                _statusGreen = 0xFF8080;
                _statusYellow = 0xFFFF40;
                _statusRed = 0xFF0000;
                break;
            case 5: // Retro Blue
                _matrixGreen = 0x4080FF;
                _darkGreen = 0x25508F;
                _brightGreen = 0x80B0FF;
                _statusGreen = 0x4080FF;
                _statusYellow = 0x80FFFF;
                _statusRed = 0xFF4040;
                break;
            case 6: // Retro Orange
                _matrixGreen = 0xFF8000;
                _darkGreen = 0x8F4000;
                _brightGreen = 0xFFB050;
                _statusGreen = 0xFF8000;
                _statusYellow = 0xFFFF00;
                _statusRed = 0xFF0000;
                break;
            case 7: // Retro Pink
                _matrixGreen = 0xFF40A0;
                _darkGreen = 0x8F2560;
                _brightGreen = 0xFF80C0;
                _statusGreen = 0xFF40A0;
                _statusYellow = 0xFFFF80;
                _statusRed = 0xFF0040;
                break;
            case 8: // Retro Yellow
                _matrixGreen = 0xFFFF00;
                _darkGreen = 0x8F8F00;
                _brightGreen = 0xFFFF80;
                _statusGreen = 0xFFFF00;
                _statusYellow = 0xFFFF80;
                _statusRed = 0xFF8000;
                break;
            case 9: // Retro White
                _matrixGreen = 0xE0E0E0;
                _darkGreen = 0x808080;
                _brightGreen = 0xFFFFFF;
                _statusGreen = 0x80FF80;
                _statusYellow = 0xFFFF80;
                _statusRed = 0xFF8080;
                break;
            default:
                _matrixGreen = 0x00FF41;
                _darkGreen = 0x008F11;
                _brightGreen = 0x80FF80;
                _statusGreen = 0x00FF00;
                _statusYellow = 0xFFFF00;
                _statusRed = 0xFF0000;
        }
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





    // Update the view with vintage instrument panel layout
    function onUpdate(dc as Dc) as Void {
        View.onUpdate(dc);
        
        // Update settings controller periodically for battery optimization
        if (_settingsCtrl != null) {
            _settingsCtrl.updateSettings();
        }
        
        // Update weather data periodically for battery optimization
        if (_weatherCtrl != null) {
            _weatherCtrl.updateConditions();
        }
        
        // Clear screen with black background
        dc.setColor(_black, Graphics.COLOR_TRANSPARENT);
        dc.clear();
        
        // Get screen dimensions for proportional layout
        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var centerY = height / 2;
        
        // Draw vintage instrument panel interface
        drawVintageInterface(dc, width, height, centerX, centerY);
    }

    // Main vintage instrument panel interface
    function drawVintageInterface(dc as Dc, width as Number, height as Number, centerX as Number, centerY as Number) as Void {
        // Get current time with null safety for device settings
        var clockTime = System.getClockTime();
        var hour = clockTime.hour;
        var minute = clockTime.min.format("%02d");
        var second = clockTime.sec.format("%02d");
        var deviceSettings = System.getDeviceSettings();
        var is24Hour = (deviceSettings != null) ? deviceSettings.is24Hour : true;
        
        // Format time display
        var displayHour = hour;
        var ampmText = "";
        if (!is24Hour) {
            ampmText = (displayHour >= 12) ? "PM" : "AM";
            if (displayHour == 0) { displayHour = 12; }
            else if (displayHour > 12) { displayHour = displayHour - 12; }
        }
        var timeString = displayHour.format("%02d") + ":" + minute + ":" + second;
        
                // Proportional layout calculations - compressed to fit new status lines
        var headerHeight = (height * 0.12).toNumber();  // Reduced from 0.15
        var timeY = (height * 0.17).toNumber();          // Reduced from 0.20
        var instrumentY = (height * 0.42).toNumber();    // Moved down from 0.38 to clear time
        var statusStartY = (height * 0.60).toNumber();   // Moved up from 0.66 for better positioning
        var panelWidth = (width * 0.28).toNumber();      // Slightly narrower panels
        var panelHeight = (height * 0.22).toNumber();    // Increased back to 0.22 for proper spacing
        
        // Draw header with title and weather symbol - moved down to prevent cutoff
        drawHeader(dc, centerX, (headerHeight * 0.75).toNumber(), width);
        
        // Draw main time display in brackets - smaller and positioned higher
        drawTimeDisplay(dc, centerX, timeY, timeString, ampmText);
        
        // Draw instrument panels - better spacing to prevent overlap
        var leftPanelX = (width * 0.22).toNumber();   // Moved closer to edge
        var centerPanelX = centerX;
        var rightPanelX = (width * 0.78).toNumber();  // Moved closer to edge
        
        drawInstrumentPanel(dc, leftPanelX, instrumentY, panelWidth, panelHeight, "TEMP", getTemperatureData());
        drawInstrumentPanel(dc, centerPanelX, instrumentY, panelWidth, panelHeight, "WIND", getWindData());
        drawInstrumentPanel(dc, rightPanelX, instrumentY, panelWidth, panelHeight, "HUM", getHumidityData());
        
        // Draw status lines - positioned to fit on screen
        drawStatusLines(dc, centerX, statusStartY, width);
    }

    // Helper functions for vintage interface
    function getTemperatureData() as Dictionary {
        var temp = null;
        var status = "N/A";
        var value = "--";
        var unit = "C";
        
        if (_weatherCtrl != null && _settingsCtrl != null) {
            temp = _weatherCtrl.getTemperature();
            unit = _settingsCtrl.getTemperatureUnitString();
            
            if (temp != null) {
                value = temp.format("%.0f");
                var threshold = _settingsCtrl.getHighTempThreshold();
                var freezing = _settingsCtrl.getFreezingPoint();
                
                if (temp >= threshold) {
                    status = "HIGH";
                } else if (temp <= freezing) {
                    status = "COLD";
                } else {
                    status = "OK";
                }
            }
        }
        
        return {
            :value => value,
            :unit => unit,
            :status => status,
            :rawValue => temp
        };
    }
    

function drawTextWireframe(dc as Dc, text as String, x as Number, y as Number, font as Graphics.FontType, justification as Number, color as Number) as Void {
    // Draw subtle shadow for depth
    var darkGray = 0x2D2D2D;
    dc.setColor(darkGray, Graphics.COLOR_TRANSPARENT);
    dc.drawText(x + 1, y + 1, font, text, justification);

    // Draw colored outline by drawing the text at offsets
    dc.setColor(color, Graphics.COLOR_TRANSPARENT);
    var stroke = 1; // Keep it simple with 1 pixel stroke
    dc.drawText(x - stroke, y, font, text, justification);
    dc.drawText(x + stroke, y, font, text, justification);
    dc.drawText(x, y - stroke, font, text, justification);
    dc.drawText(x, y + stroke, font, text, justification);
    dc.drawText(x - stroke, y - stroke, font, text, justification);
    dc.drawText(x + stroke, y - stroke, font, text, justification);
    dc.drawText(x - stroke, y + stroke, font, text, justification);
    dc.drawText(x + stroke, y + stroke, font, text, justification);

    // Fill interior with black to achieve wireframe look
    dc.setColor(0x000000, Graphics.COLOR_TRANSPARENT);
    dc.drawText(x, y, font, text, justification);
}

    // Helper function to draw text based on wireframe setting
    function drawText(dc as Dc, text as String, x as Number, y as Number, font as Graphics.FontType, justification as Number, color as Number) as Void {
        if (_settingsCtrl != null && _settingsCtrl.getWireframeText() == 1) {
            drawTextWireframe(dc, text, x, y, font, justification, color);
        } else {
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x, y, font, text, justification);
        }
    }


    function getWindData() as Dictionary {
        var wind = null;
        var windDir = null;
        var status = "N/A";
        var value = "--";
        var unit = "mph";
        var direction = "";
        
        if (_weatherCtrl != null && _settingsCtrl != null) {
            wind = _weatherCtrl.getWindSpeed();
            windDir = _weatherCtrl.getWindBearing();
            unit = _settingsCtrl.getWindSpeedUnitString();
            
            if (wind != null) {
                value = wind.format("%.0f");
                var threshold = _settingsCtrl.getWindSpeedThreshold();
                
                if (wind >= threshold) {
                    status = "HIGH";
                } else if (wind <= 2) {
                    status = "CALM";
                } else {
                    status = "OK";
                }
            }
            
            if (windDir != null) {
                direction = _weatherCtrl.getWindBearingString();
            }
        }
        
        return {
            :value => value,
            :unit => unit,
            :status => status,
            :direction => direction,
            :rawValue => wind
        };
    }
    
    function getHumidityData() as Dictionary {
        var humidity = null;
        var status = "N/A";
        var value = "--";
        
        if (_weatherCtrl != null) {
            humidity = _weatherCtrl.getHumidity();
            
            if (humidity != null) {
                value = humidity.format("%.0f");
                
                if (humidity <= 30) {
                    status = "LOW";
                } else if (humidity >= 70) {
                    status = "HIGH";
                } else {
                    status = "OK";
                }
            }
        }
        
        return {
            :value => value,
            :unit => "%",
            :status => status,
            :rawValue => humidity
        };
    }

    // Get battery level as ASCII indicator
    function getBatteryIndicator() as String {
        var battery = System.getSystemStats().battery;
        var batteryPercent = battery.toNumber();
        var barCount = 4;
        var filledBars = Math.floor(batteryPercent / 25.0).toNumber();
        if (filledBars > barCount) { filledBars = barCount; }
        
        var batteryBar = "";
        for (var i = 0; i < barCount; i++) {
            if (i < filledBars) {
                batteryBar += "#";
            } else {
                batteryBar += "-";
            }
        }
        
        return "BAT:[" + batteryBar + "]";
    }

    // Get data age as ASCII indicator
    function getDataAgeIndicator() as String {
        if (_weatherCtrl == null) {
            return "AGE:[OLD]";
        }
        
        var updateTime = _weatherCtrl.getUpdateTime();
        if (updateTime == null) {
            return "AGE:[---]";
        }
        
        var now = Time.now();
        var ageSeconds = now.value() - updateTime.value();
        var ageMinutes = ageSeconds / 60;
        
        if (ageMinutes < 5) {
            return "AGE:[NEW]";
        } else if (ageMinutes < 15) {
            return "AGE:[OK ]";
        } else if (ageMinutes < 60) {
            return "AGE:[OLD]";
        } else {
            return "AGE:[!!!]";
        }
    }

    // Get sunrise/sunset times as ASCII indicator
    function getSunriseSunsetTimes() as String {
        if (_weatherCtrl == null) {
            return "SUN:[--:--]";
        }
        
        var sunTimeString = _weatherCtrl.getSunEventTimeString();
        if (sunTimeString == null || sunTimeString.equals("-")) {
            return "SUN:[--:--]";
        }
        
        // Determine if it's sunrise or sunset based on current time
        var now = Time.now();
        var positionInfo = Position.getInfo();
        if (positionInfo != null && positionInfo.position != null) {
            var sunriseMoment = Weather.getSunrise(positionInfo.position, now);
            var sunsetMoment = Weather.getSunset(positionInfo.position, now);
            
            if (sunriseMoment != null && sunsetMoment != null) {
                if (now.compare(sunriseMoment) < 0) {
                    // Before sunrise - show sunrise time
                    return "UP:[" + sunTimeString + "]";
                } else if (now.compare(sunsetMoment) < 0) {
                    // After sunrise, before sunset - show sunset time
                    return "DN:[" + sunTimeString + "]";
                } else {
                    // After sunset - show next sunrise time
                    return "UP:[" + sunTimeString + "]";
                }
            }
        }
        
        return "SUN:[" + sunTimeString + "]";
    }

    // Get ASCII weather symbol based on condition
    function getWeatherSymbol() as String {
        var defaultSymbol = "***";
        
        if (_weatherCtrl == null) {
            return defaultSymbol;
        }
        
        var condition = _weatherCtrl.getCondition();
        if (condition == null) {
            return defaultSymbol;
        }
        
        // Convert weather condition to ASCII art symbols
        switch (condition) {
            case 0:  // Clear/Sunny
                return "[O]"; // Sun symbol
            case 1:  // Partly Cloudy  
                return "[~]"; // Mixed symbol
            case 2:  // Mostly Cloudy
                return "[=]"; // Cloud symbol
            case 3:  // Rain
                return "[|]"; // Rain symbol
            case 4:  // Snow
                return "[*]"; // Snow symbol
            case 5:  // Windy
                return "[>]"; // Wind symbol
            case 6:  // Thunderstorms
                return "[!]"; // Storm symbol
            case 7:  // Wintry Mix
                return "[%]"; // Mixed precipitation
            case 8:  // Fog
                return "[:]"; // Fog symbol
            case 9:  // Hazy
                return "[.]"; // Haze symbol
            case 10: // Hail
                return "[#]"; // Hail symbol
            case 11: // Scattered Showers
                return "[']"; // Light rain
            case 12: // Scattered Thunderstorms
                return "[^]"; // Scattered storms
            case 13: // Unknown Precipitation
                return "[?]"; // Unknown
            case 14: // Light Rain
                return "[,]"; // Light rain dots
            case 15: // Heavy Rain
                return "[|]"; // Heavy rain
            case 16: // Light Snow
                return "[+]"; // Light snow
            case 17: // Heavy Snow
                return "[*]"; // Heavy snow
            case 18: // Light Rain Snow
                return "[/]"; // Mixed light
            case 19: // Heavy Rain Snow
                return "[\\]"; // Mixed heavy
            case 20: // Cloudy
                return "[=]"; // Cloudy
            default:
                return defaultSymbol;
        }
    }

    // Draw header with title and weather symbol - more compact
    function drawHeader(dc as Dc, centerX as Number, y as Number, width as Number) as Void {
        // Draw top border only
        dc.setColor(_matrixGreen, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(0, 0, width, 0);
        // Removed bottom header line for cleaner look
        
        // Draw title with ASCII weather symbol
        var weatherSymbol = getWeatherSymbol();
        var titleText = weatherSymbol + "METEO" + weatherSymbol;
        drawText(dc, titleText, centerX, y, Graphics.FONT_SYSTEM_XTINY, Graphics.TEXT_JUSTIFY_CENTER, _brightGreen);
    }
    
    // Draw time display in retro format - smaller size
    function drawTimeDisplay(dc as Dc, centerX as Number, y as Number, timeString as String, ampmText as String) as Void {
        var displayText = "[" + timeString + "]";
        
        // Draw main time with smaller font
        drawText(dc, displayText, centerX, y, Graphics.FONT_LARGE, Graphics.TEXT_JUSTIFY_CENTER, _matrixGreen);
        
        // Draw AM/PM if present - positioned proportionally to avoid seconds overlap
        if (ampmText != "") {
            var screenWidth = dc.getWidth();
            var ampmX = centerX + (screenWidth * 0.29).toNumber(); // Proportional offset based on screen width
            drawText(dc, ampmText, ampmX, (y * 1.20).toNumber(), Graphics.FONT_SYSTEM_TINY, Graphics.TEXT_JUSTIFY_LEFT, _brightGreen);
        }
    }
    
    // Draw individual instrument panel - more spacing and taller panels
    function drawInstrumentPanel(dc as Dc, centerX as Number, centerY as Number, width as Number, height as Number, label as String, data as Dictionary) as Void {
        var halfWidth = width / 2;
        var halfHeight = height / 2;
        var left = centerX - halfWidth;
        var top = centerY - halfHeight;
        
        // Ensure panel doesn't go off screen
        if (left < 5) { left = 5; }
        if (left + width > dc.getWidth() - 5) { left = dc.getWidth() - width - 5; }
        
        // Draw panel border
        dc.setColor(_matrixGreen, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(left, top, width, height);
        
        // Draw label at top - proportional positioning
        drawText(dc, label, left + (width/2).toNumber(), top + (height * 0.08).toNumber(), Graphics.FONT_SYSTEM_XTINY, Graphics.TEXT_JUSTIFY_CENTER, _brightGreen);
        
        // Draw status indicator dot - proportional positioning with null safety
        var statusColor = _statusGreen;
        if (data != null && data.hasKey(:status) && data[:status] != null) {
            if (data[:status].equals("HIGH") || data[:status].equals("WARN")) {
                statusColor = _statusYellow;
            } else if (data[:status].equals("CRIT") || data[:status].equals("LOW") || data[:status].equals("COLD")) {
                statusColor = _statusRed;
            }
        }
        
        dc.setColor(statusColor, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(left + (width * 0.15).toNumber(), top + (height * 0.25).toNumber(), 2);
        
        // Draw value and unit - proportional positioning in middle section with null safety
        var valueText = "--";
        if (data != null) {
            var value = (data.hasKey(:value) && data[:value] != null) ? data[:value] : "--";
            var unit = (data.hasKey(:unit) && data[:unit] != null) ? data[:unit] : "";
            valueText = value + unit;
        }
        drawText(dc, valueText, left + (width/2).toNumber(), top + (height * 0.45).toNumber(), Graphics.FONT_SYSTEM_XTINY, Graphics.TEXT_JUSTIFY_CENTER, _matrixGreen);
        
        // Draw horizontal progress bar - positioned lower for better separation from value text with null safety
        var barY = top + (height * 0.82).toNumber();
        var barX = left + (width * 0.1).toNumber();
        var barWidth = (width * 0.8).toNumber();
        var rawValue = (data != null && data.hasKey(:rawValue)) ? data[:rawValue] : null;
        drawProgressBar(dc, barX, barY, barWidth, 4, rawValue, label);
    }
    
    // Draw progress bar for instrument panel - smaller bars
    function drawProgressBar(dc as Dc, x as Number, y as Number, width as Number, height as Number, value, type as String) as Void {
        var barCount = 5; // Reduced from 6 to prevent overlap
        var barWidth = (width / barCount).toNumber() - 2;
        var filled = 0;
        
        if (value != null) {
            var percentage = 0.0;
            
            // Calculate percentage based on type
            if (type.equals("TEMP")) {
                // Temperature: map -20 to 40°C (or equivalent F) to 0-100%
                var minVal = (_settingsCtrl != null && _settingsCtrl.getTemperatureUnit() == 2) ? -4 : -20;
                var maxVal = (_settingsCtrl != null && _settingsCtrl.getTemperatureUnit() == 2) ? 104 : 40;
                percentage = (value - minVal) / (maxVal - minVal);
            } else if (type.equals("WIND")) {
                // Wind: 0 to 50 mph/kmh/ms to 0-100%
                percentage = value / 50.0;
            } else if (type.equals("HUM")) {
                // Humidity: 0 to 100% directly
                percentage = value / 100.0;
            }
            
            filled = Math.floor(percentage * barCount).toNumber();
            if (filled < 0) { filled = 0; }
            if (filled > barCount) { filled = barCount; }
        }
        
        // Draw bars - smaller and more compact with increased spacing
        for (var i = 0; i < barCount; i++) {
            var barX = x + i * (barWidth + 2);
            
            if (i < filled) {
                dc.setColor(_matrixGreen, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(barX, y, barWidth, height);
            } else {
                dc.setColor(_darkGreen, Graphics.COLOR_TRANSPARENT);
                dc.drawRectangle(barX, y, barWidth, height);
            }
        }
    }
    
    // Draw status lines at bottom - using proportional positioning
    function drawStatusLines(dc as Dc, centerX as Number, startY as Number, width as Number) as Void {
        var height = dc.getHeight();
        
        // Get additional weather data
        var pressure = null;
        var feelsLike = null;
        var visibility = null;
        
        if (_weatherCtrl != null) {
            pressure = _weatherCtrl.getPressure();
            feelsLike = _weatherCtrl.getFeelsLikeTemperature();
            visibility = _weatherCtrl.getVisibility();
        }
        
        // Format status lines - shorter format to fit better
        var visibilityThreshold = 5; // Default for km
        var visibilityUnit = (_settingsCtrl != null) ? _settingsCtrl.getVisibilityUnitString() : "km";
        if (visibilityUnit.equals("mi")) {
            visibilityThreshold = 3; // 3 miles threshold instead of 5 km
        }
        
        var lines = [
            formatStatusLine("PRS", pressure, "hPa", 950, 1050),
            formatStatusLine("FEL", feelsLike, (_settingsCtrl != null) ? _settingsCtrl.getTemperatureUnitString() : "C", null, null),
            formatStatusLine("VIS", visibility, visibilityUnit, visibilityThreshold, null),
            getBatteryIndicator(),
            getDataAgeIndicator(),
            getSunriseSunsetTimes()
        ];
        
        // Proportional Y positions for each status line (60% to 90% of screen)
        var statusPositions = [
            (height * 0.56).toNumber(),  // Line 1: PRS
            (height * 0.63).toNumber(),  // Line 2: FEL  
            (height * 0.69).toNumber(),  // Line 3: VIS
            (height * 0.75).toNumber(),  // Line 4: BAT
            (height * 0.82).toNumber(),  // Line 5: AGE
            (height * 0.89).toNumber()   // Line 6: SUN
        ];
        
        // Draw each status line at its proportional position
        for (var i = 0; i < lines.size() && i < statusPositions.size(); i++) {
            drawText(dc, lines[i], centerX, statusPositions[i], Graphics.FONT_SYSTEM_XTINY, Graphics.TEXT_JUSTIFY_CENTER, _matrixGreen);
        }
    }
    
    // Format a status line with label, value, unit, and status
    function formatStatusLine(label as String, value, unit as String, lowThreshold, highThreshold) as String {
        var valueStr = "--";
        var status = "[N/A]";
        
        if (value != null) {
            valueStr = value.format("%.0f");
            
            if (lowThreshold != null && value < lowThreshold) {
                status = "[LOW]";
            } else if (highThreshold != null && value > highThreshold) {
                status = "[HIGH]";
            } else {
                status = "[OK]";
            }
        }
        
        return label + ": " + valueStr + unit + " " + status;
    }

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

        // Units: append small unit markers (simple ASCII for temp)
        var unitVal = Properties.getValue("TemperatureUnit");
        var tempUnit = "C";
        try {
            if (unitVal != null && unitVal.toNumber() == 2) { tempUnit = "F"; }
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

