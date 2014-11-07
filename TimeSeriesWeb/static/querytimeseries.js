var region_input;
var generalstation_input;
var plot_input;
var sensor_input;
var time_input;
var aggregation_input;
var aggregations = ["hour","day","week","month","year"];
var quality_input;
var qualities = ["no", "physical", "step", "empirical"];
var qualitiesText = ["0: no","1: physical","2: physical + step","3: physical + step + empirical"];
var timeText = ["[all]","2008","2009","2010","2011","2012","2013","2014"];

var sensors = "";

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
	var disableText;
	if(disabled) {
		disableText = "disable";
	} else {
		disableText = "enable";
	}
	$("#query_button").button(disableText);
	$("#image_button").button(disableText);
}

var getList = function(url) {
}

$(document).ready(function(){

region_input = $("#region_input").selectmenu();
region_input.on("selectmenuchange", function( event, ui ) {updateGeneralStations();} );

generalstation_input = $("#generalstation_input").selectmenu()
generalstation_input.on( "selectmenuchange", function( event, ui ) {updatePlots();} );

plot_input = $("#plot_input").selectmenu();
plot_input.on("selectmenuchange", function( event, ui ) {updateSensors();} );

sensor_input = $("#sensor_input").selectmenu();
sensor_input.on("selectmenuchange", function( event, ui ) {updateSensor();} );

time_input = $("#time_input").selectmenu();
$.each(timeText, function(i,text) {time_input.append(new Option(text,i));});
time_input.selectmenu("refresh");

aggregation_input = $("#aggregation_input").selectmenu();
$.each(aggregations, function(i,agg) {aggregation_input.append(new Option(agg,i));});
aggregation_input.selectmenu("refresh");

quality_input = $("#quality_input").selectmenu();
$.each(qualitiesText, function(i,text) {quality_input.append(new Option(text,i));});
quality_input.selectmenu("refresh");

$("#query_button").button().on("click",runQueryTable);

$("#image_button").button().on("click",runQueryDiagram);

incTask();

updataRegions();

decTask();

//$("#time_range").slider({range:true,min:2008*12,max:2014*12,values: [ 2008*12, 2014*12 ],slide:update_time_range_text});
//update_time_range_text();

});

/*
var month_text = ["err","jan","feb","mar","apr","may","jun","jul","aug","sep","oct","nov","dec"];

function valueToDate(value) {
	var m = value%12;
	var y = (value-m)/12;
	return month_text[(m+1)]+" "+y;
}

function update_time_range_text() {
 $("#time_range_text").val( valueToDate($( "#time_range" ).slider( "values", 0 )) +
" - " + valueToDate($( "#time_range" ).slider( "values", 1 )) );
}
*/

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
	var qualityName = qualities[quality_input.val()];
	var interpolatedName = ""+getID("interpolated").checked;
	var timeParameter = "";
	var timeName = timeText[time_input.val()];
	if(timeName!="[all]") {
		timeParameter = "&year="+timeName;
	}	
	return "plot="+plotName+"&sensor="+sensorName+"&aggregation="+aggregationName+"&quality="+qualityName+"&interpolated="+interpolatedName+timeParameter;
}

var runQueryTable = function() {
	incTask();
	getID("result").innerHTML = "query...";
	var query = getQueryParameters();
	$.get("/tsdb/query?"+query)
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