package tsdb.graph;

import java.util.Arrays;

import tsdb.Station;
import tsdb.raw.iterator.CSVIterator;
import tsdb.util.Table;
import tsdb.util.Util;
import tsdb.util.iterator.TimeSeriesIterator;

public class CSVSource implements Node {
	
	private final String[] sensorNames;
	private final String[][] rows;

	protected CSVSource(String[] sensorNames,String[][] rows) {
		this.sensorNames = sensorNames;
		this.rows = rows;
		Util.throwNull((Object)sensorNames);
		Util.throwNull((Object)rows);
	}
	
	public static CSVSource create(String filename) {		
		Table table = Table.readCSV(filename, ',');
		System.out.println("header: "+Util.arrayToString(table.names));
		String[] sensorNames = Arrays.copyOfRange(table.names, 2, table.names.length);
		return new CSVSource(sensorNames, table.rows);
	}

	@Override
	public TimeSeriesIterator get(Long start, Long end) { // TODO start, end		
		return new CSVIterator(sensorNames, rows);
	}

	@Override
	public Station getSourceStation() {
		return null;
	}

	@Override
	public boolean isContinuous() {
		return false;
	}

	@Override
	public boolean isConstantTimestep() {
		return false;
	}

	@Override
	public String[] getSchema() {
		return sensorNames;
	}

}
