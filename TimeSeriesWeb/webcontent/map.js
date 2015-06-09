var url_base = "../";
var url_plot_info = url_base + "tsdb/plot_info";	
	
var map;

function document_ready() {
	var mapOptions = { zoom: 11, center: new google.maps.LatLng(-3.1738427, 37.3574291) };
	map = new google.maps.Map(document.getElementById('map-canvas'), mapOptions);
	$.get(url_plot_info).done(function(plots) {
		for(var i in plots) {
			var plot = plots[i];
			if(plot.lat!=undefined && plot.lon!=undefined) {	  
				var myLatlng = new google.maps.LatLng(plot.lat, plot.lon);
				//console.log(plot.name+"  "+plot.lat,"  "+plot.lon);	
				
				var populationOptions = {
					strokeColor: '#FF0000',
					strokeOpacity: 1.0,
					strokeWeight: 2,
					fillColor: '#FF0000',
					fillOpacity: 0.5,
					map: map,
					center: myLatlng,
					radius: 100,
					title: 'Hello World!'
				};			
				new google.maps.Circle(populationOptions);
				
				/*var myicon = 'http://chart.apis.google.com/chart?chst=d_map_pin_letter&chld='+plot.name+'|FF0000|000000'
				
				var marker = new google.maps.Marker({
							position: myLatlng,
							map: map,
							title: 'Hello World!',
							icon: myicon
							});*/

				
			}
		}
	}).fail(function() {sensor_select.append(new Option("[error]","[error]"));decTask();});	
} // END document_ready 
