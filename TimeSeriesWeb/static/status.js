var region_select;
var generalstation_select;

var tasks = 0;

var incTask = function() {
	runDisabled(true);
	tasks++;	
	getID("status").innerHTML = "busy ("+tasks+")...";
}

var decTask = function() {
	tasks--;
	if(tasks===0) {
		getID("status").innerHTML = "ready";
		runDisabled(false);
	} else if(tasks<0){
		getID("status").innerHTML = "error";
	} else {
		getID("status").innerHTML = "busy ("+tasks+")...";
	}
}

function runDisabled(disabled) {
	$(".blockable").prop( "disabled",disabled);
}


$(document).ready(function(){
	incTask();
	region_select = $("#region_select");
	generalstation_select = $("#generalstation_select");
	
	getID("region_select").onchange = updateGeneralStations;
	getID("query_button").onclick = runQuery;
	
	updataRegions();
	decTask();
});

var updataRegions = function() {
	incTask();
	region_select.empty();
	$.get("/tsdb/region_list").done(function(data) {
		var rows = splitData(data);
		$.each(rows, function(i,row) {region_select.append(new Option(row[1],row[0]));});
		updateGeneralStations();
		decTask();		
	}).fail(function() {region_select.append(new Option("[error]","[error]"));decTask();});
}

var updateGeneralStations = function() {
	incTask();
	var regionName = region_select.val();
	generalstation_select.empty();	
	$.get("/tsdb/generalstation_list?region="+regionName).done(function(data) {
		var rows = splitData(data);
		$.each(rows, function(i,row) {generalstation_select.append(new Option(row[1],row[0]));})
		decTask();	
	}).fail(function() {generalstation_select.append(new Option("[error]","[error]"));decTask();});
}



var runQuery = function() {
	getID("result").innerHTML = "Getting data from server. This may take some time...";
	generalStationName = generalstation_select.val();
	$.getJSON("/tsdb/timespan?general_station="+generalStationName).done(function(interval) {
		getID("result").innerHTML = "";
		var min_last = 999999999;
		var max_last = 0;
		for(i in interval) {
			if(interval[i].last_timestamp<min_last) {
				min_last = interval[i].last_timestamp;
			}
			if(max_last<interval[i].last_timestamp) {
				max_last = interval[i].last_timestamp;
			}			
		}		
		for(i in interval) {
			var t = max_last - interval[i].last_timestamp;
			var timeMark = "timeMarkOneMonth";
			if(t>60*24*7*4) {
				timeMark = "timeMarkOneMonth";
			} else if(t>60*24*7*2) {
				timeMark = "timeMarkTwoWeeks";
			} else if(t>60*24*7) {
				timeMark = "timeMarkOneWeek";
			} else {
				timeMark = "timeMarkNow";
			}
			
		
			getID("result").innerHTML += "<p id=\""+timeMark+"\">"+interval[i].plot+"&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"+interval[i].first_datetime+" - "+interval[i].last_datetime+"&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"+parseInt((max_last - interval[i].last_timestamp)/(60*24))+" days</p>";
		}
	}).fail(function() {getID("result").innerHTML = "error";});
}
