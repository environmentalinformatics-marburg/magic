package processinggraph;

import timeseriesdatabase.GeneralStation;
import timeseriesdatabase.Station;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.VirtualPlot;
import timeseriesdatabase.aggregated.iterator.EmpiricalIterator;
import timeseriesdatabase.aggregated.iterator.ProjectionIterator;
import util.Util;
import util.iterator.TimeSeriesIterator;

public class EmpiricalFiltered extends Continuous.Abstract {

	private final Continuous source; //not null
	private final Continuous compareSource; //not null	
	private final String stationName; //not null
	

	public EmpiricalFiltered(TimeSeriesDatabase timeSeriesDatabase, Continuous source, Continuous compareSource, String stationName) {
		super(timeSeriesDatabase);
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

	/*public static EmpiricalFiltered create(TimeSeriesDatabase timeSeriesDatabase, String stationName, String[] querySchema) {
		Continuous source = QueryPlan.getContinuousGen(timeSeriesDatabase, DataQuality.Na).get(stationName,null);
		GeneralStation generalStation = null;
		VirtualPlot virtualPlot = timeSeriesDatabase.getVirtualPlot(stationName);
		if(virtualPlot!=null) {
			generalStation = virtualPlot.generalStation;
		} else {
			Station station = timeSeriesDatabase.getStation(stationName);
			if(station!=null) {
				generalStation = station.generalStation;
			}
		}
		if(generalStation==null) {
			throw new RuntimeException("station not found: "+stationName);
		}
		String streamName = generalStation.group;
		Continuous compareSource = Continuous.create(timeSeriesDatabase, CacheBase.create(timeSeriesDatabase, streamName , querySchema));
		return new EmpiricalFiltered(timeSeriesDatabase,source,compareSource, stationName);
	}*/
	
	public static Continuous create(TimeSeriesDatabase timeSeriesDatabase, Continuous continuous, String plotID) {
		GeneralStation generalStation = null;
		VirtualPlot virtualPlot = timeSeriesDatabase.getVirtualPlot(plotID);
		if(virtualPlot!=null) {
			generalStation = virtualPlot.generalStation;
		} else {
			Station station = timeSeriesDatabase.getStation(plotID);
			if(station!=null) {
				generalStation = station.generalStation;
			}
		}
		if(generalStation==null) {
			throw new RuntimeException("station not found: "+plotID);
		}
		String streamName = generalStation.group;
		Continuous compareSource = Continuous.create(timeSeriesDatabase, CacheBase.create(timeSeriesDatabase, streamName , continuous.getSchema()));
		return new EmpiricalFiltered(timeSeriesDatabase,continuous,compareSource, plotID);
	}

	@Override
	public TimeSeriesIterator get(Long start, Long end) {		
		if(start==null||end==null) {
			long[] interval = timeSeriesDatabase.getTimestampBaseInterval(stationName);
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
		Float[] maxDiff = timeSeriesDatabase.getEmpiricalDiff(source.getSchema());		
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
