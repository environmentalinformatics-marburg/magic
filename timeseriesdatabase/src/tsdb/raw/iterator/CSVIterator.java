package tsdb.raw.iterator;

import java.util.Arrays;
import java.util.List;

import tsdb.TimeConverter;
import tsdb.raw.TimeSeriesEntry;
import tsdb.util.ProcessingChainEntry;
import tsdb.util.Table;
import tsdb.util.TimeSeriesSchema;
import tsdb.util.TsDBLogger;
import tsdb.util.Util;
import tsdb.util.iterator.TimeSeriesIterator;

public class CSVIterator extends TimeSeriesIterator implements TsDBLogger{

	public static TimeSeriesSchema createSchema(String[] sensorNames) {
		//String[] schema = Arrays.copyOfRange(header, 2, header.length);
		boolean constantTimeStep = false;
		int timeStep = TimeSeriesSchema.NO_CONSTANT_TIMESTEP;
		boolean isContinuous = false;
		boolean hasQualityFlags = false;
		boolean hasInterpolatedFlags = false;
		boolean hasQualityCounters = false;	
		return new TimeSeriesSchema(sensorNames, constantTimeStep, timeStep, isContinuous, hasQualityFlags, hasInterpolatedFlags, hasQualityCounters) ;
	}

	public static CSVIterator create(String filename) {
		Table table = Table.readCSV(filename, ',');
		System.out.println("header: "+Util.arrayToString(table.names));
		String[] schema = Arrays.copyOfRange(table.names, 2, table.names.length);
		return new CSVIterator(schema,table.rows);
	}

	private String[][] rows;
	private int currIndex;

	private final int columns;

	public CSVIterator(String[] sensorNames, String[][] rows) {
		super(createSchema(sensorNames));
		this.rows = rows;
		this.currIndex = 0;
		columns = this.outputTimeSeriesSchema.columns;
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
		float[] data = new float[columns];
		for(int colIndex=0;colIndex<columns;colIndex++) {
			try {
				data[colIndex] = Float.parseFloat(row[colIndex+2]); 
			} catch (Exception e) {
				data[colIndex] = Float.NaN;
				log.warn(e);
			}
		}
		return new TimeSeriesEntry(timestamp,data);
	}

	@Override
	public List<ProcessingChainEntry> getProcessingChain() {
		// TODO Auto-generated method stub
		return null;
	}

}
