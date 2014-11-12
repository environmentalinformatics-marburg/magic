package tsdb.graph;

import static tsdb.util.AssumptionCheck.throwNull;
import static tsdb.util.AssumptionCheck.throwNullText;
import tsdb.GeneralStation;
import tsdb.Station;
import tsdb.TsDB;
import tsdb.VirtualPlot;
import tsdb.util.iterator.TsIterator;

public class GroupAverageSource implements Continuous {
	
	private final Continuous source;
	
	public GroupAverageSource(Continuous source) {
		throwNull(source);
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
		throwNullText(generalStation,"station not found: "+plotID);
		return createFromGroup(tsdb, generalStation.group, schema);		
	}
	
	public static GroupAverageSource createFromGroup(TsDB tsdb, String group, String[] schema) {
		CacheBase cacheBase = CacheBase.create(tsdb, group, schema);
		if(cacheBase==null) {
			return null;
		}
		Continuous source = Continuous.create(cacheBase);		
		return new GroupAverageSource(source);
	}

	@Override
	public TsIterator get(Long start, Long end) {
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
	public TsIterator getExactly(long start, long end) {
		return source.getExactly(start, end);
	}

}
