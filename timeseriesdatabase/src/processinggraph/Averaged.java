package processinggraph;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

import timeseriesdatabase.Station;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.aggregated.iterator.AverageIterator;
import util.iterator.TimeSeriesIterator;

public class Averaged extends Node {
	
	private final List<Continuous> sources;
	private final String[] schema;

	public Averaged(TimeSeriesDatabase timeSeriesDatabase, List<Continuous> sources, String[] schema) {
		super(timeSeriesDatabase);
		this.sources = sources;
		this.schema = schema;
	}

	public static Averaged create(TimeSeriesDatabase timeSeriesDatabase, List<Continuous> sources) {		
		Set<String> schemaSet = new LinkedHashSet<String>();		
		for(Continuous continuous:sources) {
			schemaSet.addAll(Arrays.asList(continuous.getSchema()));
		}
		return new Averaged(timeSeriesDatabase, sources, schemaSet.toArray(new String[0]));
	}

	@Override
	public TimeSeriesIterator get(Long start, Long end) {
		return getExactly(start,end);
	}
	
	public TimeSeriesIterator getExactly(long start, long end) {		
		List<TimeSeriesIterator> iteratorList = new ArrayList<>();		
		for(Continuous source:sources) {
			TimeSeriesIterator it = source.get(start, end);
			if(it!=null&&it.hasNext()) {
				iteratorList.add(it);				
			}
		}
		return new AverageIterator(schema,iteratorList.toArray(new TimeSeriesIterator[0]),3);		
	}

	@Override
	public Station getSourceStation() { // multiple source stations
		return null;
	}

	@Override
	public boolean isContinuous() {
		return true;
	}

	@Override
	public String[] getSchema() {
		return schema;
	}

}
