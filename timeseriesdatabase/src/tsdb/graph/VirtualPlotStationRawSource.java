package tsdb.graph;

import static tsdb.util.AssumptionCheck.throwNulls;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import tsdb.Station;
import tsdb.StationProperties;
import tsdb.TsDB;
import tsdb.VirtualPlot;
import tsdb.util.TimestampInterval;
import tsdb.util.Util;
import tsdb.util.iterator.TsIterator;

public class VirtualPlotStationRawSource extends RawSource.Abstract {
	private static final Logger log = LogManager.getLogger();

	private final VirtualPlot virtualPlot; // not null
	private final Station station; // not null
	private final String[] sensorNames; //not null, schema valid

	VirtualPlotStationRawSource(TsDB tsdb, VirtualPlot virtualPlot, Station station, String[] sensorNames) {
		super(tsdb);
		throwNulls(virtualPlot, station,sensorNames);
		this.virtualPlot = virtualPlot;
		this.station = station;
		this.sensorNames = sensorNames;
		if(this.sensorNames.length==0) {
			throw new RuntimeException("no schema");
		}
		if(!station.isValidSchema(sensorNames)) {
			throw new RuntimeException("not valid schema: "+Util.arrayToString(sensorNames)+" in "+Util.arrayToString(station.getSchema())); 
		}
	}

	public static VirtualPlotStationRawSource of(TsDB tsdb, String plotID, String stationID, String[] querySchema) {
		VirtualPlot virtualPlot = tsdb.getVirtualPlot(plotID);
		if(virtualPlot==null) {
			throw new RuntimeException("virtual plot not found: "+plotID);
		}
		return of(tsdb,virtualPlot,stationID,querySchema);
	}

	public static VirtualPlotStationRawSource of(TsDB tsdb, VirtualPlot virtualPlot, String stationID, String[] querySchema) {
		Station station = tsdb.getStation(stationID);
		if(station==null) {
			throw new RuntimeException("station not found: "+stationID);
		}
		return of(tsdb,virtualPlot,station,querySchema);
	}


	public static VirtualPlotStationRawSource of(TsDB tsdb, VirtualPlot virtualPlot, Station station, String[] querySchema) {	
		if(querySchema==null) {
			querySchema = station.getSchema();
		}
		return new VirtualPlotStationRawSource(tsdb, virtualPlot, station, querySchema);
	}

	@Override
	public TsIterator get(Long start, Long end) {
		TimestampInterval<StationProperties> interval = null;
		for(TimestampInterval<StationProperties> i:virtualPlot.intervalList) {
			if(station.stationID.equals(i.value.get_serial())) {
				if(interval==null) {
					interval = i.filterByInterval(start, end);
				} else {
					new RuntimeException("multiple intervals for virtualPlot at station not supported: "+virtualPlot+"  "+station);
				}
			}
		}

		if(interval==null) {
			return null;
		}

		log.info("add interval "+interval);

		TsIterator it = tsdb.streamStorage.getRawIterator(station.stationID, sensorNames, interval.start, interval.end);

		if(it==null||!it.hasNext()) {		
			return null;
		}
		return it;
	}

	@Override
	public Station getSourceStation() {
		return station;
	}

	@Override
	public boolean isContinuous() {
		return false;
	}

	@Override
	public boolean isConstantTimestep() {
		return false;
	}

	@Override
	public String[] getSchema() {
		return sensorNames;
	}

}
