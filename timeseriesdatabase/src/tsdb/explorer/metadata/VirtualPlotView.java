package tsdb.explorer.metadata;

import javax.swing.SortOrder;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.event.EventHandler;
import javafx.scene.Node;
import javafx.scene.control.Hyperlink;
import javafx.scene.control.Label;
import javafx.scene.control.TableCell;
import javafx.scene.control.TableColumn;
import javafx.scene.control.TableColumn.SortType;
import javafx.scene.control.TableView;
import javafx.scene.input.MouseEvent;
import javafx.scene.layout.BorderPane;
import javafx.scene.layout.GridPane;
import javafx.util.Callback;
import tsdb.StationProperties;
import tsdb.explorer.FXUtil;
import tsdb.remote.GeneralStationInfo;
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
	
	private TableView<TimestampInterval<StationProperties>> tableInterval;

	private Node node;

	private final MetadataScene metadataScene;

	public VirtualPlotView(MetadataScene metadataScene) {
		this.metadataScene = metadataScene;
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
		tableVirtualPlot.setColumnResizePolicy(TableView.CONSTRAINED_RESIZE_POLICY);
		borderPane.setLeft(tableVirtualPlot);

		TableColumn<VirtualPlotInfo,String> colName = new TableColumn<VirtualPlotInfo,String>("name");
		colName.setCellValueFactory(cdf->StringConstant.valueOf(cdf.getValue().plotID));
		colName.comparatorProperty().set(String.CASE_INSENSITIVE_ORDER);
		tableVirtualPlot.getColumns().addAll(colName);
		tableVirtualPlot.getSortOrder().clear();
		tableVirtualPlot.getSortOrder().add(colName);

		GridPane detailPane = new GridPane();
		borderPane.setCenter(detailPane);
		detailPane.setStyle("-fx-border-style:solid;-fx-border-color: transparent;-fx-border-width: 20;");
		detailPane.setHgap(10);
		detailPane.setVgap(10);

		Label lblVirtualPlot = new Label();
		detailPane.add(new Label("Virtual Plot"), 0, 0);
		detailPane.add(lblVirtualPlot, 1, 0);

		//Label lblGeneralStation = new Label();
		Hyperlink lblGeneralStation = new Hyperlink();		
		lblGeneralStation.setOnAction(e->{
			VirtualPlotInfo virtualPlot = tableVirtualPlot.getSelectionModel().selectedItemProperty().get();
			GeneralStationInfo generalStation = virtualPlot.generalStationInfo;
			metadataScene.selectGeneralStation(generalStation.name);
			lblGeneralStation.setVisited(false);
		});
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


		tableInterval = new TableView<TimestampInterval<StationProperties>>();
		tableInterval.setColumnResizePolicy(TableView.CONSTRAINED_RESIZE_POLICY);
		TableColumn<TimestampInterval<StationProperties>,Long> colIntervalStart = new TableColumn<TimestampInterval<StationProperties>,Long>("Start");
		colIntervalStart.setCellValueFactory(cdf->ObjectConstant.<Long>valueOf(cdf.getValue().start));
		colIntervalStart.setMinWidth(150);
		colIntervalStart.setCellFactory(p->new TimestampTableCell());
		colIntervalStart.setComparator(TimeConverter.TIMESTAMP_START_ASC_COMPARATOR);
		TableColumn<TimestampInterval<StationProperties>,Long> colIntervalEnd = new TableColumn<TimestampInterval<StationProperties>,Long>("End");
		colIntervalEnd.setCellValueFactory(cdf->ObjectConstant.<Long>valueOf(cdf.getValue().end));
		colIntervalEnd.setMinWidth(150);
		colIntervalEnd.setCellFactory(p->new TimestampTableCell());
		colIntervalEnd.setComparator(TimeConverter.TIMESTAMP_END_ASC_COMPARATOR);
		TableColumn<TimestampInterval<StationProperties>,String> colIntervalStation = new TableColumn<TimestampInterval<StationProperties>,String>("Station");
		colIntervalStation.setCellValueFactory(cdf->StringConstant.valueOf(cdf.getValue().value.get_serial()));		
		colIntervalStation.setCellFactory(FXUtil.cellFactoryWithOnClicked(e->{
			StationProperties stationProperties = tableInterval.getSelectionModel().selectedItemProperty().get().value;
			String serial = stationProperties.get_serial();
			metadataScene.selectStation(serial);
		}));
		colIntervalStation.setComparator(String.CASE_INSENSITIVE_ORDER);
		colIntervalStation.setMinWidth(150);
		TableColumn<TimestampInterval<StationProperties>,String> colIntervalLogger = new TableColumn<TimestampInterval<StationProperties>,String>("Logger");
		colIntervalLogger.setCellFactory(FXUtil.cellFactoryWithOnClicked(e->{
			StationProperties stationProperties = tableInterval.getSelectionModel().selectedItemProperty().get().value;
			String logger = stationProperties.get_logger_type_name();
			metadataScene.selectLogger(logger);
		}));
		colIntervalLogger.setCellValueFactory(cdf->StringConstant.valueOf(cdf.getValue().value.get_logger_type_name()));
		colIntervalLogger.setComparator(String.CASE_INSENSITIVE_ORDER);
		colIntervalLogger.setMinWidth(150);
		tableInterval.getColumns().addAll(colIntervalStart,colIntervalEnd,colIntervalLogger,colIntervalStation);
		tableInterval.getSortOrder().clear();
		tableInterval.getSortOrder().addAll(colIntervalStart,colIntervalEnd,colIntervalLogger,colIntervalStation);

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
				tableInterval.sort();
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
		tableVirtualPlot.sort();
	}

}
