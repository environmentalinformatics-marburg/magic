package tsdb.explorer;

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
import tsdb.remote.GeneralStationInfo;
import tsdb.remote.RemoteTsDB;
import tsdb.remote.StationInfo;
import tsdb.remote.VirtualPlotInfo;
import tsdb.util.TimestampInterval;

public class MetadataScene extends TsdbScene {
	private static final Logger log = LogManager.getLogger();	
	private final RemoteTsDB tsdb;

	TableView<Sensor> tableSensor;
	private CheckBox checkBoxShowRawSensors;
	private FilteredList<Sensor> filteredSensorList;
	private TableView<StationInfo> tableStation;
	private FilteredList<StationInfo> filteredStationList;
	private CheckBox checkBoxShowPlotStationsOnly;
	private TableView<LoggerType> tableLogger;
	private TableView<VirtualPlotInfo> tableVirtualPlot;
	private TableView<GeneralStationInfo> tableGeneralStation;
	private TableView<Region> tableRegion;

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
		tabVirtualPlot.setContent(createVirtualPlotView());
		tabPane.getTabs().add(tabVirtualPlot);

		Tab tabStation = new Tab("Station");
		tabStation.setContent(createStationView());
		tabPane.getTabs().add(tabStation);

		Tab tabLogger = new Tab("Logger");
		tabLogger.setContent(createLoggerView());
		tabPane.getTabs().add(tabLogger);

		Tab tabSensor = new Tab("Sensor");
		tabSensor.setContent(createSensorView());
		tabPane.getTabs().add(tabSensor);

		Tab tabGeneralStation = new Tab("General Station");
		tabGeneralStation.setContent(createGeneralStationView());
		tabPane.getTabs().add(tabGeneralStation);
		
		Tab tabRegion = new Tab("Region");
		tabRegion.setContent(createRegionView());
		tabPane.getTabs().add(tabRegion);


		return tabPane;
	}


	private static class DetailEntry {		
		private final String title;
		private final ContentMapper contentMapper;

		public interface ContentMapper {
			public String map(Sensor sensor);
		}

		public DetailEntry(String title, ContentMapper contentMapper) {
			this.title = title;
			this.contentMapper = contentMapper;
		}
	}

	private Node createSensorView() {
		BorderPane borderPane = new BorderPane();

		tableSensor = new TableView<Sensor>();

		TableColumn<Sensor,String> colName = new TableColumn<Sensor,String>("name");
		colName.setCellValueFactory(cdf->StringConstant.valueOf(cdf.getValue().name));


		tableSensor.getColumns().setAll(colName);


		borderPane.setLeft(tableSensor);



		GridPane detailPane = new GridPane();
		detailPane.setStyle("-fx-border-style:solid;-fx-border-color: transparent;-fx-border-width: 20;");
		//detailPane.setb
		detailPane.setHgap(10);
		detailPane.setVgap(10);


		ArrayList<DetailEntry> detailEntryList = new ArrayList<DetailEntry>();

		detailEntryList.add(new DetailEntry("Sensor",s->s.name));
		detailEntryList.add(new DetailEntry("Description",s->s.description));
		detailEntryList.add(new DetailEntry("Unit",s->s.unitDescription));
		detailEntryList.add(new DetailEntry("Visualisation Category",s->s.category.toString()));

		detailEntryList.add(new DetailEntry("Physical Range",s->{
			String min;
			if(s.physicalMin!=-Float.MAX_VALUE) {
				min = Float.toString(s.physicalMin);
			} else {
				min = "...";
			}
			String max;
			if(s.physicalMax!=Float.MAX_VALUE) {
				max = Float.toString(s.physicalMax);
			} else {
				max = "...";
			}
			return min+" - "+max;
		}));

		detailEntryList.add(new DetailEntry("Step Range",s->{
			String max;
			if(s.stepMax!=Float.MAX_VALUE) {
				max = Float.toString(s.physicalMax);
			} else {
				max = "...";
			}
			return s.stepMin+" - "+max;
		}));

		detailEntryList.add(new DetailEntry("Max Empirical Diff",s->{
			if(s.empiricalDiff!=null) {
				return Float.toString(s.empiricalDiff);
			} else {
				return null;
			}
		}));

		detailEntryList.add(new DetailEntry("Aggregation",s->s.baseAggregationType.toString()));
		detailEntryList.add(new DetailEntry("Interpolation",s->s.useInterpolation?"yes":"no"));


		int columnCounter = 0;
		for(DetailEntry detailEntry:detailEntryList) {
			Label lblTitle = new Label(detailEntry.title);
			Label lblContent = new Label();
			tableSensor.getSelectionModel().selectedItemProperty().addListener((s,o,sensor)->{
				if(sensor!=null) {
					lblContent.setText(detailEntry.contentMapper.map(sensor));
				} else {
					lblContent.setText(null);
				}
			});
			detailPane.add(lblTitle, 0, columnCounter);
			detailPane.add(lblContent, 1, columnCounter);
			columnCounter++;
		}


		borderPane.setCenter(detailPane);

		checkBoxShowRawSensors = new CheckBox("show raw sensors");
		checkBoxShowRawSensors.setOnAction(this::updateSensorPredicate);
		borderPane.setBottom(checkBoxShowRawSensors);


		return borderPane;

	}

	private Node createStationView() {
		BorderPane borderPane = new BorderPane();

		tableStation = new TableView<StationInfo>();

		TableColumn<StationInfo,String> colName = new TableColumn<StationInfo,String>("name");
		colName.setCellValueFactory(cdf->StringConstant.valueOf(cdf.getValue().stationID));

		tableStation.getColumns().addAll(colName);

		borderPane.setLeft(tableStation);

		checkBoxShowPlotStationsOnly = new CheckBox("show stations that are plots only");
		checkBoxShowPlotStationsOnly.setOnAction(this::updateStationPredicate);
		borderPane.setBottom(checkBoxShowPlotStationsOnly);

		GridPane detailPane = new GridPane();
		detailPane.setStyle("-fx-border-style:solid;-fx-border-color: transparent;-fx-border-width: 20;");
		detailPane.setHgap(10);
		detailPane.setVgap(10);

		Label lblStation = new Label();
		detailPane.add(new Label("Station"), 0, 0);
		detailPane.add(lblStation, 1, 0);

		Label lblLogger = new Label();
		detailPane.add(new Label("Logger"), 0, 1);
		detailPane.add(lblLogger, 1, 1);

		Label lblGeneralStation = new Label();
		detailPane.add(new Label("General Station"), 0, 2);
		detailPane.add(lblGeneralStation, 1, 2);

		Label lblLocation = new Label();
		detailPane.add(new Label("Location"), 0, 3);
		detailPane.add(lblLocation, 1, 3);

		Label lblSecondary = new Label();
		detailPane.add(new Label("Secondary ID"), 0, 4);
		detailPane.add(lblSecondary, 1, 4);

		tableStation.getSelectionModel().selectedItemProperty().addListener((s,o,station)->{
			if(station!=null) {
				lblStation.setText(station.stationID);
				lblLogger.setText(station.loggerType.typeName);
				lblGeneralStation.setText(station.generalStationInfo==null?null:station.generalStationInfo.name);				
				String loc;
				if(Double.isNaN(station.geoPosLatitude)&&Double.isNaN(station.geoPosLatitude)) {
					loc = null;
				} else {
					loc = station.geoPosLatitude+"  ,  "+station.geoPoslongitude;
				}
				lblLocation.setText(loc);
				lblSecondary.setText(station.alternativeID);

			}
		});

		borderPane.setCenter(detailPane);

		return borderPane;
	}


	private static class TimestampTableCell extends TableCell<TimestampInterval<StationProperties>, Long> {
		@Override
		protected void updateItem(Long item, boolean empty) {
			super.updateItem(item, empty);
			if(empty) {
				super.setText(null);
			} else if (item == null) {
				super.setText("*");
			} else {
				super.setText(TimeConverter.oleMinutesToText(item));
			}
		}			
	}

	private Node createVirtualPlotView() {
		BorderPane borderPane = new BorderPane();

		tableVirtualPlot = new TableView<VirtualPlotInfo>();
		borderPane.setLeft(tableVirtualPlot);

		TableColumn<VirtualPlotInfo,String> colName = new TableColumn<VirtualPlotInfo,String>("name");
		colName.setCellValueFactory(cdf->StringConstant.valueOf(cdf.getValue().plotID));
		tableVirtualPlot.getColumns().addAll(colName);

		GridPane detailPane = new GridPane();
		borderPane.setCenter(detailPane);
		detailPane.setStyle("-fx-border-style:solid;-fx-border-color: transparent;-fx-border-width: 20;");
		detailPane.setHgap(10);
		detailPane.setVgap(10);

		Label lblVirtualPlot = new Label();
		detailPane.add(new Label("Virtual Plot"), 0, 0);
		detailPane.add(lblVirtualPlot, 1, 0);

		Label lblGeneralStation = new Label();
		detailPane.add(new Label("General Station"), 0, 1);
		detailPane.add(lblGeneralStation, 1, 1);

		Label lblLocation = new Label();
		detailPane.add(new Label("Location"), 0, 2);
		detailPane.add(lblLocation, 1, 2);

		Label lblElevation = new Label();
		detailPane.add(new Label("Elevation"), 0, 3);
		detailPane.add(lblElevation, 1, 3);

		Label lblElevationTemperature = new Label();
		detailPane.add(new Label("Elevation Temp. Ref."), 0, 4);
		detailPane.add(lblElevationTemperature, 1, 4);


		TableView<TimestampInterval<StationProperties>> tableInterval = new TableView<TimestampInterval<StationProperties>>();
		TableColumn<TimestampInterval<StationProperties>,Long> colIntervalStart = new TableColumn<TimestampInterval<StationProperties>,Long>("Start");
		colIntervalStart.setCellValueFactory(cdf->ObjectConstant.<Long>valueOf(cdf.getValue().start));
		colIntervalStart.setMinWidth(150);
		colIntervalStart.setCellFactory(p->new TimestampTableCell());
		TableColumn<TimestampInterval<StationProperties>,Long> colIntervalEnd = new TableColumn<TimestampInterval<StationProperties>,Long>("End");
		colIntervalEnd.setCellValueFactory(cdf->ObjectConstant.<Long>valueOf(cdf.getValue().end));
		colIntervalEnd.setMinWidth(150);
		colIntervalEnd.setCellFactory(p->new TimestampTableCell());
		TableColumn<TimestampInterval<StationProperties>,String> colIntervalStation = new TableColumn<TimestampInterval<StationProperties>,String>("Station");
		colIntervalStation.setCellValueFactory(cdf->StringConstant.valueOf(cdf.getValue().value.get_serial()));		
		TableColumn<TimestampInterval<StationProperties>,String> colIntervalLogger = new TableColumn<TimestampInterval<StationProperties>,String>("Logger");
		colIntervalLogger.setCellValueFactory(cdf->StringConstant.valueOf(cdf.getValue().value.get_logger_type_name()));		
		tableInterval.getColumns().addAll(colIntervalStart,colIntervalEnd,colIntervalLogger,colIntervalStation);

		GridPane.setRowIndex(tableInterval, 5);
		GridPane.setColumnIndex(tableInterval, 0);
		GridPane.setColumnSpan(tableInterval, 2);
		detailPane.getChildren().add(tableInterval);


		tableVirtualPlot.getSelectionModel().selectedItemProperty().addListener((s,o,virtualPlot)->{
			if(virtualPlot!=null) {
				lblVirtualPlot.setText(virtualPlot.plotID);
				lblGeneralStation.setText(virtualPlot.generalStationInfo==null?null:virtualPlot.generalStationInfo.name);
				lblLocation.setText(virtualPlot.geoPosEasting+"  ,  "+virtualPlot.geoPosNorthing);
				lblElevation.setText(""+virtualPlot.elevation);
				lblElevationTemperature.setText(""+virtualPlot.elevationTemperature);				
				tableInterval.setItems(FXCollections.observableList(virtualPlot.intervalList));				
			} else {
				lblVirtualPlot.setText(null);
				lblGeneralStation.setText(null);
				lblLocation.setText(null);
				lblElevation.setText(null);
				lblElevationTemperature.setText(null);
				tableInterval.setItems(null);
			}
		});

		return borderPane;
	}

	@SuppressWarnings("unchecked")
	private Node createLoggerView() {
		BorderPane borderPane = new BorderPane();

		tableLogger = new TableView<LoggerType>();
		TableColumn<LoggerType,String> colName = new TableColumn<LoggerType,String>("name");
		colName.setCellValueFactory(cdf->StringConstant.valueOf(cdf.getValue().typeName));
		tableLogger.getColumns().addAll(colName);

		borderPane.setLeft(tableLogger);


		GridPane detailPane = new GridPane();
		detailPane.setStyle("-fx-border-style:solid;-fx-border-color: transparent;-fx-border-width: 20;");
		detailPane.setHgap(10);
		detailPane.setVgap(10);

		Label lblLogger = new Label();
		detailPane.add(new Label("Logger"), 0, 0);
		detailPane.add(lblLogger, 1, 0);

		TableView<String> tableLoggerSensor = new TableView<String>();
		TableColumn<String,String> colLoggerSensorName = new TableColumn<String,String>("Sensor");
		colLoggerSensorName.setCellValueFactory(cdf->StringConstant.valueOf(cdf.getValue()));
		colLoggerSensorName.setMinWidth(180);
		tableLoggerSensor.getColumns().addAll(colLoggerSensorName);
		GridPane.setRowIndex(tableLoggerSensor, 1);
		GridPane.setColumnSpan(tableLoggerSensor, 2);
		detailPane.getChildren().add(tableLoggerSensor);


		TableView<Entry<String, String>> tableTranslation = new TableView<Entry<String, String>>();
		TableColumn<Entry<String, String>,String> colTranslationHeader = new TableColumn<Entry<String, String>,String>("Header");
		colTranslationHeader.setCellValueFactory(cdf->StringConstant.valueOf(cdf.getValue().getKey()));
		colTranslationHeader.setMinWidth(180);
		TableColumn<Entry<String, String>,String> colTranslationSensor = new TableColumn<Entry<String, String>,String>("Translation");
		colTranslationSensor.setCellValueFactory(cdf->StringConstant.valueOf(cdf.getValue().getValue()));
		colTranslationSensor.setMinWidth(180);
		tableTranslation.getColumns().addAll(colTranslationHeader,colTranslationSensor);

		GridPane.setRowIndex(tableTranslation, 1);
		GridPane.setColumnIndex(tableTranslation, 2);
		GridPane.setColumnSpan(tableTranslation, 2);
		detailPane.getChildren().add(tableTranslation);

		tableLogger.getSelectionModel().selectedItemProperty().addListener((s,o,logger)->{
			if(logger!=null) {
				lblLogger.setText(logger.typeName);
				tableLoggerSensor.setItems(FXCollections.observableArrayList(logger.sensorNames));

				ObservableList<Entry<String, String>> translationList = FXCollections.observableArrayList();
				if(logger.sensorNameTranlationMap!=null) {
					translationList.addAll(logger.sensorNameTranlationMap.entrySet());
				}
				tableTranslation.setItems(translationList);				
			}
		});

		borderPane.setCenter(detailPane);

		return borderPane;
	}


	private Node createGeneralStationView() {
		BorderPane borderPane = new BorderPane();
				
		tableGeneralStation = new TableView<GeneralStationInfo>();
		borderPane.setLeft(tableGeneralStation);
		TableColumn<GeneralStationInfo,String> colName = new TableColumn<GeneralStationInfo,String>("name");
		colName.setCellValueFactory(cdf->StringConstant.valueOf(cdf.getValue().name));
		tableGeneralStation.getColumns().addAll(colName);
				
		GridPane detailPane = new GridPane();
		borderPane.setCenter(detailPane);
		detailPane.setStyle("-fx-border-style:solid;-fx-border-color: transparent;-fx-border-width: 20;");
		detailPane.setHgap(10);
		detailPane.setVgap(10);

		Label lblGeneral = new Label();
		detailPane.add(new Label("General Station"), 0, 0);
		detailPane.add(lblGeneral, 1, 0);
		
		Label lblGeneralLong = new Label();
		detailPane.add(new Label("Full Name"), 0, 1);
		detailPane.add(lblGeneralLong, 1, 1);
		
		Label lblGroup = new Label();
		detailPane.add(new Label("Group"), 0, 2);
		detailPane.add(lblGroup, 1, 2);
		
		Label lblRegion = new Label();
		detailPane.add(new Label("Region"), 0, 3);
		detailPane.add(lblRegion, 1, 3);
		
		Label lblStations = new Label();
		detailPane.add(new Label("Station Plots"), 0, 4);
		detailPane.add(lblStations, 1, 4);
		
		Label lblVirtualPlots = new Label();
		detailPane.add(new Label("Virtual Plots"), 0, 5);
		detailPane.add(lblVirtualPlots, 1, 5);
		
		tableGeneralStation.getSelectionModel().selectedItemProperty().addListener((s,o,general)->{
			if(general!=null) {
				lblGeneral.setText(general.name);
				lblGeneralLong.setText(general.longName);
				lblGroup.setText(general.group);
				lblRegion.setText(general.region==null?null:general.region.name);
				lblStations.setText(""+general.stationCount);
				lblVirtualPlots.setText(""+general.virtualPlotCount);
			} else {
				lblGeneral.setText(null);
				lblGeneralLong.setText(null);
				lblGroup.setText(null);
				lblRegion.setText(null);
				lblStations.setText(null);
				lblVirtualPlots.setText(null);
			}
		});
		
		return borderPane;
	}
	
	private Node createRegionView() {
		BorderPane borderPane = new BorderPane();
		
		tableRegion = new TableView<Region>();
		borderPane.setLeft(tableRegion);
		TableColumn<Region,String> colName = new TableColumn<Region,String>("name");
		colName.setCellValueFactory(cdf->StringConstant.valueOf(cdf.getValue().name));
		tableRegion.getColumns().addAll(colName);
		
		GridPane detailPane = new GridPane();
		borderPane.setCenter(detailPane);
		detailPane.setStyle("-fx-border-style:solid;-fx-border-color: transparent;-fx-border-width: 20;");
		detailPane.setHgap(10);
		detailPane.setVgap(10);

		Label lblRegion = new Label();
		detailPane.add(new Label("Region"), 0, 0);
		detailPane.add(lblRegion, 1, 0);
		
		Label lblRegionLong = new Label();
		detailPane.add(new Label("Full Name"), 0, 1);
		detailPane.add(lblRegionLong, 1, 1);
		
		tableRegion.getSelectionModel().selectedItemProperty().addListener((s,o,region)->{
			if(region!=null) {
				lblRegion.setText(region.name);
				lblRegionLong.setText(region.longName);
			} else {
				lblRegion.setText(null);
				lblRegionLong.setText(null);
			}
		});
		
		return borderPane;
	}
	
	
	private void updateSensorPredicate(ActionEvent e) {
		if(checkBoxShowRawSensors.isSelected()) {
			filteredSensorList.setPredicate(s->true);
		} else {
			filteredSensorList.setPredicate(s->s.isAggregable());
		}	
	}

	private void createDataSensorView() {
		ObservableList<Sensor> sensorList = FXCollections.observableArrayList();
		filteredSensorList = new FilteredList<Sensor>(sensorList);
		updateSensorPredicate(null);

		try {
			Sensor[] sensors = tsdb.getSensors();
			if(sensors!=null)
				sensorList.addAll(sensors);
		} catch (Exception e) {
			e.printStackTrace();
			log.error(e);
		}
		tableSensor.setItems(filteredSensorList);
	}

	private void updateStationPredicate(ActionEvent e) {
		if(checkBoxShowPlotStationsOnly.isSelected()) {
			filteredStationList.setPredicate(s->s.generalStationInfo!=null); // change !!!
		} else {
			filteredStationList.setPredicate(s->true);			
		}	
	}

	private void createDataStationView() {
		ObservableList<StationInfo> stationList = FXCollections.observableArrayList();
		filteredStationList = new FilteredList<StationInfo>(stationList);
		updateSensorPredicate(null);

		try {
			StationInfo[] stations = tsdb.getStations();
			if(stations!=null)
				stationList.addAll(stations);
		} catch (Exception e) {
			e.printStackTrace();
			log.error(e);
		}

		tableStation.setItems(filteredStationList);
	}

	private void createDataVirtualPlotView() {
		ObservableList<VirtualPlotInfo> virtualPlotList = FXCollections.observableArrayList();

		try {
			VirtualPlotInfo[] virtualPlots = tsdb.getVirtualPlots();
			if(virtualPlots!=null)
				virtualPlotList.addAll(virtualPlots);
		} catch (Exception e) {
			e.printStackTrace();
			log.error(e);
		}		

		tableVirtualPlot.setItems(virtualPlotList);
	}

	private void createDataLoggerView() {
		ObservableList<LoggerType> loggerList = FXCollections.observableArrayList();
		try {
			LoggerType[] loggers = tsdb.getLoggerTypes();
			if(loggers!=null)
				loggerList.addAll(loggers);
		} catch (Exception e) {
			e.printStackTrace();
			log.error(e);
		}
		tableLogger.setItems(loggerList);
	}
	
	private void createDataGeneralStationView() {
		ObservableList<GeneralStationInfo> generalList = FXCollections.observableArrayList();
		try {
			GeneralStationInfo[] generals = tsdb.getGeneralStations();
			if(generals!=null) {
				generalList.addAll(generals);
			}
		} catch (Exception e) {
			e.printStackTrace();
			log.error(e);
		}
		tableGeneralStation.setItems(generalList);
	}
	
	private void createDataRegionView() {
		ObservableList<Region> regionList = FXCollections.observableArrayList();
		try {
			Region[] regions = tsdb.getRegions();
			if(regions!=null) {
				regionList.addAll(regions);
			}
		} catch (Exception e) {
			e.printStackTrace();
			log.error(e);
		}
		tableRegion.setItems(regionList);
	}

	@Override
	protected void onShown() {
		createDataSensorView();
		createDataStationView();
		createDataLoggerView();
		createDataVirtualPlotView();
		createDataGeneralStationView();
		createDataRegionView();
	}
}