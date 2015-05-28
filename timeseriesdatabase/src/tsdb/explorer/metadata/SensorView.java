package tsdb.explorer.metadata;

import java.util.ArrayList;

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

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import tsdb.component.Sensor;
import tsdb.remote.RemoteTsDB;

import com.sun.javafx.binding.StringConstant;

/**
 * Overview of sensors
 * @author woellauer
 *
 */
public class SensorView {	
	private static final Logger log = LogManager.getLogger();
	
	TableView<Sensor> tableSensor;
	private CheckBox checkBoxShowRawSensors;
	private FilteredList<Sensor> filteredSensorList;
	
	private Node node;
	
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
	
	public SensorView() {
		node = createContent();
	}
	
	public Node getNode() {
		return node;
	}
	
	@SuppressWarnings("unchecked")
	private Node createContent() {
		BorderPane borderPane = new BorderPane();

		tableSensor = new TableView<Sensor>();

		TableColumn<Sensor,String> colName = new TableColumn<Sensor,String>("name");
		colName.setCellValueFactory(cdf->StringConstant.valueOf(cdf.getValue().name));


		tableSensor.getColumns().setAll(colName);


		borderPane.setLeft(tableSensor);



		GridPane detailPane = new GridPane();
		detailPane.setStyle("-fx-border-style:solid;-fx-border-color: transparent;-fx-border-width: 20;");
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
	
	private void updateSensorPredicate(ActionEvent e) {
		if(checkBoxShowRawSensors.isSelected()) {
			filteredSensorList.setPredicate(s->true);
		} else {
			filteredSensorList.setPredicate(s->s.isAggregable());
		}	
	}

	public void collectData(RemoteTsDB tsdb) {
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

}
