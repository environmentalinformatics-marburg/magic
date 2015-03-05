package tsdb.explorer.metadata;

import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.scene.Node;
import javafx.scene.control.Label;
import javafx.scene.control.TableColumn;
import javafx.scene.control.TableView;
import javafx.scene.layout.BorderPane;
import javafx.scene.layout.GridPane;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import tsdb.Region;
import tsdb.remote.RemoteTsDB;

import com.sun.javafx.binding.StringConstant;

public class RegionView {
	private static final Logger log = LogManager.getLogger();
	
	private TableView<Region> tableRegion;
	
	private Node node;
	
	public RegionView() {
		node = createContent();
	}
	
	public Node getNode() {
		return node;
	}
	
	@SuppressWarnings("unchecked")
	private Node createContent() {
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
		
		Label lblRegionViewTimeRange = new Label();
		detailPane.add(new Label("View Time Range"), 0, 2);
		detailPane.add(lblRegionViewTimeRange, 1, 2);
		
		tableRegion.getSelectionModel().selectedItemProperty().addListener((s,o,region)->{
			if(region!=null) {
				lblRegion.setText(region.name);
				lblRegionLong.setText(region.longName);
				lblRegionViewTimeRange.setText(region.viewTimeRange.toString());
			} else {
				lblRegion.setText(null);
				lblRegionLong.setText(null);
				lblRegionViewTimeRange.setText(null);
			}
		});
		
		return borderPane;
	}
	
	public void collectData(RemoteTsDB tsdb) {
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
}
