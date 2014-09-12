package tsdb.server;

import java.rmi.Remote;
import java.rmi.RemoteException;

import tsdb.DataQuality;
import tsdb.aggregated.AggregationInterval;
import tsdb.raw.TimestampSeries;

@Deprecated
public interface TSDServerInterface extends Remote {

	TimestampSeries query(String plotID, String[] querySchema, Long queryStart, Long queryEnd, DataQuality dataQuality, AggregationInterval aggregationInterval, boolean interpolated) throws RemoteException;
	String[] queryGeneralStations() throws RemoteException;
	String[] queryPlotIds(String generalStationName) throws RemoteException;
	
}
