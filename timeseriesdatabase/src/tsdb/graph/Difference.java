package tsdb.graph;

import tsdb.GeneralStation;
import tsdb.Station;
import tsdb.TsDB;
import tsdb.VirtualPlot;
import tsdb.aggregated.iterator.DifferenceIterator;
import tsdb.util.Util;
import tsdb.util.iterator.TimeSeriesIterator;

public class Difference extends Continuous.Abstract {
	
	private final Continuous source;
	private final Continuous compareSource;
	private final String stationName;

	protected Difference(TsDB tsdb, Continuous source, Continuous compareSource, String stationName) {
		super(tsdb);
		Util.throwNull(source,compareSource,stationName);
		if(!source.isContinuous()) {
			throw new RuntimeException("QualityChecked needs continuous source");
		}
		if(!compareSource.isContinuous()) {
			throw new RuntimeException("QualityChecked needs continuous compare source");
		}
		if(source.isConstantTimestep()!=compareSource.isConstantTimestep()) {
			throw new RuntimeException("source and compare source are not compatible");
		}
		if(!Util.isContained(source.getSchema(), compareSource.getSchema())) {
			throw new RuntimeException("source and compare source are not compatible");
		}
		this.source = source;
		this.compareSource = compareSource;
		this.stationName = stationName;		
	}
	
	public static Continuous create(TsDB tsdb, Continuous source, Continuous compareSource, String stationName) {
		return new Difference(tsdb, source, compareSource, stationName);		
	}
	
	public static Continuous createFromGroupAverage(TsDB tsdb, Continuous continuous, String plotID) {
		GeneralStation generalStation = null;
		VirtualPlot virtualPlot = tsdb.getVirtualPlot(plotID);
		if(virtualPlot!=null) {
			generalStation = virtualPlot.generalStation;
		} else {
			Station station = tsdb.getStation(plotID);
			if(station!=null) {
				generalStation = station.generalStation;
			}
		}
		if(generalStation==null) {
			throw new RuntimeException("station not found: "+plotID);
		}
		String streamName = generalStation.group;
		Continuous compareSource = Continuous.create(tsdb, CacheBase.create(tsdb, streamName , continuous.getSchema()));
		return create(tsdb,continuous,compareSource, plotID);
	}

	@Override
	public TimeSeriesIterator getExactly(long start, long end) {
		TimeSeriesIterator input_iterator = source.get(start, end);
		if(input_iterator==null||!input_iterator.hasNext()) {
			return null;
		}
		TimeSeriesIterator compare_iterator = compareSource.get(start, end);
		//TimeSeriesIterator compare_iterator = new ProjectionIterator(compareSource.get(start, end),source.getSchema());
		if(compare_iterator==null||!compare_iterator.hasNext()) {
			log.warn("no compare iterator");
			return null;
		}		
		DifferenceIterator difference_iterator = new DifferenceIterator(input_iterator, compare_iterator);
		return difference_iterator;
	}

	@Override
	public TimeSeriesIterator get(Long start, Long end) {
		if(start==null||end==null) {
			long[] interval = tsdb.getBaseTimeInterval(stationName);
			if(interval==null) {
				return null;
			}
			if(start==null) {
				start = interval[0];
			}
			if(end==null) {
				end = interval[1];
			}
		}
		return getExactly(start, end);
	}

	@Override
	public Station getSourceStation() {
		return source.getSourceStation();
	}

	@Override
	public boolean isConstantTimestep() {
		return source.isConstantTimestep();
	}

	@Override
	public String[] getSchema() {
		return source.getSchema();
	}

}
