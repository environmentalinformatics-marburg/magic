package tsdb.explorer.metadata;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.scene.Node;
import javafx.scene.control.Label;
import javafx.scene.control.TableCell;
import javafx.scene.control.TableColumn;
import javafx.scene.control.TableView;
import javafx.scene.layout.BorderPane;
import javafx.scene.layout.GridPane;
import tsdb.StationProperties;
import tsdb.remote.RemoteTsDB;
import tsdb.remote.VirtualPlotInfo;
import tsdb.util.TimeConverter;
import tsdb.util.TimestampInterval;

import com.sun.javafx.binding.ObjectConstant;
import com.sun.javafx.binding.StringConstant;

/**
 * Overview of virtual plots
 * @author woellauer
 *
 */
public class VirtualPlotView {
	private static final Logger log = LogManager.getLogger();
	
	private TableView<VirtualPlotInfo> tableVirtualPlot;
	
	private Node node;
	
	public VirtualPlotView() {
		node = createContent();
	}
	
	public Node getNode() {
		return node;
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
	
	
	@SuppressWarnings("unchecked")
	private Node createContent() {
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
	
	public void collectData(RemoteTsDB tsdb) {
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

}
