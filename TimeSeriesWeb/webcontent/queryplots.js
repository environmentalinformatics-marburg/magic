var region_select;
var generalstation_select;
var plot_select;
var time_select;
var time_month_select;
var aggregation_select;
var quality_select;
var qualities = ["no", "physical", "step", "empirical"];
var qualitiesText = ["0: no","1: physical","2: physical + step","3: physical + step + empirical"];
var timeText = ["[all]","2008","2009","2010","2011","2012","2013","2014","2015"];
var monthText = ["[whole year]","jan","feb","mar","apr","may","jun","jul","aug","sep","oct","nov","dec"];
var aggregationText = ["raw","hour","day","week","month","year"];

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
	plot_select = $("#plot_select");
	time_select = $("#time_select");
	time_month_select = $("#time_month_select");
	aggregation_select = $("#aggregation_select");
	quality_select = $("#quality_select");
	$.each(qualitiesText, function(i,text) {quality_select.append(new Option(text,i));});
	quality_select.val(2);
	$.each(timeText, function(i,text) {time_select.append(new Option(text,i));});
	time_month_select.hide();
	$.each(monthText, function(i,text) {time_month_select.append(new Option(text,i));});
	$.each(aggregationText, function(i,text) {aggregation_select.append(new Option(text));});
	aggregation_select.val("hour");
	
	getID("region_select").onchange = updateGeneralStations;
	getID("generalstation_select").onchange = updatePlots;
	getID("time_select").onchange = onUpdateTime;	
	getID("aggregation_select").onchange = onUpdateAggregation;
	getID("query_plot").onclick = runQueryPlot;
	
	updataRegions();
	decTask();
});


function onUpdateTime() {
	if(time_select.val()==0) {
		time_month_select.hide();
	} else {
		time_month_select.show();
	}
}

function onUpdateAggregation() {
	if(aggregation_select.val()=="raw") {
		$("#div_quality_select").hide();
		$("#div_interpolated").hide();
	} else {
		$("#div_quality_select").show();
		$("#div_interpolated").show();
	}
}


var updataRegions = function() {
	incTask();
	region_select.empty();
	$.get("../tsdb/region_list").done(function(data) {
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
	$.get("../tsdb/generalstation_list?region="+regionName).done(function(data) {
		var rows = splitData(data);
		var pre = -1;
		$.each(rows, function(i,row) {
			generalstation_select.append(new Option(row[1],row[0]));
			if(row[0]==="HEG") {
				pre = i;
			}
		})
		
		if(pre>0) {
			generalstation_select.val(rows[pre][0]);
		}
		
		updatePlots();
		decTask();	
	}).fail(function() {generalstation_select.append(new Option("[error]","[error]"));decTask();});
}

var updatePlots = function() {
	incTask();
	var generalstationName = generalstation_select.val();
	plot_select.empty();	
	$.get("../tsdb/plot_list?generalstation="+generalstationName).done(function(data) {
		var rows = splitData(data);
		$.each(rows, function(i,row) {plot_select.append(new Option(row[0],row[0]));})
		decTask();
	}).fail(function() {plot_select.append(new Option("[error]","[error]"));decTask();});
}

var runQueryPlot = function() {
	incTask();
	getID("result").innerHTML = "query...";
	var plotName = plot_select.val();
	$.get("../tsdb/sensor_list?plot="+plotName).done(function(data) {
		getID("result").innerHTML = "";
		sensors = splitData(data);
		$.each(sensors, function(i,row) {addDiagram(plotName,row[0],row[1],row[2]);})
		decTask();
	}).fail(function() {getID("result").innerHTML = "error";decTask();});
}

var addDiagram = function(plotName, sensorName, sensorDesc, sensorUnit) {
	incTask();
	var sensorResult = getID("result").appendChild(document.createElement("div"));
	var sensorResultTitle = sensorResult.appendChild(document.createElement("div"));
	sensorResultTitle.innerHTML += "query "+sensorName+"...";
	var aggregationName = aggregation_select.val();
	var qualityName = qualities[quality_select.val()];
	var interpolatedName = ""+getID("interpolated").checked;
	var timeParameter = "";
	var timeName = timeText[time_select.val()];
	if(timeName!="[all]") {
		timeParameter = "&year="+timeName;
		var month = time_month_select.val();
		if(month!=0) {
			timeParameter += "&month="+month;
		}
	}
	incTask();
	var image = new Image();
	sensorResult.appendChild(image);
	image.onload = function() {
		sensorResultTitle.innerHTML = sensorName+": "+sensorDesc+" - "+sensorUnit;
		decTask();
	}
	image.onerror = function() {	
		sensorResultTitle.innerHTML = sensorName+": no data";
		sensorResultTitle.style.color = "grey";
		sensorResult.removeChild(image);
		decTask();
	}
	image.src = "../tsdb/query_image?plot="+plotName+"&sensor="+sensorName+"&aggregation="+aggregationName+"&quality="+qualityName+"&interpolated="+interpolatedName+timeParameter;
	decTask();	
}