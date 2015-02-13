package tsdb.explorer.metadata;

import java.util.Map.Entry;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import com.sun.javafx.binding.StringConstant;

import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.scene.Node;
import javafx.scene.control.Label;
import javafx.scene.control.TableColumn;
import javafx.scene.control.TableView;
import javafx.scene.layout.BorderPane;
import javafx.scene.layout.GridPane;
import tsdb.LoggerType;
import tsdb.remote.RemoteTsDB;

public class LoggerView {
	private static final Logger log = LogManager.getLogger();	
	
	private TableView<LoggerType> tableLogger;
	
	private Node node;
	
	public LoggerView () {
		node = createContent();
	}
	
	public Node getNode() {
		return node;
	}
	
	@SuppressWarnings("unchecked")
	private Node createContent() {
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
	
	public void collectData(RemoteTsDB tsdb) {
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

}
