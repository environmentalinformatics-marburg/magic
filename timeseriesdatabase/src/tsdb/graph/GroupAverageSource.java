package tsdb.graph;

import tsdb.GeneralStation;
import tsdb.Station;
import tsdb.TsDB;
import tsdb.VirtualPlot;
import tsdb.util.Util;
import tsdb.util.iterator.TimeSeriesIterator;

public class GroupAverageSource implements Continuous {
	
	private final Continuous source;
	
	public GroupAverageSource(Continuous source) {
		Util.throwNull(source);
		this.source = source;
	}
	
	public static GroupAverageSource createFromPlot(TsDB tsdb, String plotID, String[] schema) {	
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
		Util.throwNullText(generalStation,"station not found: "+plotID);
		return createFromGroup(tsdb, generalStation.group, schema);		
	}
	
	public static GroupAverageSource createFromGroup(TsDB tsdb, String group, String[] schema) {
		Continuous source = Continuous.create(CacheBase.create(tsdb, group, schema));		
		return new GroupAverageSource(source);
	}

	@Override
	public TimeSeriesIterator get(Long start, Long end) {
		return source.get(start, end);
	}

	@Override
	public Station getSourceStation() {
		return null;
	}


	@Override
	public boolean isConstantTimestep() {
		return true;
	}

	@Override
	public String[] getSchema() {
		return source.getSchema();
	}

	@Override
	public TimeSeriesIterator getExactly(long start, long end) {
		return source.getExactly(start, end);
	}

}
