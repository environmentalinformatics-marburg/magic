var region_input;
var generalstation_input;
var plot_input;
var sensor_input;

var sensors = "";

var getList = function(url) {
}

$(document).ready(function(){
	region_input = $("#region_input");
	generalstation_input = $("#generalstation_input");
	plot_input = $("#plot_input");
	sensor_input = $("#sensor_input");
	updataRegions();
});

var updataRegions = function() {
	region_input.empty();
	$.get("/tsdb/region_list").done(function(data) {
		var rows = splitData(data);
		$.each(rows, function(i,row) {region_input.append(new Option(row[1],row[0]));});
		updateGeneralStations();		
	}).fail(function() {region_input.append(new Option("[error]","[error]"));});
}

var updateGeneralStations = function() {
	var regionName = region_input.val();
	generalstation_input.empty();	
	$.get("/tsdb/generalstation_list?region="+regionName).done(function(data) {
		var rows = splitData(data);
		$.each(rows, function(i,row) {generalstation_input.append(new Option(row[1],row[0]));})
		updatePlots();		
	}).fail(function() {generalstation_input.append(new Option("[error]","[error]"));});
}

var updatePlots = function() {
	var generalstationName = generalstation_input.val();
	plot_input.empty();	
	$.get("/tsdb/plot_list?generalstation="+generalstationName).done(function(data) {
		var rows = splitData(data);
		$.each(rows, function(i,row) {plot_input.append(new Option(row[0],row[0]));})
		updateSensors();		
	}).fail(function() {plot_input.append(new Option("[error]","[error]"));});
}

var updateSensors = function() {
	var plotName = plot_input.val();
	sensor_input.empty();	
	$.get("/tsdb/sensor_list?plot="+plotName).done(function(data) {
		sensors = splitData(data);
		$.each(sensors, function(i,row) {document.getElementById("sensor_input").add(new Option(row[0],i));})
		updateSensor();		
	}).fail(function() {plot_input.append(new Option("[error]","[error]"));});
}

var updateSensor = function() {
	var row = sensors[sensor_input.val()];
	getID("sensor_description").innerHTML = row[1];
	getID("sensor_unit").innerHTML = row[2];
}

var runQuery = function() {
	getID("result").innerHTML = "query...";
	$.get("/tsdb/query")
		.done(function(data) {
			var rows = splitData(data);
			var result = getID("result");
			var table = newTable();
			var trHeader = newTableRow(table);
			newTableHeaderEntry(trHeader,"h1");
			newTableHeaderEntry(trHeader,"h2");		
			for(i in rows) {
				var row = rows[i];
				var trRow = newTableRow(table);
				newTableEntry(trRow,row[0]);
				newTableEntry(trRow,row[1]);
			}
		})
		.fail(function() {
			getID("result").innerHTML = "error";
		});	
} 