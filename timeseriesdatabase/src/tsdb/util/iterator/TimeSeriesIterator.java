package tsdb.util.iterator;

import java.util.List;

import tsdb.aggregated.TimeSeries;
import tsdb.raw.TimeSeriesEntry;
import tsdb.raw.TimestampSeries;
import tsdb.util.CSV;
import tsdb.util.ProcessingChainEntry;
import tsdb.util.TimeSeriesSchema;

public abstract class TimeSeriesIterator extends SchemaIterator<TimeSeriesEntry> {

	public TimeSeriesIterator(TimeSeriesSchema outputTimeSeriesSchema) {
		super(outputTimeSeriesSchema);
	}

	public String getIteratorName() {
		return this.getClass().getName();
	}

	
	@Override
	public String toString() {
		
		List<ProcessingChainEntry> list = getProcessingChain();
		boolean first=true;
		String chain="";
		for(ProcessingChainEntry entry:list) {
			if(first) {				
				first=false;
			} else {
				chain+=" -> ";
			}
			chain += entry.getProcessingTitle();
		}
		
		return getIteratorName()+" "+outputTimeSeriesSchema.toString()+" "+chain;
	}
	
	@Override
	public String getProcessingTitle() {
		return getIteratorName();
	}
	
	public void writeCSV(String filename) {
		CSV.write(this,filename);
	}
	
	public void writeConsole() {
		while(this.hasNext()) {
			TimeSeriesEntry e = this.next();
			System.out.println(e);
		}		
	}
	
	public TimeSeries toTimeSeries() {
		return TimeSeries.create(this);
	}
	
	public TimestampSeries toTimestampSeries() {
		return TimestampSeries.create(this);
	}
}