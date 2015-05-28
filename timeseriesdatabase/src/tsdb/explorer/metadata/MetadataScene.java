package tsdb.explorer.metadata;

import static tsdb.util.AssumptionCheck.throwNull;
import javafx.scene.Parent;
import javafx.scene.control.Tab;
import javafx.scene.control.TabPane;
import javafx.scene.control.TabPane.TabClosingPolicy;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import tsdb.explorer.TsdbScene;
import tsdb.remote.RemoteTsDB;

/**
 * Central window for all types of metadata
 * @author woellauer
 *
 */
public class MetadataScene extends TsdbScene {
	@SuppressWarnings("unused")
	private static final Logger log = LogManager.getLogger();	
	private final RemoteTsDB tsdb;
	
	private VirtualPlotView virtualPlotView;
	private StationView stationView;
	private LoggerView loggerView;
	private SensorView sensorView;
	private GeneralStationView generalStationView;
	private RegionView regionView;	

	public MetadataScene(RemoteTsDB tsdb) {
		super("time series databaes metadata view");		
		throwNull(tsdb);
		this.tsdb = tsdb;
	}

	@Override
	protected Parent createContent() {
		TabPane tabPane = new TabPane();
		tabPane.setTabClosingPolicy(TabClosingPolicy.UNAVAILABLE);

		Tab tabVirtualPlot = new Tab("Virtual Plot");
		virtualPlotView = new VirtualPlotView();
		tabVirtualPlot.setContent(virtualPlotView.getNode());
		tabPane.getTabs().add(tabVirtualPlot);

		Tab tabStation = new Tab("Station");
		stationView = new StationView();
		tabStation.setContent(stationView.getNode());
		tabPane.getTabs().add(tabStation);

		Tab tabLogger = new Tab("Logger");
		loggerView = new LoggerView();
		tabLogger.setContent(loggerView.getNode());
		tabPane.getTabs().add(tabLogger);

		Tab tabSensor = new Tab("Sensor");
		sensorView = new SensorView();
		tabSensor.setContent(sensorView.getNode());
		tabPane.getTabs().add(tabSensor);

		Tab tabGeneralStation = new Tab("General Station");
		generalStationView = new GeneralStationView();
		tabGeneralStation.setContent(generalStationView.getNode());
		tabPane.getTabs().add(tabGeneralStation);
		
		Tab tabRegion = new Tab("Region");
		regionView = new RegionView();
		tabRegion.setContent(regionView.getNode());
		tabPane.getTabs().add(tabRegion);

		return tabPane;
	}	

	@Override
	protected void onShown() {
		sensorView.collectData(tsdb);
		stationView.collectData(tsdb);
		loggerView.collectData(tsdb);
		virtualPlotView.collectData(tsdb);
		generalStationView.collectData(tsdb);
		regionView.collectData(tsdb);
	}
}