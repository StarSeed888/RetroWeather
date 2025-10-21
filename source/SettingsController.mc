import Toybox.Lang;
import Toybox.System;
using Toybox.Application.Properties;

// Settings controller to minimize battery usage by caching settings
// and only polling them periodically instead of every update cycle
class SettingsController {
    
    // Cache settings values to avoid frequent Properties calls
    private var _colorTheme;
    private var _temperatureUnit;
    private var _windSpeedUnit;
    private var _visibilityUnit;
    private var _dynamicWeatherColor;
    private var _wireframeText;
    
    // Poll counter to refresh settings periodically for responsive updates
    private var _pollCounter;
    private var _pollInterval;
    
    function initialize() {
        _pollCounter = 0;
        _pollInterval = 5; // Refresh settings every 5 update cycles for quick response
        
        // Load initial settings
        refreshSettings();
    }
    
    // Call this from main update loop - will only refresh periodically
    function updateSettings() as Void {
        _pollCounter++;
        if (_pollCounter >= _pollInterval) {
            _pollCounter = 0;
            refreshSettings();
        }
    }
    
    // Force refresh all settings from Properties (battery intensive)
    function refreshSettings() as Void {
        _colorTheme = getProperty("ColorTheme", 0);
        _temperatureUnit = getProperty("TemperatureUnit", 1);
        _windSpeedUnit = getProperty("WindSpeedUnit", 2);
        _visibilityUnit = getProperty("VisibilityUnit", 1);
        _dynamicWeatherColor = getProperty("DynamicWeatherColor", false);
        _wireframeText = getProperty("WireframeText", 1);
    }
    
    // Safe property getter with default fallback
    private function getProperty(key as String, defaultVal) as Object {
        try {
            var value = Properties.getValue(key);
            if (value == null) {
                return defaultVal;
            }
            // Try to coerce to number if it looks numeric
            if (value instanceof String) {
                try {
                    return value.toNumber();
                } catch (ex) {
                    return value;
                }
            }
            return value;
        } catch (ex) {
            return defaultVal;
        }
    }
    
    // Cached getters - these are battery friendly
    function getColorTheme() as Number {
        return _colorTheme;
    }
    
    function getTemperatureUnit() as Number {
        return _temperatureUnit;
    }
    
    function getWindSpeedUnit() as Number {
        return _windSpeedUnit;
    }
    
    function getVisibilityUnit() as Number {
        return _visibilityUnit;
    }
    
    function getDynamicWeatherColor() as Boolean {
        return _dynamicWeatherColor;
    }
    
    function getWireframeText() as Number {
        return _wireframeText;
    }
    
    // Get temperature unit string for display - ASCII compatible
    function getTemperatureUnitString() as String {
        switch (_temperatureUnit) {
            case 2: return "F";
            default: return "C";
        }
    }
    
    // Get wind speed unit string for display
    function getWindSpeedUnitString() as String {
        switch (_windSpeedUnit) {
            case 0: return "m/s";
            case 1: return "km/h";
            case 2: return "mph";
            default: return "mph";
        }
    }
    
    // Get visibility unit string for display
    function getVisibilityUnitString() as String {
        switch (_visibilityUnit) {
            case 1: return "km";
            case 2: return "mi";
            default: return "km";
        }
    }
    
    // Get freezing point based on temperature unit
    function getFreezingPoint() as Number {
        return (_temperatureUnit == 2) ? 32 : 0;
    }
    
    // Get high temperature threshold based on unit
    function getHighTempThreshold() as Number {
        return (_temperatureUnit == 2) ? 82 : 27;
    }
    
    // Get wind speed threshold based on unit
    function getWindSpeedThreshold() as Number {
        switch (_windSpeedUnit) {
            case 0: return 13; // m/s
            case 1: return 48; // km/h
            case 2: return 30; // mph
            default: return 30;
        }
    }
}
