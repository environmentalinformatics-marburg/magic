package tsdb.remote;

import java.rmi.Remote;
import java.rmi.RemoteException;

import tsdb.DataQuality;
import tsdb.LoggerType;
import tsdb.Region;
import tsdb.Sensor;
import tsdb.aggregated.AggregationInterval;
import tsdb.catalog.SourceEntry;
import tsdb.raw.TimestampSeries;
import tsdb.util.iterator.TimeSeriesIterator;

public interface RemoteTsDB extends Remote {
	
	//ok
	TimestampSeries plot(String plotID, String columnName, AggregationInterval aggregationInterval, DataQuality dataQuality, boolean interpolated) throws RemoteException;

	//ok
	TimestampSeries cache(String streamName, String columnName, AggregationInterval aggregationInterval) throws RemoteException;

	//ok
	Region[] getRegions() throws RemoteException;

	GeneralStationInfo[] getGeneralStationInfos(String regionName) throws RemoteException;

	LoggerType getLoggerType(String loggerTypeName) throws RemoteException;

	String[] getBaseSchema(String[] rawSchema) throws RemoteException;

	String[] getRegionLongNames() throws RemoteException;

	Region getRegionByLongName(String longName) throws RemoteException;

	String[] getGeneralStationLongNames(String regionName) throws RemoteException;

	String[] cacheStorageGetStreamNames() throws RemoteException;

	String[] getPlotIDsByGeneralStationByLongName(String longName) throws RemoteException;

	VirtualPlotInfo getVirtualPlotInfo(String plotID) throws RemoteException;

	String[] getCacheSchemaNames(String streamName) throws RemoteException;

	Sensor getSensor(String sensorName) throws RemoteException;

	Sensor[] getSensors() throws RemoteException;
	
	StationInfo[] getStationInfos() throws RemoteException;

	VirtualPlotInfo[] getVirtualPlots() throws RemoteException;

	GeneralStationInfo[] getGeneralStations() throws RemoteException;

	LoggerType[] getLoggerTypes() throws RemoteException;

	SourceEntry[] getSourceCatalogEntries() throws RemoteException;

	String[] getStationNames() throws RemoteException;

	TimeSeriesIterator query_raw(String plotID, String[] querySchema, Long queryStart, Long queryEnd) throws RemoteException;

	String[] getPlotSchema(String stationName) throws RemoteException;

	//ok
	String[] getGeneralStationSensorNames(String generalStationName) throws RemoteException;	
}
