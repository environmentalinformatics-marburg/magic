var region_input;
var generalstation_input;
var plot_input;
var sensor_input;
var aggregation_input;
var aggregations = ["hour","day","week","month","year"];

var sensors = "";

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

aggregation_input = $("#aggregation_input").selectmenu();
//aggregation_input.on("selectmenuchange", function( event, ui ) {updateAggregation();} );
$.each(aggregations, function(i,agg) {aggregation_input.append(new Option(agg,i));});
aggregation_input.selectmenu("refresh");

$("#query_button").button().on("click",runQuery);

$("#image_button").button().on("click",runImage);

$("#radio").buttonset();


updataRegions();
});

var updataRegions = function() {
	region_input.empty();
	$.get("/tsdb/region_list").done(function(data) {
		var rows = splitData(data);
		$.each(rows, function(i,row) {region_input.append(new Option(row[1],row[0]));});
		region_input.selectmenu( "refresh" );
		updateGeneralStations();		
	}).fail(function() {region_input.append(new Option("[error]","[error]"));});
}

var updateGeneralStations = function() {
	var regionName = region_input.val();
	generalstation_input.empty();	
	$.get("/tsdb/generalstation_list?region="+regionName).done(function(data) {
		var rows = splitData(data);
		$.each(rows, function(i,row) {generalstation_input.append(new Option(row[1],row[0]));})
		generalstation_input.selectmenu( "refresh" );
		updatePlots();		
	}).fail(function() {generalstation_input.append(new Option("[error]","[error]"));});
}

var updatePlots = function() {
	var generalstationName = generalstation_input.val();
	plot_input.empty();	
	$.get("/tsdb/plot_list?generalstation="+generalstationName).done(function(data) {
		var rows = splitData(data);
		$.each(rows, function(i,row) {plot_input.append(new Option(row[0],row[0]));})
		plot_input.selectmenu( "refresh" );
		updateSensors();		
	}).fail(function() {plot_input.append(new Option("[error]","[error]"));});
}

var updateSensors = function() {
	var plotName = plot_input.val();
	sensor_input.empty();	
	$.get("/tsdb/sensor_list?plot="+plotName).done(function(data) {
		sensors = splitData(data);
		$.each(sensors, function(i,row) {document.getElementById("sensor_input").add(new Option(row[0],i));})
		sensor_input.selectmenu( "refresh" );
		updateSensor();		
	}).fail(function() {plot_input.append(new Option("[error]","[error]"));});
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

var runQuery = function() {
	getID("result").innerHTML = "query...";
	var plotName = plot_input.val();
	var sensorName = sensors[sensor_input.val()][0];
	var aggregationName = aggregations[aggregation_input.val()];
	$.get("/tsdb/query?plot="+plotName+"&sensor="+sensorName+"&aggregation="+aggregationName)
		.done(function(data) {
					rows = splitData(data);
					//createTable(rows); 
					//createDiagram(rows);
					updateView();
		})
		.fail(function() {
			getID("result").innerHTML = "no data";
		});	
}

var runImage = function() {
	$("#result").empty();
	var query = getQueryParameters();
	var image = new Image();
	getID("result").appendChild(image);
	image.onerror = function() {
		getID("result").innerHTML = "no data";
	}
	image.src = "/tsdb/query_image?"+query;
	//var img = document.createElement("img");
	//img.setAttribute("src","/tsdb/query_image?"+query);
	//getID("result").appendChild(img);
}

var updateView = function() {
	if(document.getElementById("radioTable").checked) {
		createTable(rows);
	} else {
		createDiagram(rows);
	}
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

var createDiagram = function(rows) {
	var w = window.innerWidth-60;
	var h = window.innerHeight-400;		
	$("#result").empty();
	var svg = d3.select("#result").append("svg").attr("width", w).attr("height", h).attr("style","background-color:#ffffff");
	var padding = 40;
	var parseDate = d3.time.format.utc("%Y-%m-%dT%H:%M").parse;
	
	var dataset = new Array(rows.length);
	for (var i = 0; i < rows.length; ++i) {
		dataset[i] = [parseDate(rows[i][0]),+rows[i][1]];
	}
	
	var xScale = d3.time.scale()
					    .domain(d3.extent(dataset, function(row) {return row[0];}))
					    .range([padding,w-padding]);
						
	var yScale = d3.scale.linear()
					 .domain([d3.min(dataset, function(d) {return d[1];}),
					          d3.max(dataset, function(d) {return d[1];})
							  ])
					 .range([h-padding,padding])
					 .nice();

	var xAxis = d3.svg.axis()
					.scale(xScale)
					.orient("bottom");
						  
	var yAxis = d3.svg.axis()
					  .scale(yScale)
					  .orient("left");
					  
	var area = d3.svg.area()
					.x(function(d) { return xScale(d[0]); })
					.y0(function(d) { if(isNaN(d[1])) return h-padding; else return yScale(d[1]); })
					.y1(h-padding);

	svg.append("path")
		   .datum(dataset)
		   .attr("d", area)
		   .attr("fill","rgb(230,230,230)");

	svg.selectAll("circle").data(dataset).enter().append("circle")
		   .attr("cx", function(d) {return xScale(d[0]);})
		   .attr("cy", function(d) {return yScale(d[1]);})
		   .attr("r", 0.5)
		   .attr("fill", "rgb(0,0,0)");

	svg.append("g").attr("class", "axis")
				   .attr("transform", "translate(0,"+ (h-padding)+")")
				   .call(xAxis);
					   
	svg.append("g").attr("class", "axis")
				.attr("transform", "translate("+padding+",0)")
			    .call(yAxis);		   

}






 