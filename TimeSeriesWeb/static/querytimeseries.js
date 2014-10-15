var region_input;
var generalstation_input;
var plot_input;
var sensor_input;
var aggregation_input;
var aggregations = ["hour","day","week","month","year"];

var sensors = "";

var tasks = 0;

var incTask = function() {
	tasks++;	
	getID("status").innerHTML = "busy ("+tasks+")...";
}

var decTask = function() {
	tasks--;
	if(tasks===0) {
		getID("status").innerHTML = "ready";
	} else if(tasks<0){
		getID("status").innerHTML = "error";
	} else {
		getID("status").innerHTML = "busy ("+tasks+")...";
	}
}

var getList = function(url) {
}

$(document).ready(function(){
incTask();
region_input = $("#region_input").selectmenu();
region_input.on("selectmenuchange", function( event, ui ) {updateGeneralStations();} );

generalstation_input = $("#generalstation_input").selectmenu()
generalstation_input.on( "selectmenuchange", function( event, ui ) {updatePlots();} );

plot_input = $("#plot_input").selectmenu();
plot_input.on("selectmenuchange", function( event, ui ) {updateSensors();} );

sensor_input = $("#sensor_input").selectmenu();
sensor_input.on("selectmenuchange", function( event, ui ) {updateSensor();} );

aggregation_input = $("#aggregation_input").selectmenu();
//aggregation_input.on("selectmenuchange", function( event, ui ) {updateAggregation();} );
$.each(aggregations, function(i,agg) {aggregation_input.append(new Option(agg,i));});
aggregation_input.selectmenu("refresh");

$("#query_button").button().on("click",runQueryTable);

$("#image_button").button().on("click",runQueryDiagram);


updataRegions();

decTask();
});

var updataRegions = function() {
	incTask();
	region_input.empty();
	$.get("/tsdb/region_list").done(function(data) {
		var rows = splitData(data);
		$.each(rows, function(i,row) {region_input.append(new Option(row[1],row[0]));});
		region_input.selectmenu( "refresh" );
		updateGeneralStations();
		decTask();		
	}).fail(function() {region_input.append(new Option("[error]","[error]"));decTask();});
}

var updateGeneralStations = function() {
	incTask();
	var regionName = region_input.val();
	generalstation_input.empty();	
	$.get("/tsdb/generalstation_list?region="+regionName).done(function(data) {
		var rows = splitData(data);
		$.each(rows, function(i,row) {generalstation_input.append(new Option(row[1],row[0]));})
		generalstation_input.selectmenu( "refresh" );
		updatePlots();
		decTask();		
	}).fail(function() {generalstation_input.append(new Option("[error]","[error]"));decTask();});
}

var updatePlots = function() {
	incTask();
	var generalstationName = generalstation_input.val();
	plot_input.empty();	
	$.get("/tsdb/plot_list?generalstation="+generalstationName).done(function(data) {
		var rows = splitData(data);
		$.each(rows, function(i,row) {plot_input.append(new Option(row[0],row[0]));})
		plot_input.selectmenu( "refresh" );
		updateSensors();
		decTask();		
	}).fail(function() {plot_input.append(new Option("[error]","[error]"));decTask();});
}

var updateSensors = function() {
	incTask();
	var plotName = plot_input.val();
	sensor_input.empty();	
	$.get("/tsdb/sensor_list?plot="+plotName).done(function(data) {
		sensors = splitData(data);
		$.each(sensors, function(i,row) {document.getElementById("sensor_input").add(new Option(row[0],i));})
		sensor_input.selectmenu( "refresh" );
		updateSensor();
		decTask();	
	}).fail(function() {plot_input.append(new Option("[error]","[error]"));decTask();});
}

var updateSensor = function() {
	var row = sensors[sensor_input.val()];
	getID("sensor_description").innerHTML = row[1];
	getID("sensor_unit").innerHTML = row[2];
}

var getQueryParameters = function() {
	var plotName = plot_input.val();
	var sensorName = sensors[sensor_input.val()][0];
	var aggregationName = aggregations[aggregation_input.val()];
	return "plot="+plotName+"&sensor="+sensorName+"&aggregation="+aggregationName;
}

var runQueryTable = function() {
	incTask();
	getID("result").innerHTML = "query...";
	var plotName = plot_input.val();
	var sensorName = sensors[sensor_input.val()][0];
	var aggregationName = aggregations[aggregation_input.val()];
	$.get("/tsdb/query?plot="+plotName+"&sensor="+sensorName+"&aggregation="+aggregationName)
		.done(function(data) {
			rows = splitData(data);
			createTable(rows);
			decTask();					
		})
		.fail(function() {
			getID("result").innerHTML = "no data";
			decTask();
		});	
}

var runQueryDiagram = function() {
	incTask();
	$("#result").empty();
	var query = getQueryParameters();
	var image = new Image();
	getID("result").appendChild(image);
	image.onload = function() {
		decTask();
	}	
	image.onerror = function() {
		getID("result").innerHTML = "no data";
		decTask();
	}
	image.src = "/tsdb/query_image?"+query;
}

var createTable = function(rows) {
	$("#result").empty();
	var result = getID("result");
	var table = newTable(result);
	var trHeader = newTableRow(table);
	newTableHeaderEntry(trHeader,"timestamp");
	newTableHeaderEntry(trHeader,"value");		
	for(i in rows) {
		var row = rows[i];
		var trRow = newTableRow(table);
		newTableEntry(trRow,row[0]);
		newTableEntry(trRow,row[1]);
	}	
}