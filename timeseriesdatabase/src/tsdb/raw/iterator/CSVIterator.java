package tsdb.raw.iterator;

import java.util.Arrays;
import java.util.List;

import tsdb.TimeConverter;
import tsdb.raw.TimeSeriesEntry;
import tsdb.util.ProcessingChainEntry;
import tsdb.util.Table;
import tsdb.util.TimeSeriesSchema;
import tsdb.util.TsDBLogger;
import tsdb.util.TsSchema;
import tsdb.util.Util;
import tsdb.util.iterator.TsIterator;

public class CSVIterator extends TsIterator implements TsDBLogger{

	public static TsSchema createSchema(String[] sensorNames) {
		return new TsSchema(sensorNames);
	}

	public static CSVIterator create(String filename) {
		Table table = Table.readCSV(filename, ',');
		System.out.println("header: "+Util.arrayToString(table.names));
		String[] schema = Arrays.copyOfRange(table.names, 2, table.names.length);
		return new CSVIterator(schema,table.rows);
	}

	private String[][] rows;
	private int currIndex;


	public CSVIterator(String[] sensorNames, String[][] rows) {
		super(createSchema(sensorNames));
		this.rows = rows;
		this.currIndex = 0;
	}

	@Override
	public boolean hasNext() {
		return currIndex<rows.length;
	}

	@Override
	public TimeSeriesEntry next() {		
		String[] row = rows[currIndex];
		currIndex++;
		long timestamp = TimeConverter.parseTimestamp(row[0], row[1], true);		
		float[] data = new float[schema.length];
		for(int colIndex=0;colIndex<schema.length;colIndex++) {
			try {
				data[colIndex] = Float.parseFloat(row[colIndex+2]); 
			} catch (Exception e) {
				data[colIndex] = Float.NaN;
				log.warn(e);
			}
		}
		return new TimeSeriesEntry(timestamp,data);
	}
}
