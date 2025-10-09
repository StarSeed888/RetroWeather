import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Position;
import Toybox.Weather;
using Toybox.Application.Properties;
import Toybox.Math;
import Toybox.Time;

class SystemStatsControl{

function SystemStatsControl() {
    //Constructor if needed

}


function getBattery() as Float {
    return Toybox.System.getSystemStats().battery;
}

function getBatteryString() as String {
    return getBattery().format("%d") + "%";
}


function getDate() as String {
   var now = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
    var MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    var monthStr = MONTHS[now.month - 1];
    return now.day.format("%d") + " " + monthStr;
}







}