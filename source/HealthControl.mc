import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Position;
import Toybox.Weather;
using Toybox.Application.Properties;
import Toybox.Math;
import Toybox.Time;
import Toybox.ActivityMonitor;



class HealthControl {


function HealthControl() {
     // Constructor code here

}

function getStepGoal() as Number or Null {
    return Toybox.ActivityMonitor.getInfo().stepGoal;
}

function getStepsRatioThresholded() as Float or Null {
    var stepGoal = getStepGoal();
    var steps = getSteps();

    if (steps == null || stepGoal == null) {
        return null;
    }

    if (steps > stepGoal) {
        steps = stepGoal;
    }

    return 1.0 * steps / stepGoal;
}

function getSteps() as Number or Null {
    return Toybox.ActivityMonitor.getInfo().steps;
}

function getStepsString() as String {
    var steps = getSteps();
    if (steps == null) {
        return "-";
    }
    return getSteps().format("%d");
}


function getCalories() as Number or Null {
    var info = Toybox.ActivityMonitor.getInfo();
    if (info != null && info.calories != null) {
        return info.calories;
      
    }
    return null;
}


function getStressIterator() {
    if ((Toybox has: SensorHistory) && (Toybox.SensorHistory has: getStressHistory)) {
        return Toybox.SensorHistory.getStressHistory({: period => 1,
            : order => Toybox.SensorHistory.ORDER_NEWEST_FIRST
        });
    }
    return null;
}


function getStress() as Number or Null {
    var stressIterator = getStressIterator();
    if (stressIterator != null) {
        var sample = stressIterator.next();
        while (sample != null) {
            if (sample.data != null) {
                return sample.data;
            }
            sample = stressIterator.next();
        }
    }
    return null;
}

function getStressString() as String {
    var stressIterator = getStressIterator();
    if (stressIterator != null) {
        var sample = stressIterator.next();
        while (sample != null) {
            if (sample.data != null) {
                return sample.data.format("%d");
            }
            sample = stressIterator.next();
        }
    }
    return "-";
}


function getDistance() as Number or Null {
    var info = Toybox.ActivityMonitor.getInfo();
    if (info != null && info.steps != null) {
        var steps = info.steps;
        var strideLength = 0.75; // meters per step (average)
        var distanceMeters = steps * strideLength;
        var unit = Application.Properties.getValue("DistanceUnit");
        if (unit == null) { unit = 1; } // Default: 1 (Kilometers)
        var value;
        if (unit == 2) { // Miles
            value = distanceMeters / 1609.344;
        } else { // Kilometers (default)
            value = distanceMeters / 1000.0;
        }
        return value as Number;
    }
    return null;
}

function getBodyBatteryIterator() {
    if ((Toybox has: SensorHistory) && (Toybox.SensorHistory has: getBodyBatteryHistory)) {
        return Toybox.SensorHistory.getBodyBatteryHistory({: period => 1,
            : order => Toybox.SensorHistory.ORDER_NEWEST_FIRST
        });
    }
    return null;
}

function getBodyBattery() as Number or Null {
    var bbIterator = getBodyBatteryIterator();
    var sample = bbIterator.next();

    while (sample != null) {
        if (sample.data != null) {
            return sample.data;
        }
        sample = bbIterator.next();
    }

    return null;
}

function getBodyBatteryString() as String {
    var bodyBattery = getBodyBattery();
    if (bodyBattery == null) {
        return "-";
    }
    return bodyBattery.format("%d") + "%";
}


function getHeartRate() as Number or Null {
    var heartrateIterator = Toybox.ActivityMonitor.getHeartRateHistory(1, true);
    var sample = heartrateIterator.next();
    if (sample != null && sample.heartRate != null) {
        return sample.heartRate;
    }
    return null;
}

function getHeartRateString() as String {
    var hr = getHeartRate();
    if (hr == null || hr == 255) {
        return "-";
    }
    return hr.format("%d");
}



}

