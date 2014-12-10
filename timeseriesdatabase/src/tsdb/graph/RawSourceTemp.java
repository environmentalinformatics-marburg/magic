package tsdb.graph;

import static tsdb.util.AssumptionCheck.throwNull;
import tsdb.Station;
import tsdb.TsDB;
import tsdb.VirtualPlot;

public interface RawSourceTemp extends Node {	
	
	public static RawSourceTemp of(TsDB tsdb, String plotID, String[] querySchema) {		
		VirtualPlot virtualPlot = tsdb.getVirtualPlot(plotID);
		if(virtualPlot!=null) {
			return VirtualRawSource.create(tsdb, virtualPlot, querySchema);
		}
		Station station = tsdb.getStation(plotID);
		if(station!=null) {
			return StationRawSource.create(tsdb, station, querySchema);
		}else {
			throw new RuntimeException("plotID / stationID not found: "+plotID);
		}	
		
	}
	
	public abstract class Abstract implements RawSourceTemp {		
		protected TsDB tsdb; // not null		
		Abstract(TsDB tsdb) {
			throwNull(tsdb);
			this.tsdb = tsdb;
		}		
	}

}
