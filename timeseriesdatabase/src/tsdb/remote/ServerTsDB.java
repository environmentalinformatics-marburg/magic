package tsdb.remote;

import static tsdb.util.AssumptionCheck.throwNull;

import java.rmi.RemoteException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Stream;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import tsdb.DataQuality;
import tsdb.GeneralStation;
import tsdb.LoggerType;
import tsdb.QueryProcessor;
import tsdb.Region;
import tsdb.Sensor;
import tsdb.Station;
import tsdb.TsDB;
import tsdb.VirtualPlot;
import tsdb.aggregated.AggregationInterval;
import tsdb.catalog.SourceEntry;
import tsdb.graph.Node;
import tsdb.graph.QueryPlan;
import tsdb.raw.TimestampSeries;
import tsdb.run.ConsoleStarter;
import tsdb.run.ConsoleRunner;
import tsdb.util.Pair;
import tsdb.util.iterator.TsIterator;

public class ServerTsDB implements RemoteTsDB {
	
	private static final Logger log = LogManager.getLogger();
	
	protected final TsDB tsdb; //not null

	public ServerTsDB(TsDB tsdb) throws RemoteException { // !!
		throwNull(tsdb);
		this.tsdb = tsdb;
	}

	@Override
	public TimestampSeries plot(String queryType, String plotID, String[] columnNames, AggregationInterval aggregationInterval, DataQuality dataQuality, boolean interpolated) {
		Node node = null;
		if(queryType==null||queryType.equals("standard")) {		
			node = QueryPlan.plot(tsdb, plotID, columnNames, aggregationInterval, dataQuality, interpolated);
		} else if(queryType.equals("difference")) {
			node = QueryPlan.plotDifference(tsdb, plotID, columnNames, aggregationInterval, dataQuality, interpolated);
		} else {
			log.error("queryType unknown");
		}
		if(node==null) {
			return null;
		}
		TsIterator it = node.get(null, null);
		if(it==null||!it.hasNext()) {
			return null;
		}
		System.out.println(it.getProcessingChain().getText());
		return it.toTimestampSeries();
	}

	@Override
	public TimestampSeries cache(String streamName, String[] columnNames, AggregationInterval aggregationInterval) {
		Node node =  QueryPlan.cache(tsdb, streamName, columnNames, aggregationInterval);
		if(node==null) {
			return null;
		}
		TsIterator it = node.get(null, null);
		if(it==null||!it.hasNext()) {
			return null;
		}
		return it.toTimestampSeries();		
	}

	@Override
	public Region[] getRegions() {
		return tsdb.getRegions().toArray(new Region[0]);
	}

	@Override
	public GeneralStationInfo[] getGeneralStationInfos(String regionName) {
		return tsdb.getGeneralStations(regionName).map(g->new GeneralStationInfo(g)).toArray(GeneralStationInfo[]::new);
	}

	@Override
	public LoggerType getLoggerType(String loggerTypeName) {
		return tsdb.getLoggerType(loggerTypeName);
	}

	@Override
	public String[] getBaseSchema(String[] rawSchema) {
		return tsdb.getBaseSchema(rawSchema);
	}

	@Override
	public String[] getRegionLongNames() {
		return tsdb.getRegionLongNames().toArray(String[]::new);
	}

	@Override
	public Region getRegionByLongName(String longName) {
		return tsdb.getRegionByLongName(longName);
	}

	@Override
	public String[] getGeneralStationLongNames(String regionName) {
		return tsdb.getGeneralStationLongNames(regionName);
	}

	@Override
	public String[] cacheStorageGetStreamNames() {
		return tsdb.cacheStorage.getStreamNames().toArray(String[]::new);
	}

	@Override
	public String[] getPlotIDsByGeneralStationByLongName(String longName) {		
		GeneralStation generalStation = tsdb.getGeneralStationByLongName(longName);
		if(generalStation==null) {
			return null;
		}
		ArrayList<String> plotIDList = new ArrayList<String>();
		generalStation.stationList.stream().forEach(station->plotIDList.add(station.stationID));
		generalStation.virtualPlots.stream().forEach(virtualPlot->plotIDList.add(virtualPlot.plotID));
		if(plotIDList.isEmpty()) {
			return null;
		}
		return plotIDList.toArray(new String[0]);
	}

	@Override
	public VirtualPlotInfo getVirtualPlotInfo(String plotID) {
		return new VirtualPlotInfo(tsdb.getVirtualPlot(plotID));
	}

	@Override
	public String[] getPlotSchema(String plotID) {
		VirtualPlot virtualPlot = tsdb.getVirtualPlot(plotID);
		if(virtualPlot!=null) {
			return virtualPlot.getSchema();
		}
		Station station = tsdb.getStation(plotID);
		if(station==null) {
			return null;
		}
		return station.loggerType.sensorNames;
	}

	@Override
	public String[] getCacheSchemaNames(String streamName) {
		return tsdb.cacheStorage.getSchema(streamName).names;
	}

	@Override
	public Sensor getSensor(String sensorName) {
		return tsdb.getSensor(sensorName);
	}

	@Override
	public Sensor[] getSensors() {
		return tsdb.getSensors().toArray(new Sensor[0]);
	}

	@Override
	public VirtualPlotInfo[] getVirtualPlots() {
		return tsdb.getVirtualPlots().stream().map(v->new VirtualPlotInfo(v)).toArray(VirtualPlotInfo[]::new);
	}

	@Override
	public StationInfo[] getStationInfos() {
		return tsdb.getStations().stream().map(s->new StationInfo(s)).toArray(StationInfo[]::new);
	}

	@Override
	public GeneralStationInfo[] getGeneralStations() {
		return tsdb.getGeneralStations().stream().map(g->new GeneralStationInfo(g)).toArray(GeneralStationInfo[]::new);
	}

	@Override
	public LoggerType[] getLoggerTypes() {
		return tsdb.getLoggerTypes().toArray(new LoggerType[0]);
	}

	@Override
	public SourceEntry[] getSourceCatalogEntries() {
		return tsdb.sourceCatalog.getEntries().toArray(new SourceEntry[0]);
	}

	@Override
	public String[] getStationNames() {
		return tsdb.getStationNames().toArray(new String[0]);
	}

	@Override
	public TsIterator query_raw(String plotID, String[] querySchema, Long queryStart, Long queryEnd) {
		QueryProcessor qp = new QueryProcessor(tsdb);
		return qp.query_raw(plotID, querySchema, queryStart, queryEnd);
	}

	@Override
	public String[] getGeneralStationSensorNames(String generalStationName) {
		GeneralStation generalStation = tsdb.getGeneralStation(generalStationName);
		if(generalStation==null) {
			return null;
		}

		Set<LoggerType> loggerTypes = new HashSet<LoggerType>();

		generalStation.stationList.forEach(station->loggerTypes.add(station.loggerType));

		generalStation.virtualPlots.stream()
		.flatMap(virtualPlot->virtualPlot.intervalList.stream())
		.map(i->tsdb.getLoggerType(i.value.get_logger_type_name()))
		.forEach(lt->loggerTypes.add(lt));

		Set<String> sensorNames = new TreeSet<String>();

		loggerTypes.stream()
		.map(lt->tsdb.getBaseSchema(lt.sensorNames))
		.forEach(s->{ for(String n:s){sensorNames.add(n);}});

		if(sensorNames.isEmpty()) {
			return null;
		}

		return sensorNames.toArray(new String[0]);		
	}

	@Override
	public PlotInfo[] getPlotInfos() {
		return Stream.concat(
				tsdb.getStations().stream().filter(s->s.isPlot).map(s->new PlotInfo(s)), 
				tsdb.getVirtualPlots().stream().map(v->new PlotInfo(v))
				).toArray(PlotInfo[]::new);
	}

	@Override
	public String[] getValidSchema(String plotID, String[] sensorNames) {
		return tsdb.getValidSchema(plotID, sensorNames);
	}
	
	Long command_counter=0l;
	
	Map<Long,Pair<Thread,ConsoleRunner>> commandThreadMap = new ConcurrentHashMap<Long,Pair<Thread,ConsoleRunner>>();
	
	private long createCommandThreadId() {
		synchronized (command_counter) {
			final long commandThreadId = command_counter;
			command_counter++;
			return commandThreadId;
		}
	}

	@Override
	public long execute_console_command(String input_line) throws RemoteException {
		final long commandThreadId = createCommandThreadId();
		ConsoleRunner consolerunner = new ConsoleRunner(tsdb, input_line);
		Thread commandThread = new Thread(consolerunner);		
		commandThread.start();
		System.out.println("execute_console_command: "+input_line+"     "+command_counter);
		commandThreadMap.put(commandThreadId, new Pair<Thread,ConsoleRunner>(commandThread,consolerunner));
		return commandThreadId;
	}

	@Override
	public Pair<Boolean,String[]> console_comand_get_output(long commandThreadId) throws RemoteException {
		Pair<Thread,ConsoleRunner> pair = commandThreadMap.get(commandThreadId);
		if(pair==null) {
			return null;
		}
		System.out.println("console_comand_get_output: "+commandThreadId);
		Thread commandThread = pair.a;
		ConsoleRunner consolerunner = pair.b;
		boolean running = commandThread.isAlive(); //first
		String[] output_lines = consolerunner.getOutputLines();  //and then
		if(!running) {
			commandThreadMap.remove(commandThreadId);
		}

		return new Pair<Boolean,String[]>(running,output_lines);
	}
}
