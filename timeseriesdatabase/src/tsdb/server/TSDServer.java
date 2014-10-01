package tsdb.server;

import static tsdb.util.AssumptionCheck.throwNull;

import java.rmi.RemoteException;

import tsdb.DataQuality;
import tsdb.GeneralStation;
import tsdb.QueryProcessor;
import tsdb.TsDB;
import tsdb.aggregated.AggregationInterval;
import tsdb.raw.TimestampSeries;
import tsdb.util.iterator.TsIterator;

@Deprecated
public class TSDServer implements TSDServerInterface {
	
	private final TsDB tsdb; //not null
	
	private QueryProcessor qp;
	
	public TSDServer(TsDB tsdb) throws RemoteException {
		throwNull(tsdb);
		this.tsdb = tsdb;
		this.qp = new QueryProcessor(tsdb);
	}
	
	@Override
	public TimestampSeries query(String plotID, String[] querySchema, Long queryStart, Long queryEnd, DataQuality dataQuality, AggregationInterval aggregationInterval, boolean interpolated) {
		TsIterator it = qp.query_aggregated(plotID, querySchema, queryStart, queryEnd, dataQuality, aggregationInterval, interpolated);
		TimestampSeries timestampSeries = TimestampSeries.create(it);
		return timestampSeries;
	}

	@Override
	public String[] queryGeneralStations() {
		return tsdb.getGeneralStationNames();
	}

	@Override
	public String[] queryPlotIds(String generalStationName) {
		GeneralStation generalStation = tsdb.getGeneralStation(generalStationName);
		if(generalStation!=null) {
			String[] names = new String[generalStation.stationList.size()];
			for(int i=0;i<generalStation.stationList.size();i++) {
				names[i] = generalStation.stationList.get(i).stationID;
			}
			return names;
		}
		return null;
	}

}
