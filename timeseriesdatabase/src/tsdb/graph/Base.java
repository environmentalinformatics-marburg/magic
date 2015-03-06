package tsdb.graph;

import static tsdb.util.AssumptionCheck.throwNull;
import tsdb.Station;
import tsdb.TsDB;
import tsdb.VirtualPlot;

/**
 * This node provides base aggregated data.
 * @author woellauer
 *
 */
public interface Base extends Node {
	
	@Override
	public default boolean isConstantTimestep() {
		return true;
	}
	
	public static Base of(TsDB tsdb, String plotID, String[] querySchema, NodeGen stationGen) {
		VirtualPlot virtualPlot = tsdb.getVirtualPlot(plotID);
		if(virtualPlot!=null) {
			return VirtualBase.of(tsdb, virtualPlot, querySchema, stationGen);
		}
		Station station = tsdb.getStation(plotID);
		if(station!=null) {
			return StationBase.of(tsdb, station, querySchema, stationGen);
		}else {
			throw new RuntimeException("plotID / stationID not found: "+plotID);
		}	
	}
	
	public abstract class Abstract implements Base {		
		protected TsDB tsdb; // not null		
		Abstract(TsDB tsdb) {
			throwNull(tsdb);
			this.tsdb = tsdb;
		}
		
		@Override
		public final boolean isConstantTimestep() {
			return true;
		}
		
		@Override
		public boolean isContinuous() {
			return false;
		}
	}
}
