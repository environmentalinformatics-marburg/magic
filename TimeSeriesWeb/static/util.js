var splitData = function(data) {
	var lines = data.split(/\n/);
	var rows = new Array(lines.length);
	for (var i = 0; i < lines.length; ++i) {
		rows[i] = lines[i].split(';');
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