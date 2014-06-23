package util;

import java.io.FileReader;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.apache.logging.log4j.Logger;

import au.com.bytecode.opencsv.CSVReader;

public class Table {

	private static final Logger log = Util.log;

	public String[] names;
	public Map<String, Integer> nameMap;
	public String[][] rows;


	private Table() {

	}


	public static Table readCSV(String filename) {
		try {
			Table table = new Table();
			
			CSVReader reader = new CSVReader(new FileReader(filename));
			List<String[]> list = reader.readAll();

			table.names = list.get(0);
			
			table.nameMap = new HashMap();

			for(int i=0;i<table.names.length;i++) {
				if(table.nameMap.containsKey(table.names[i])) {
					log.error("dublicate name: "+table.names[i]);
				} else {
					table.nameMap.put(table.names[i], i);
				}
			}

			table.rows = new String[list.size()-1][];

			for(int i=1;i<list.size();i++) {
				table.rows[i-1] = list.get(i);
			}
			
			for(int i=0;i<table.rows.length;i++) {

			}
			reader.close();
			return table;
		} catch(Exception e) {
			log.error(e);
			return null;
		}
	}
	
	public int getColumnIndex(String name) {
		Integer index = nameMap.get(name);
		if(index==null) {
			log.error("name not found in table: "+name);
			return -1;
		}
		return index;
	}
}
