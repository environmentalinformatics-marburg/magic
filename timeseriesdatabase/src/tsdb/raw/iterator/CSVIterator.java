package tsdb.raw.iterator;

import java.nio.file.Path;
import java.util.Arrays;

import tsdb.TimeConverter;
import tsdb.raw.TimeSeriesEntry;
import tsdb.util.Table;
import tsdb.util.TsDBLogger;
import tsdb.util.TsSchema;
import tsdb.util.iterator.TsIterator;

public class CSVIterator extends TsIterator implements TsDBLogger{

	public static TsSchema createSchema(String[] sensorNames) {
		return new TsSchema(sensorNames);
	}
	
	public static CSVIterator create(Path path) {
		return create(path.toString());
	}

	public static CSVIterator create(String filename) {
		Table table = Table.readCSV(filename, ',');
		String[] schema = Arrays.copyOfRange(table.names, 2, table.names.length);
		return new CSVIterator(schema,table.rows,filename);
	}

	private final String filename;//for debug
	private String[][] rows;
	private int currIndex;


	public CSVIterator(String[] sensorNames, String[][] rows, String filename) {
		super(createSchema(sensorNames));
		this.filename = filename;
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
				log.warn(e+ "   csv line "+(currIndex+1)+"  in "+filename);
			}
		}
		return new TimeSeriesEntry(timestamp,data);
	}
}