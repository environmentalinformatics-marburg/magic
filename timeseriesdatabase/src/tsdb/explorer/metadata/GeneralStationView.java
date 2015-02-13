package tsdb.explorer.metadata;

import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.collections.transformation.FilteredList;
import javafx.scene.Node;
import javafx.scene.control.CheckBox;
import javafx.scene.control.Label;
import javafx.scene.control.TableColumn;
import javafx.scene.control.TableView;
import javafx.scene.layout.BorderPane;
import javafx.scene.layout.GridPane;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import com.sun.javafx.binding.StringConstant;

import tsdb.remote.GeneralStationInfo;
import tsdb.remote.RemoteTsDB;
import tsdb.remote.StationInfo;

public class GeneralStationView {
	private static final Logger log = LogManager.getLogger();
	
	private TableView<GeneralStationInfo> tableGeneralStation;
	
	private Node node;
	
	public GeneralStationView() {
		node = createContent();
	}
	
	public Node getNode() {
		return node;
	}
	
	private Node createContent() {
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
	
	public void collectData(RemoteTsDB tsdb) {
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

}
