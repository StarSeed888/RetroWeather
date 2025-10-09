import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Position;
import Toybox.Weather;
using Toybox.Application.Properties;
import Toybox.Math;
import Toybox.Time;
import Toybox.Position;


class WeatherControl {

    var conditions = Weather.getCurrentConditions();
    var lastUpdateTime = 0; // Track when we last updated conditions
  




 function WeatherControl() {
        // Constructor code here
        //conditions = Weather.getCurrentConditions();
        refreshConditions();

    }

     function refreshConditions() as Void {
        var currentTime = Time.now().value();
        
        // Only refresh if it's been more than 5 minutes (300 seconds) since last update
        if (currentTime - lastUpdateTime > 300) {
            conditions = Weather.getCurrentConditions();
            lastUpdateTime = currentTime;
        }
    }

    // Safe property getter: returns defaultVal if key missing or getValue throws
    function _getProperty(key as String, defaultVal) as Object {
        try {
            var v = Properties.getValue(key);
            if (v == null) {
                return defaultVal;
            }
            // try to coerce numeric-like strings to numbers
            try {
                v = v.toNumber();
            } catch (ex) {
                // leave as-is
            }
            return v;
        } catch (ex) {
            return defaultVal;
        }
    }



    function getTemperature() as Number or Null {
      if (conditions != null) {
    var unit = _getProperty("TemperatureUnit", 1);
    if (unit == 2) { // 2 = Fahrenheit
            return conditions.temperature * 9 / 5 + 32;
        } else { // 1 = Celsius (default)
            return conditions.temperature;
        }
    }
        return null;

    }

function getSunEventTime() as Time.Moment or Null {
    var positionInfo = Position.getInfo();
    //System.println("Position Info: " + positionInfo.altitude);
    if (positionInfo != null && positionInfo.accuracy != null && positionInfo.position != null) {
        var now = Time.now();
        var sunriseMoment = Weather.getSunrise(positionInfo.position, now);
        var sunsetMoment  = Weather.getSunset(positionInfo.position, now);

        if (sunriseMoment != null && sunsetMoment != null) {
            if (now.compare(sunriseMoment) < 0) {
                // Before sunrise
                return sunriseMoment;
            } else if (now.compare(sunsetMoment) < 0 && now.compare(sunriseMoment) >= 0) {
                // After sunrise, before sunset
                return sunsetMoment;
            } else {
                // After sunset, get tomorrow's sunrise
                var oneDay = new Time.Duration(Time.Gregorian.SECONDS_PER_DAY);
                var tomorrow = now.add(oneDay);
                var nextSunrise = Weather.getSunrise(positionInfo.position, tomorrow);
                return nextSunrise;
            }
        }
    }
    return null;
}

function getHumidity() as Number or Null {
    if (conditions != null && conditions.relativeHumidity != null) {
        return conditions.relativeHumidity;
    }
    return null;
}


function getVisibility() as Number or Null {
    if (conditions != null && conditions.visibility != null) {
        return conditions.visibility;
    }
    return null;
}

function getUpdateTime() as Lang.DateTime or Null {
    if (conditions != null && conditions.timestamp != null) {
        return conditions.timestamp;
    }
    return null;
}



function getUvIndex() as Number or Null {
    if (conditions != null && conditions.uvIndex != null) {
        return conditions.uvIndex;
    }
    return null;
}

function getFeelsLikeTemperature() as Number or Null {
    if (conditions != null && conditions.feelsLikeTemperature != null) {
    var unit = _getProperty("TemperatureUnit", 1);
    if (unit == 2) { // Fahrenheit
            return conditions.feelsLikeTemperature * 9 / 5 + 32;
        } else {
            return conditions.feelsLikeTemperature;
        }
    }
    return null;
}
   function getDewPoint() as Number or Null {
        if (conditions != null) {
            return conditions.dewPoint;
        }
        return null;
   
    }
    function getConditions() as Dictionary or Null {
        return conditions;
    }

    function getPressure() as Number or Null {
        if (conditions != null) {
            return conditions.pressure /100; // Convert Pa to hPa
        }
        return null;
    }

    function getWindSpeed() as Number or Null {
    if (conditions != null) {
    var unit = _getProperty("WindSpeedUnit", 1);
        if (unit == 2) { // 2 = mph
            return conditions.windSpeed * 2.23694;
        } else if (unit == 3) { // 3 = km/h
            return conditions.windSpeed * 3.6;
        } else { // 1 = m/s (default)
            return conditions.windSpeed;
        }
    }
    return null;
    }


   function getWindBearingString() as String {
    if (conditions != null && conditions.windBearing != null) {
        var bearing = conditions.windBearing;
        var directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"];
        var index = Math.floor((bearing + 22.5) / 45).toNumber() % 8;
        return directions[index];
    }
    return "Unknown";
}



function getCompassHeading() as Number or Null {
    var heading = Sensor.getInfo().heading; // Returns heading in degrees (0 = North)
    if (heading != null) {
        return heading.toNumber();
    }
    return null;
}
function getCompassDirectionString() as String {
    var heading = getCompassHeading();
    if (heading == null) {
        return "Unknown";
    }
    var directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"];
    var index = Math.floor((heading + 22.5) / 45).toNumber() % 8;
    return directions[index];
}



function getWindBearing() as Number or Null {
    if (conditions != null && conditions.windBearing != null) {
        return conditions.windBearing;
    }
    return null;
}



    function getCondition() as String or Null {
        if (conditions != null) {
            return conditions.condition;
        }
        return null;
    }


    function getWeatherColor() as Number {
    if (conditions != null) {
        //System.println("Current weather condition: " + conditions.condition);
    } else {
       // System.println("Weather conditions are null.");
    }

    var dynamicWeatherColor = Application.Properties.getValue("DynamicWeatherColor");
    if (dynamicWeatherColor == null) { dynamicWeatherColor = false; }
    if (dynamicWeatherColor == true) {
        if (conditions != null) {
            switch (conditions.condition) {
                case 0:  // Clear
                    return 0xFFFF00; // Bright yellow
                case 1:  // Partly cloudy
                    return 0xFFD700; // Gold
                case 2:  // Mostly cloudy
                    return 0xAAAAAA; // Medium gray
                case 3:  // Rain
                    return 0x0000FF; // Blue
                case 4:  // Snow
                    return 0xFFFFFF; // White
                case 5:  // Windy
                    return 0x00FFFF; // Cyan
                case 6:  // Thunderstorms
                    return 0x000080; // Navy
                case 7:  // Wintry mix
                    return 0xADD8E6; // Light blue
                case 8:  // Fog
                    return 0xCCCCCC; // Light gray
                case 9:  // Hazy
                    return 0xBDB76B; // Khaki
                case 10: // Hail
                    return 0xE0FFFF; // Light cyan
                case 11: // Scattered showers
                    return 0x87CEEB; // Sky blue
                case 12: // Scattered thunderstorms
                    return 0x800080; // Purple
                case 13: // Unknown precipitation
                    return 0xFF00FF; // Magenta
                case 14: // Light rain
                    return 0xB0E0E6; // Powder blue
                case 15: // Heavy rain
                    return 0x191970; // Midnight blue
                case 16: // Light snow
                    return 0xF8F8FF; // Ghost white
                case 17: // Heavy snow
                    return 0xC0C0C0; // Silver
                case 18: // Light rain snow
                    return 0xAFEEEE; // Pale turquoise
                case 19: // Heavy rain snow
                    return 0x4682B4; // Steel blue
                case 20: // Cloudy
                    return 0x808080; // Gray
                case 21: // Rain snow
                    return 0x5F9EA0; // Cadet blue
                case 22: // Partly clear
                    return 0xFFE4B5; // Moccasin
                case 23: // Mostly clear
                    return 0xFFFFE0; // Light yellow
                case 24: // Light showers
                    return 0x40E0D0; // Turquoise
                case 25: // Showers
                    return 0x1E90FF; // Dodger blue
                case 26: // Heavy showers
                    return 0x00008B; // Dark blue
                case 27: // Chance of showers
                    return 0x00BFFF; // Deep sky blue
                case 28: // Chance of thunderstorms
                    return 0x8B0000; // Dark red
                case 29: // Mist
                    return 0xD3D3D3; // Light gray
                case 30: // Dust
                    return 0xDEB887; // Burly wood
                case 31: // Drizzle
                    return 0xAFEEEE; // Pale turquoise
                case 32: // Tornado
                    return 0xFF0000; // Bright red
                case 33: // Smoke
                    return 0x696969; // Dim gray
                case 34: // Ice
                    return 0x00CED1; // Dark turquoise
                case 35: // Sand
                    return 0xF4A460; // Sandy brown
                case 36: // Squall
                    return 0xA52A2A; // Brown
                case 37: // Sandstorm
                    return 0xDAA520; // Goldenrod
                case 38: // Volcanic ash
                    return 0x2F4F4F; // Dark slate gray
                case 39: // Haze
                    return 0xF5F5DC; // Beige
                case 40: // Fair
                    return 0x7CFC00; // Lawn green
                case 41: // Hurricane
                    return 0xFF4500; // Orange red
                case 42: // Tropical storm
                    return 0x00FA9A; // Medium spring green
                case 43: // Chance of snow
                    return 0xE6E6FA; // Lavender
                case 44: // Chance of rain snow
                    return 0xB0C4DE; // Light steel blue
                case 45: // Cloudy chance of rain
                    return 0x4682B4; // Steel blue
                case 46: // Cloudy chance of snow
                    return 0xF0FFFF; // Azure
                case 47: // Cloudy chance of rain snow
                    return 0xB0E0E6; // Powder blue
                case 48: // Flurries
                    return 0xF0FFF0; // Honeydew
                case 49: // Freezing rain
                    return 0x00BFFF; // Deep sky blue
                case 50: // Sleet
                    return 0xB0C4DE; // Light steel blue
                case 51: // Ice snow
                    return 0xE0FFFF; // Light cyan
                case 52: // Thin clouds
                    return 0xF5F5F5; // White smoke
                case 53: // Unknown
                    return 0xFFA500; // Orange
                default:
                    return 0xFFA500; // Orange (fallback/default)
            }
        }
        return 0xFFA500; // Orange (if conditions are null)
    } else {
    var faceColor = Application.Properties.getValue("FaceColor");
    if (faceColor == null) { faceColor = 0x009933; } // Default: #009933
    return faceColor;
    }
}


function getConditionName(condNum as Number) as String {
    var CONDITION_NAMES = {
        0  => "Clear",
        1  => "Partly cld",
        2  => "Mostly cld",
        3  => "Rain",
        4  => "Snow",
        5  => "Windy",
        6  => "T-storms",
        7  => "Wintry mix",
        8  => "Fog",
        9  => "Hazy",
        10 => "Hail",
        11 => "Scatt shwr",
        12 => "Scatt T-strm",
        13 => "Unk precip",
        14 => "Lt rain",
        15 => "Hvy rain",
        16 => "Lt snow",
        17 => "Hvy snow",
        18 => "Lt rn/sn",
        19 => "Hvy rn/sn",
        20 => "Cloudy",
        21 => "Rn/snow",
        22 => "Partly clr",
        23 => "Mostly clr",
        24 => "Lt shwr",
        25 => "Showers",
        26 => "Hvy shwr",
        27 => "Ch shwr",
        28 => "Ch T-strm",
        29 => "Mist",
        30 => "Dust",
        31 => "Drizzle",
        32 => "Tornado",
        33 => "Smoke",
        34 => "Ice",
        35 => "Sand",
        36 => "Squall",
        37 => "Sandstorm",
        38 => "Volc ash",
        39 => "Haze",
        40 => "Fair",
        41 => "Hurricane",
        42 => "Trop storm",
        43 => "Ch snow",
        44 => "Ch rn/sn",
        45 => "Cldy ch rn",
        46 => "Cldy ch sn",
        47 => "Cldy ch rn/sn",
        48 => "Flurries",
        49 => "Frz rain",
        50 => "Sleet",
        51 => "Ice snow",
        52 => "Thin clds",
        53 => "Unknown"
    };

    if (CONDITION_NAMES.hasKey(condNum)) {
        return CONDITION_NAMES[condNum];
    }
    return "Unknown";
}

/*function getConditionIcon(condNum as Number) as ResourceId or Null {
    var CONDITION_ICONS = {
        0  => Rez.Drawables.weatherCondition_Icon0,
        1  => Rez.Drawables.weatherCondition_Icon1,
        2  => Rez.Drawables.weatherCondition_Icon2,
        3  => Rez.Drawables.weatherCondition_Icon3,
        4  => Rez.Drawables.weatherCondition_Icon4,
        5  => Rez.Drawables.weatherCondition_Icon5,
        6  => Rez.Drawables.weatherCondition_Icon6,
        7  => Rez.Drawables.weatherCondition_Icon7,
        8  => Rez.Drawables.weatherCondition_Icon8,
        9  => Rez.Drawables.weatherCondition_Icon9,
        10 => Rez.Drawables.weatherCondition_Icon10,
        11 => Rez.Drawables.weatherCondition_Icon11,
        12 => Rez.Drawables.weatherCondition_Icon12,
        13 => Rez.Drawables.weatherCondition_Icon13,
        14 => Rez.Drawables.weatherCondition_Icon14,
        15 => Rez.Drawables.weatherCondition_Icon15,
        16 => Rez.Drawables.weatherCondition_Icon16,
        17 => Rez.Drawables.weatherCondition_Icon17,
        18 => Rez.Drawables.weatherCondition_Icon18,
        19 => Rez.Drawables.weatherCondition_Icon19,
        20 => Rez.Drawables.weatherCondition_Icon20,
        21 => Rez.Drawables.weatherCondition_Icon21,
        22 => Rez.Drawables.weatherCondition_Icon22,
        23 => Rez.Drawables.weatherCondition_Icon23,
        24 => Rez.Drawables.weatherCondition_Icon24,
        25 => Rez.Drawables.weatherCondition_Icon25,
        26 => Rez.Drawables.weatherCondition_Icon26,
        27 => Rez.Drawables.weatherCondition_Icon27,
        28 => Rez.Drawables.weatherCondition_Icon28,
        29 => Rez.Drawables.weatherCondition_Icon29,
        30 => Rez.Drawables.weatherCondition_Icon30,
        31 => Rez.Drawables.weatherCondition_Icon31,
        32 => Rez.Drawables.weatherCondition_Icon32,
        33 => Rez.Drawables.weatherCondition_Icon33,
        34 => Rez.Drawables.weatherCondition_Icon34,
        35 => Rez.Drawables.weatherCondition_Icon35,
        36 => Rez.Drawables.weatherCondition_Icon36,
        37 => Rez.Drawables.weatherCondition_Icon37,
        38 => Rez.Drawables.weatherCondition_Icon38,
        39 => Rez.Drawables.weatherCondition_Icon39,
        40 => Rez.Drawables.weatherCondition_Icon40,
        41 => Rez.Drawables.weatherCondition_Icon41,
        42 => Rez.Drawables.weatherCondition_Icon42,
        43 => Rez.Drawables.weatherCondition_Icon43,
        44 => Rez.Drawables.weatherCondition_Icon44,
        45 => Rez.Drawables.weatherCondition_Icon45,
        46 => Rez.Drawables.weatherCondition_Icon46,
        47 => Rez.Drawables.weatherCondition_Icon47,
        48 => Rez.Drawables.weatherCondition_Icon48,
        49 => Rez.Drawables.weatherCondition_Icon49,
        50 => Rez.Drawables.weatherCondition_Icon50,
        51 => Rez.Drawables.weatherCondition_Icon51,
        52 => Rez.Drawables.weatherCondition_Icon52,
        53 => Rez.Drawables.weatherCondition_Icon53 // Unknown
    };

    if (CONDITION_ICONS.hasKey(condNum)) {
        return CONDITION_ICONS[condNum];
    }
    return CONDITION_ICONS[53]; // Fallback to "Unknown"



}
*/
function getUVIndexString() as String {
    var uv = getUvIndex();
    if (uv == null) {
        return "-";
    }
    return uv.format("%d");
}



function getHumidityString() as String {
    var humidity = getHumidity();
    if (humidity == null) {
        return "-";
    }
    return humidity.toString() + "%";
}


function getSunEventTimeString() as String {
    var sunEvent = getSunEventTime();
    //System.println("Sun Event: " + sunEvent);
    if (sunEvent == null) {
        return "-";
    }
    var info = Time.Gregorian.info(sunEvent, Time.FORMAT_SHORT);
    var hour = info.hour;
    var min = info.min;
    return hour.format("%02d") + ":" + min.format("%02d");
}




}