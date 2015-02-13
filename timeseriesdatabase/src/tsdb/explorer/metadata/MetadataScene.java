package tsdb.explorer.metadata;

import static tsdb.util.AssumptionCheck.throwNull;

import java.rmi.RemoteException;
import java.util.ArrayList;
import java.util.Map.Entry;
import java.util.function.Function;

import javafx.beans.binding.Bindings;
import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.collections.ObservableMap;
import javafx.collections.transformation.FilteredList;
import javafx.event.ActionEvent;
import javafx.scene.Node;
import javafx.scene.Parent;
import javafx.scene.control.CheckBox;
import javafx.scene.control.Hyperlink;
import javafx.scene.control.Label;
import javafx.scene.control.ListCell;
import javafx.scene.control.Tab;
import javafx.scene.control.TabPane;
import javafx.scene.control.TabPane.TabClosingPolicy;
import javafx.scene.control.TableCell;
import javafx.scene.control.TableColumn;
import javafx.scene.control.TableView;
import javafx.scene.layout.BorderPane;
import javafx.scene.layout.GridPane;
import javafx.scene.layout.HBox;
import javafx.scene.layout.VBox;
import javafx.util.Callback;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import com.sun.javafx.binding.ObjectConstant;
import com.sun.javafx.binding.StringConstant;
import com.sun.javafx.scene.control.behavior.TabPaneBehavior;

import tsdb.LoggerType;
import tsdb.Region;
import tsdb.Sensor;
import tsdb.StationProperties;
import tsdb.TimeConverter;
import tsdb.explorer.TsdbScene;
import tsdb.remote.GeneralStationInfo;
import tsdb.remote.RemoteTsDB;
import tsdb.remote.StationInfo;
import tsdb.remote.VirtualPlotInfo;
import tsdb.util.TimestampInterval;

public class MetadataScene extends TsdbScene {
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