/*var splitData = function(data) {
	var lines = data.split(/\n/);
	console.log("lines: ["+lines[0].length+"]");
	var rows = new Array(lines.length);
	for (var i = 0; i < lines.length; ++i) {
		rows[i] = lines[i].split(';');
	}
	return rows;
}*/

var splitData = function(data) {
	var lines = data.split(/\n/);
	var rows = [];
	for (var i in lines) {
		if(lines[i].length>0) {
			rows.push(lines[i].split(';'));
		}
	}
	return rows;
}

var getID = function(id) {
	return document.getElementById(id);
}

var newTable = function(root) {
	return root.appendChild(document.createElement("table"));
}

var newTableRow = function(table) {
	return table.appendChild(document.createElement("tr"));
}

var newTableEntry = function(row,text) {
	var entry = row.appendChild(document.createElement("td"));
	entry.appendChild(document.createTextNode(text));	
	return entry;
}

var newTableHeaderEntry = function(row,text) {
	var entry = row.appendChild(document.createElement("th"));
	entry.appendChild(document.createTextNode(text));	
	return entry;
}

var appendButton = function(element, text) {
	var button = element.appendChild(document.createElement("button"));
	button.appendChild(document.createTextNode(text));
	return button;
}

var clear = function(element) {
	element.textContent = "";
}
var clear_println = function(element,text) {
	element.textContent = "";
	element.appendChild(document.createElement("p")).appendChild(document.createTextNode(text));
}

var println = function(element,text) {
	element.appendChild(document.createElement("p")).appendChild(document.createTextNode(text));
}

$.postJSON = function(url, data, callback) {
    return jQuery.ajax({
        'type': 'POST',
        'url': url,
        'contentType': 'application/json',
        'data': JSON.stringify(data),
        //'dataType': 'json',  //received data type
        'success': callback
    });
};

$.postJSONJSON = function(url, data, callback) {
    return jQuery.ajax({
        'type': 'POST',
        'url': url,
        'contentType': 'application/json',
        'data': JSON.stringify(data),
        'dataType': 'json',  //received data type
        'success': callback
    });
};

var array_to_html_list = function(element,array) {
	var list = element.appendChild(document.createElement("ul"));
	for(i in array) {
		list.appendChild(document.createElement("li")).appendChild(document.createTextNode(array[i]));
	}
}

