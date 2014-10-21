var region_select;
var generalstation_select;
var sensor_select;
var aggregation_select;
var quality_select;
var qualities = ["no", "physical", "step", "empirical"];
var qualitiesText = ["0: no","1: physical","2: physical + step","3: physical + step + empirical"];


var sensors;

var tasks = 0;

$(document).ready(function(){
	incTask();
	region_select = $("#region_select");
	generalstation_select = $("#generalstation_select");
	sensor_select = $("#sensor_select");
	aggregation_select = $("#aggregation_select");
	quality_select = $("#quality_select");
	$.each(qualitiesText, function(i,text) {quality_select.append(new Option(text,i));});
	
	getID("region_select").onchange = updateGeneralStations;
	getID("generalstation_select").onchange = updateSensors;	
	getID("sensor_select").onchange = updateSensor;
	getID("query_sensor").onclick = runQuerySensor;
	
	updataRegions();
	decTask();
});

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
		updateSensors();
		decTask();		
	}).fail(function() {generalstation_select.append(new Option("[error]","[error]"));decTask();});
}

var updateSensors = function() {
	incTask();
	var general_station = generalstation_select.val();
	sensor_select.empty();	
	$.get("/tsdb/general_station_sensor_list?general_station="+general_station).done(function(data) {
		var rows = splitData(data);
		sensors = rows
		//$.each(sensors, function(i,row) {document.getElementById("sensor_select").add(new Option(row[0],i));})
		$.each(rows, function(i,row) {sensor_select.append(new Option(row[0],i));})
		updateSensor();
		decTask();
	}).fail(function() {plot_select.append(new Option("[error]","[error]"));decTask();});
}

var updateSensor = function() {
	incTask();
	var row = sensors[sensor_select.val()];
	getID("sensor_description").innerHTML = row[1];
	getID("sensor_unit").innerHTML = row[2];
	decTask();
}

var runQuerySensor = function() {
	incTask();
	getID("result").innerHTML = "query...";
	var sensorName = sensors[sensor_select.val()][0];
	var generalstationName = generalstation_select.val();
	$.get("/tsdb/plot_list?generalstation="+generalstationName).done(function(data) {
		getID("result").innerHTML = "";	
		var rows = splitData(data);
		$.each(rows, function(i,row) {addDiagram(row[0],sensorName);})
		decTask();		
	}).fail(function() {getID("result").innerHTML = "error";decTask();})
}

var addDiagram = function(plotName, sensorName) {
	incTask();
	var plotResult = getID("result").appendChild(document.createElement("div"));
	var plotResultTitle = plotResult.appendChild(document.createElement("div"));
	plotResultTitle.innerHTML += "query "+plotName+"...";
	var aggregationName = aggregation_select.val();
	var qualityName = qualities[quality_select.val()];
	var interpolatedName = ""+getID("interpolated").checked;
	var image = new Image();
	plotResult.appendChild(image);
	image.onload = function() {
		plotResultTitle.innerHTML = plotName;
		decTask();
	}
	image.onerror = function() {	
		plotResultTitle.innerHTML = plotName+": no data";
		plotResultTitle.style.color = "grey";
		plotResult.removeChild(image);
		decTask();
	}
	image.src = "/tsdb/query_image?plot="+plotName+"&sensor="+sensorName+"&aggregation="+aggregationName+"&quality="+qualityName+"&interpolated="+interpolatedName;	
}
