package tsdb.explorer.metadata;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.collections.transformation.FilteredList;
import javafx.event.ActionEvent;
import javafx.scene.Node;
import javafx.scene.control.CheckBox;
import javafx.scene.control.Label;
import javafx.scene.control.TableColumn;
import javafx.scene.control.TableView;
import javafx.scene.layout.BorderPane;
import javafx.scene.layout.GridPane;
import tsdb.remote.RemoteTsDB;
import tsdb.remote.StationInfo;

import com.sun.javafx.binding.StringConstant;

public class StationView {
	private static final Logger log = LogManager.getLogger();	
	
	private TableView<StationInfo> tableStation;
	private CheckBox checkBoxShowPlotStationsOnly;
	private FilteredList<StationInfo> filteredStationList;
	
	private Node node;
	
	public StationView() {
		node = createContent();
	}
	
	public Node getNode() {
		return node;
	}
	
	@SuppressWarnings("unchecked")
	private Node createContent() {
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
	
	private void updateStationPredicate(ActionEvent e) {
		if(checkBoxShowPlotStationsOnly.isSelected()) {
			filteredStationList.setPredicate(s->s.generalStationInfo!=null); // change !!!
		} else {
			filteredStationList.setPredicate(s->true);			
		}	
	}
	
	public void collectData(RemoteTsDB tsdb) {
		ObservableList<StationInfo> stationList = FXCollections.observableArrayList();
		filteredStationList = new FilteredList<StationInfo>(stationList);
		updateStationPredicate(null);

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
}
