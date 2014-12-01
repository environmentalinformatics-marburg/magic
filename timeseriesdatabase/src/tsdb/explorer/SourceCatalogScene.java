package tsdb.explorer;

import java.rmi.RemoteException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.TreeMap;
import java.util.TreeSet;

import javafx.beans.value.ChangeListener;
import javafx.beans.value.ObservableValue;
import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.collections.transformation.FilteredList;
import javafx.collections.transformation.SortedList;
import javafx.scene.Scene;
import javafx.scene.control.ComboBox;
import javafx.scene.control.Label;
import javafx.scene.control.TableCell;
import javafx.scene.control.TableColumn;
import javafx.scene.control.TableView;
import javafx.scene.layout.BorderPane;
import javafx.scene.layout.HBox;
import javafx.util.Callback;
import javafx.util.StringConverter;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import tsdb.Region;
import tsdb.StationProperties;
import tsdb.TimeConverter;
import tsdb.catalog.SourceEntry;
import tsdb.remote.GeneralStationInfo;
import tsdb.remote.RemoteTsDB;
import tsdb.remote.StationInfo;
import tsdb.remote.VirtualPlotInfo;
import tsdb.util.TimestampInterval;
import tsdb.util.TsSchema;

import com.sun.javafx.binding.ObjectConstant;

public class SourceCatalogScene {
	
	private static String ESCAPE = ""+(char)27;

	private static <S, T> Callback<TableColumn<S,T>, TableCell<S,T>> createCellFactory(Callback<T,String> converter) {
		return param -> new TableCell<S, T>(){
			@Override
			protected void updateItem(T item, boolean empty) {
				super.updateItem(item, empty);
				if(empty) {
					setText(null);
				} else {
					setText(converter.call(item));
				}
			}
		};
	}

	private final RemoteTsDB tsdb;
	private Scene scene;
	private ArrayList<SourceItem> sourceItemList;
	private FilteredList<SourceItem> filteredList;
	private Region[] regions;

	ComboBox<Region> comboRegion;
	ComboBox<String> comboGeneralStation;
	ComboBox<String> comboPlot;
	
	TableView<SourceItem> table;

	private final Region regionAll = new Region("[all]","[all]");

	public SourceCatalogScene(RemoteTsDB tsdb) {
		this.tsdb = tsdb;		
		createScene();
		//createData();
	}

	private static final Logger log = LogManager.getLogger();
	
	public void createScene() {
		table = new TableView<SourceItem>();

		TableColumn<SourceItem,String> colPlot = new TableColumn<SourceItem,String>("plot");		
		colPlot.setCellValueFactory(param->ObjectConstant.valueOf(param.getValue().plotid));
		colPlot.setComparator(String.CASE_INSENSITIVE_ORDER);

		TableColumn<SourceItem,Long> colFirst = new TableColumn<SourceItem,Long>("first");		
		colFirst.setCellValueFactory(param->ObjectConstant.valueOf(param.getValue().sourceEntry.firstTimestamp));
		colFirst.setCellFactory(createCellFactory(t->TimeConverter.oleMinutesToText(t)));

		TableColumn<SourceItem,Long> colLast = new TableColumn<SourceItem,Long>("last");		
		colLast.setCellValueFactory(param->ObjectConstant.valueOf(param.getValue().sourceEntry.lastTimestamp));
		colLast.setCellFactory(createCellFactory(t->TimeConverter.oleMinutesToText(t)));

		TableColumn<SourceItem,String> colStation = new TableColumn<SourceItem,String>("station");		
		colStation.setCellValueFactory(param->ObjectConstant.valueOf(param.getValue().sourceEntry.stationName));
		colStation.setComparator(String.CASE_INSENSITIVE_ORDER);
		colStation.setMinWidth(80);

		TableColumn<SourceItem,String> colPath = new TableColumn<SourceItem,String>("path");		
		colPath.setCellValueFactory(param->ObjectConstant.valueOf(param.getValue().sourceEntry.path));
		colPath.setComparator(String.CASE_INSENSITIVE_ORDER);

		TableColumn<SourceItem,String> colFilename = new TableColumn<SourceItem,String>("filename");		
		colFilename.setCellValueFactory(param->ObjectConstant.valueOf(param.getValue().sourceEntry.filename));
		colFilename.setComparator(String.CASE_INSENSITIVE_ORDER);

		TableColumn<SourceItem,Integer> colRows = new TableColumn<SourceItem,Integer>("rows");		
		colRows.setCellValueFactory(param->ObjectConstant.valueOf(param.getValue().sourceEntry.rows));

		TableColumn<SourceItem,Integer> colTimeStep = new TableColumn<SourceItem,Integer>("time-step");		
		colTimeStep.setCellValueFactory(param->ObjectConstant.valueOf(param.getValue().sourceEntry.timeStep));
		colTimeStep.setCellFactory(createCellFactory(timestep->timestep==null||timestep==TsSchema.NO_CONSTANT_TIMESTEP?null:timestep.toString()));

		TableColumn<SourceItem,String> colHeader = new TableColumn<SourceItem,String>("header");		
		colHeader.setCellValueFactory(param->ObjectConstant.valueOf(Arrays.toString(param.getValue().sourceEntry.headerNames)));
		colHeader.setComparator(String.CASE_INSENSITIVE_ORDER);
		colHeader.setMinWidth(160);


		TableColumn<SourceItem,String> colSensors = new TableColumn<SourceItem,String>("sensors");		
		colSensors.setCellValueFactory(param->ObjectConstant.valueOf(Arrays.toString(param.getValue().sourceEntry.sensorNames)));
		colSensors.setComparator(String.CASE_INSENSITIVE_ORDER);
		colSensors.setMinWidth(160);


		TableColumn<SourceItem,String> colGeneralStation = new TableColumn<SourceItem,String>("general");		
		colGeneralStation.setCellValueFactory(param->ObjectConstant.valueOf(param.getValue().generalStationName));
		colPlot.setComparator(String.CASE_INSENSITIVE_ORDER);

		table.getColumns().setAll(colGeneralStation,colPlot,colStation,colFirst,colLast,colRows,colTimeStep,colFilename,colPath,colHeader,colSensors);

		BorderPane mainBoderPane = new BorderPane();		
		mainBoderPane.setCenter(table);
		
		Label lblStatus = new Label("ready");
		mainBoderPane.setBottom(lblStatus);
		
		comboRegion = new ComboBox<Region>();
		StringConverter<Region> regionConverter = new StringConverter<Region>() {			
			@Override
			public String toString(Region region) {
				return region.longName;
			}			
			@Override
			public Region fromString(String string) {
				return null;
			}
		};
		comboRegion.setConverter(regionConverter);
		comboRegion.valueProperty().addListener(this::onRegionChanged);


		comboGeneralStation = new ComboBox<String>();
		comboGeneralStation.valueProperty().addListener(this::onGeneralStationChanged);

		comboPlot = new ComboBox<String>();
		comboPlot.valueProperty().addListener(this::onPlotChanged);

		HBox hBoxControl = new HBox(10d);
		hBoxControl.getChildren().add(new Label("Region"));
		hBoxControl.getChildren().add(comboRegion);
		hBoxControl.getChildren().add(new Label("General"));
		hBoxControl.getChildren().add(comboGeneralStation);
		hBoxControl.getChildren().add(new Label("Plot"));
		hBoxControl.getChildren().add(comboPlot);
		mainBoderPane.setTop(hBoxControl);
		this.scene = new Scene(mainBoderPane, 400, 400);		
	}	

	public void createData() {
		sourceItemList = new ArrayList<SourceItem>();

		try {			
			HashMap<String, ArrayList<SourceEntry>> stationCatalogEntryMap = new HashMap<String, ArrayList<SourceEntry>>();
			for(SourceEntry sourceEntry:tsdb.getSourceCatalogEntries()) {
				ArrayList<SourceEntry> list = stationCatalogEntryMap.get(sourceEntry.stationName);
				if(list==null) {
					list = new ArrayList<SourceEntry>();
					stationCatalogEntryMap.put(sourceEntry.stationName, list);
				}
				list.add(sourceEntry);			
			}			

			for(StationInfo stationInfo:tsdb.getStationInfos()) {
				ArrayList<SourceEntry> sourceEntryList = stationCatalogEntryMap.get(stationInfo.stationID);
				if(sourceEntryList!=null) {
					if(stationInfo.generalStationInfo!=null) {
						for(SourceEntry sourceEntry:sourceEntryList) {
							SourceItem sourceItem = new SourceItem(sourceEntry);
							sourceItem.generalStationName = stationInfo.generalStationInfo.name;
							sourceItem.regionName = stationInfo.generalStationInfo.region.name;
							sourceItem.plotid = stationInfo.stationID;
							sourceItemList.add(sourceItem);
						}
					}				
				}
			}

			for(VirtualPlotInfo virtualPlotInfo:tsdb.getVirtualPlots()) {
				for(TimestampInterval<StationProperties> interval:virtualPlotInfo.intervalList) {
					ArrayList<SourceEntry> sourceEntryList = stationCatalogEntryMap.get(interval.value.get_serial());
					if(sourceEntryList!=null) {
						for(SourceEntry sourceEntry:sourceEntryList) {
							if(interval.contains(sourceEntry.firstTimestamp, sourceEntry.lastTimestamp)) {
								SourceItem sourceItem = new SourceItem(sourceEntry);
								sourceItem.generalStationName = virtualPlotInfo.generalStationInfo.name;
								sourceItem.regionName = virtualPlotInfo.generalStationInfo.region.name;
								sourceItem.plotid = virtualPlotInfo.plotID;
								sourceItemList.add(sourceItem);
							}
						}
					}
				}
			}
			regions = tsdb.getRegions();
			
			
			filteredList = new FilteredList<SourceItem>(FXCollections.observableArrayList(sourceItemList));
			SortedList<SourceItem> sortedList = new SortedList<SourceItem>(filteredList);
			sortedList.comparatorProperty().bind(table.comparatorProperty());
			table.setItems(sortedList);
			
			setRegions(regions);
			
		} catch (RemoteException e) {
			e.printStackTrace();
			log.error(e);
			regions = new Region[0];
		}		

	}



	public Scene getScene() {
		return scene;
	}
	
	void setRegions(Region[] regions) {
		ObservableList<Region> regionList = FXCollections.observableArrayList();
		regionList.add(regionAll);
		regionList.addAll(regions);
		comboRegion.setItems(regionList);
		comboRegion.setValue(regionAll);		
	}
	
	void onRegionChanged(ObservableValue<? extends Region> observable, Region oldValue, Region newValue) {
		TreeSet<String> generalSet = new TreeSet<String>();
		Region region = newValue;		
		if(region==null||region.name.equals("[all]")) {
			for(SourceItem sourceItem:sourceItemList) {
				generalSet.add(sourceItem.generalStationName);
			}
		} else {		
			for(SourceItem sourceItem:sourceItemList) {
				if(sourceItem.regionName.equals(region.name)) {
					generalSet.add(sourceItem.generalStationName);
				};
			}
		}
		ObservableList<String> generals = FXCollections.observableArrayList();
		String generalAll = "[all]";
		generals.add(generalAll);
		generals.addAll(generalSet);
		comboGeneralStation.setItems(generals);
		comboGeneralStation.setValue(generalAll);

		//updateComboPlot();		
	}
	
	void onGeneralStationChanged(ObservableValue<? extends String> observable, String oldValue, String newValue) {
		System.out.println(oldValue+"     "+newValue);
		Region region = comboRegion.getValue();
		TreeSet<String> plotSet = new TreeSet<String>();
		String general = newValue;
		if(general==null||general.equals("[all]")) {
			for(SourceItem sourceItem:sourceItemList) {
				if(region==null||region.name.equals("[all]")||sourceItem.regionName.equals(region.name)) {
					plotSet.add(sourceItem.plotid);
				}
			}		
		} else {
			for(SourceItem sourceItem:sourceItemList) {
				if(sourceItem.generalStationName.equals(general)) {
					plotSet.add(sourceItem.plotid);
				}
			}	
		}

		ObservableList<String> plots = FXCollections.observableArrayList();
		String plotAll = "[all]";
		plots.add(plotAll );
		plots.addAll(plotSet);
		comboPlot.setItems(plots);
		comboPlot.setValue(plotAll);
	}
	
	void onPlotChanged(ObservableValue<? extends String> observable, String oldValue, String newValue) {
		System.out.println(oldValue+"     "+newValue);
		Region region = comboRegion.getValue();
		String general = comboGeneralStation.getValue();
		String plot = newValue;

		if(plot==null||plot.equals("[all]")) {
			if(general==null||general.equals("[all]")) {
				if(region==null||region.name.equals("[all]")) {
					filteredList.setPredicate(sourceEntry->true);
				} else {
					filteredList.setPredicate(sourceEntry->region.name.equals(sourceEntry.regionName));
				}
			} else {
				filteredList.setPredicate(sourceEntry->general.equals(sourceEntry.generalStationName));
			}
		} else {
			filteredList.setPredicate(sourceEntry->plot.equals(sourceEntry.plotid));
		}
	}
	
	public void setOnClose(Callback<Boolean,Boolean> cb) {
		scene.setOnKeyTyped(value->{			
			if(value.getCharacter().equals(ESCAPE)) {
				cb.call(true);
			}
		});
	}

}
