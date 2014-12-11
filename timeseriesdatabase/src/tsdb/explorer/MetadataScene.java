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
import javafx.scene.control.Tab;
import javafx.scene.control.TabPane;
import javafx.scene.control.TabPane.TabClosingPolicy;
import javafx.scene.control.TableColumn;
import javafx.scene.control.TableView;
import javafx.scene.layout.BorderPane;
import javafx.scene.layout.GridPane;
import javafx.scene.layout.HBox;
import javafx.scene.layout.VBox;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import com.sun.javafx.binding.StringConstant;
import com.sun.javafx.scene.control.behavior.TabPaneBehavior;

import tsdb.LoggerType;
import tsdb.Sensor;
import tsdb.remote.RemoteTsDB;
import tsdb.remote.StationInfo;

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

	public MetadataScene(RemoteTsDB tsdb) {
		super("time series databaes metadata view");		
		throwNull(tsdb);
		this.tsdb = tsdb;

	}

	@Override
	protected Parent createContent() {
		TabPane tabPane = new TabPane();
		tabPane.setTabClosingPolicy(TabClosingPolicy.UNAVAILABLE);

		Tab tabStation = new Tab("Station");
		tabStation.setContent(createStationView());
		tabPane.getTabs().add(tabStation);
		
		Tab tabLogger = new Tab("Logger");
		tabLogger.setContent(createLoggerView());
		tabPane.getTabs().add(tabLogger);
		
		Tab tabSensor = new Tab("Sensor");
		tabSensor.setContent(createSensorView());
		tabPane.getTabs().add(tabSensor);


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
		tableLoggerSensor.getColumns().addAll(colLoggerSensorName);
		GridPane.setRowIndex(tableLoggerSensor, 1);
		GridPane.setColumnSpan(tableLoggerSensor, 2);
		detailPane.getChildren().add(tableLoggerSensor);
		
		
		TableView<Entry<String, String>> tableTranslation = new TableView<Entry<String, String>>();
		TableColumn<Entry<String, String>,String> colTranslationHeader = new TableColumn<Entry<String, String>,String>("Header");
		colTranslationHeader.setCellValueFactory(cdf->StringConstant.valueOf(cdf.getValue().getKey()));
		TableColumn<Entry<String, String>,String> colTranslationSensor = new TableColumn<Entry<String, String>,String>("Translation");
		colTranslationSensor.setCellValueFactory(cdf->StringConstant.valueOf(cdf.getValue().getValue()));
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

	@Override
	protected void onShown() {
		createDataSensorView();
		createDataStationView();
		createDataLoggerView();
	}


}