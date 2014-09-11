package tsdb.server;

import java.rmi.RemoteException;

import tsdb.DataQuality;
import tsdb.GeneralStation;
import tsdb.QueryProcessor;
import tsdb.TsDB;
import tsdb.TsDBClient;
import tsdb.aggregated.AggregationInterval;
import tsdb.raw.TimestampSeries;
import tsdb.util.iterator.TsIterator;

public class TSDServer extends TsDBClient implements TSDServerInterface {
	
	private QueryProcessor qp;
	
	public TSDServer(TsDB tsdb) throws RemoteException {
		super(tsdb);
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
