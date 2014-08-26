package tsdb.graph;

import tsdb.GeneralStation;
import tsdb.Station;
import tsdb.TsDB;
import tsdb.VirtualPlot;
import tsdb.aggregated.iterator.EmpiricalIterator;
import tsdb.aggregated.iterator.ProjectionIterator;
import tsdb.util.Util;
import tsdb.util.iterator.TimeSeriesIterator;

public class EmpiricalFiltered extends Continuous.Abstract {

	private final Continuous source; //not null
	private final Continuous compareSource; //not null	
	private final String stationName; //not null
	

	public EmpiricalFiltered(TsDB tsdb, Continuous source, Continuous compareSource, String stationName) {
		super(tsdb);
		Util.throwNull(source,compareSource,stationName);
		if(!source.isContinuous()) {
			throw new RuntimeException("QualityChecked needs continuous source");
		}
		if(!compareSource.isContinuous()) {
			throw new RuntimeException("QualityChecked needs continuous compare source");
		}
		this.source = source;
		this.compareSource = compareSource;
		this.stationName = stationName;
	}

	public static Continuous create(TsDB tsdb, Continuous continuous, String plotID) {
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
		return new EmpiricalFiltered(tsdb,continuous,compareSource, plotID);
	}

	@Override
	public TimeSeriesIterator get(Long start, Long end) {		
		if(start==null||end==null) {
			long[] interval = tsdb.getTimestampBaseInterval(stationName);
			if(start==null) {
				start = interval[0];
			}
			if(end==null) {
				end = interval[1];
			}
		}
		TimeSeriesIterator input_iterator = source.get(start, end);
		if(input_iterator==null||!input_iterator.hasNext()) {
			return null;
		}
		TimeSeriesIterator compare_iterator = new ProjectionIterator(compareSource.get(start, end),source.getSchema());
		if(compare_iterator==null||!compare_iterator.hasNext()) {
			log.warn("no compare iterator");
			return input_iterator;
		}		
		Float[] maxDiff = tsdb.getEmpiricalDiff(source.getSchema());		
		EmpiricalIterator empirical_iterator = new EmpiricalIterator(input_iterator, compare_iterator, maxDiff);
		return empirical_iterator;
	}

	@Override
	public Station getSourceStation() {
		return source.getSourceStation();
	}

	@Override
	public String[] getSchema() {
		return source.getSchema();
	}

	@Override
	public TimeSeriesIterator getExactly(long start, long end) {
		return get(start,end);
	}
	
	@Override
	public boolean isContinuous() {
		return source.isContinuous();
	}

	@Override
	public boolean isConstantTimestep() {
		return source.isContinuous();
	}
}
