package tsdb.explorer;

import java.awt.Graphics2D;
import java.awt.image.BufferedImage;
import java.rmi.RemoteException;
import java.util.HashMap;
import java.util.Map;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import tsdb.DataQuality;
import tsdb.Region;
import tsdb.Sensor;
import tsdb.SensorCategory;
import tsdb.TimeConverter;
import tsdb.aggregated.AggregationInterval;
import tsdb.raw.TimestampSeries;
import tsdb.remote.GeneralStationInfo;
import tsdb.remote.PlotInfo;
import tsdb.remote.RemoteTsDB;
import tsdb.util.gui.TimeSeriesDiagram;
import tsdb.util.gui.TimeSeriesPainterGraphics2D;
import javafx.beans.property.ObjectProperty;
import javafx.beans.property.SimpleObjectProperty;
import javafx.beans.value.ObservableValue;
import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.embed.swing.SwingFXUtils;
import javafx.geometry.Orientation;
import javafx.geometry.Pos;
import javafx.scene.Node;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.scene.control.ComboBox;
import javafx.scene.control.Label;
import javafx.scene.control.ScrollPane;
import javafx.scene.control.Separator;
import javafx.scene.image.ImageView;
import javafx.scene.image.WritableImage;
import javafx.scene.input.MouseEvent;
import javafx.scene.input.ScrollEvent;
import javafx.scene.layout.AnchorPane;
import javafx.scene.layout.BorderPane;
import javafx.scene.layout.FlowPane;
import javafx.scene.layout.HBox;
import javafx.stage.Stage;
import javafx.util.StringConverter;
import static tsdb.util.AssumptionCheck.*;

public class TimeSeriesViewSceneNew extends TsdbScene {
	private static final Logger log = LogManager.getLogger();	
	private final RemoteTsDB tsdb;
	
	private ImageView imageView;
	private AnchorPane anchorPane;

	private ObjectProperty<TimeSeriesDiagram> tsdProperty;

	private static final Region regionAll = new Region("[all]","[all]");
	private static final GeneralStationInfo GeneralStationAll = new GeneralStationInfo("[all]", "[?]");
	private static final String plotAll = "[all]";

	private float zoomFactor = 1;

	private ComboBox<Region> comboRegion;
	private ComboBox<GeneralStationInfo> comboGeneralStation;
	private ComboBox<PlotInfo> comboPlot;
	private ComboBox<Sensor> comboSensor;

	private Double mouseStartMovePos = null;

	public TimeSeriesViewSceneNew(RemoteTsDB tsdb) {
		super("time series view");
		throwNull(tsdb);
		this.tsdb = tsdb;
	}

	@Override
	protected Parent createContent() {
		imageView = new ImageView();		
		imageView.setOnScroll(this::onScroll);
		imageView.setOnMouseDragged(this::onMouseDragged);
		imageView.setOnMousePressed(this::onMousePressed);


		anchorPane = new AnchorPane();
		AnchorPane.setTopAnchor(imageView, 0.0);
		AnchorPane.setBottomAnchor(imageView, 0.0);
		AnchorPane.setLeftAnchor(imageView, 0.0);
		AnchorPane.setRightAnchor(imageView, 0.0);
		anchorPane.getChildren().add(imageView);
		anchorPane.widthProperty().addListener(x->repaint());
		anchorPane.heightProperty().addListener(x->repaint());
		anchorPane.setOnMouseClicked(x->repaint());
		anchorPane.setMinSize(10, 10);

		Label labelRegion = new Label("Region");
		labelRegion.setAlignment(Pos.CENTER);
		labelRegion.setMaxHeight(100d);
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

		Label labelGeneralStation = new Label("General");
		labelGeneralStation.setAlignment(Pos.CENTER);
		labelGeneralStation.setMaxHeight(100d);
		comboGeneralStation = new ComboBox<GeneralStationInfo>();
		StringConverter<GeneralStationInfo> generalStationConverter = new StringConverter<GeneralStationInfo>() {			
			@Override
			public String toString(GeneralStationInfo general) {
				return general.longName;
			}			
			@Override
			public GeneralStationInfo fromString(String string) {
				return null;
			}
		};
		comboGeneralStation.setConverter(generalStationConverter);
		comboGeneralStation.valueProperty().addListener(this::onGeneralStationChanged);

		Label labelPlot = new Label("Plot");
		labelPlot.setAlignment(Pos.CENTER);
		labelPlot.setMaxHeight(100d);
		comboPlot = new ComboBox<PlotInfo>();
		StringConverter<PlotInfo> plotConverter = new StringConverter<PlotInfo>() {			
			@Override
			public String toString(PlotInfo plot) {
				return plot.name;
			}			
			@Override
			public PlotInfo fromString(String string) {
				return null;
			}
		};
		comboPlot.setConverter(plotConverter);
		comboPlot.valueProperty().addListener(this::onPlotChanged);

		Label labelSensor = new Label("Sensor");
		labelSensor.setAlignment(Pos.CENTER);
		labelSensor.setMaxHeight(100d);
		comboSensor = new ComboBox<Sensor>();
		StringConverter<Sensor> sensorConverter = new StringConverter<Sensor>() {			
			@Override
			public String toString(Sensor sensor) {
				return sensor.name;
			}			
			@Override
			public Sensor fromString(String string) {
				return null;
			}
		};
		comboSensor.setConverter(sensorConverter);
		comboSensor.valueProperty().addListener(this::onSensorChanged);

		FlowPane top = new FlowPane();
		top.setHgap(30d);
		top.setVgap(3d);
		top.getChildren().add(new HBox(10d,labelRegion,comboRegion,new Separator(Orientation.VERTICAL)));
		top.getChildren().add(new HBox(10d,labelGeneralStation,comboGeneralStation,new Separator(Orientation.VERTICAL)));
		top.getChildren().add(new HBox(10d,labelPlot,comboPlot,new Separator(Orientation.VERTICAL)));
		top.getChildren().add(new HBox(10d,labelSensor,comboSensor,new Separator(Orientation.VERTICAL)));
		Node center = anchorPane;
		Node bottom = new Label("ready");
		Node left = null;
		Node right = null;
		ScrollPane sc = new ScrollPane(top);
		//sc.setFitToHeight(true); // no
		sc.setFitToWidth(true);
		sc.prefHeightProperty().bind(top.heightProperty().add(10));

		tsdProperty = new SimpleObjectProperty<TimeSeriesDiagram >();
		tsdProperty.addListener(o->{
			zoomFactor=1;
			repaint();
		});
		
		return new BorderPane(center, sc, right, bottom, left);
	}
	
	private void repaint() {
		imageView.setImage(null);
		double width = anchorPane.getWidth();
		double height = anchorPane.getHeight();
		System.out.println(width+"   "+height);
		if(width<10d||height<10d) {
			imageView.setImage(null);
			return;

		}
		if(tsdProperty.get()==null) {
			return;
		}
		try {
			BufferedImage bufferedImage = new BufferedImage((int)width,(int)height,java.awt.image.BufferedImage.TYPE_INT_RGB);
			Graphics2D gc = bufferedImage.createGraphics();
			gc.setBackground(new java.awt.Color(255, 255, 255));
			gc.setColor(new java.awt.Color(0, 0, 0));
			gc.clearRect(0, 0, bufferedImage.getWidth(), bufferedImage.getHeight());
			gc.dispose();
			TimeSeriesPainterGraphics2D tsp = new TimeSeriesPainterGraphics2D(bufferedImage);
			tsdProperty.get().draw(tsp);
			WritableImage image = SwingFXUtils.toFXImage(bufferedImage, null);
			imageView.setImage(image);
		} catch (Exception e) {
			e.printStackTrace();
		}		
	}

	private void setRegions() {
		ObservableList<Region> regionList = FXCollections.observableArrayList();
		try {
			Region[] regions = tsdb.getRegions();
			regionList.add(regionAll);
			regionList.addAll(regions);
		} catch (RemoteException e) {
			log.error(e);
		}

		comboRegion.setItems(regionList);
		comboRegion.setValue(regionAll);		
	}

	private void onRegionChanged(ObservableValue<? extends Region> observable, Region oldValue, Region region) {
		ObservableList<GeneralStationInfo> generalStationList = FXCollections.observableArrayList();

		try {
			GeneralStationInfo[] g = tsdb.getGeneralStations();
			if(region==null||region.name.equals("[all]")) {
				generalStationList.add(GeneralStationAll);
				generalStationList.addAll(g);
			} else {
				for(GeneralStationInfo s:g) {
					if(s.region.name.equals(region.name)) {
						generalStationList.add(s);
					}
				}
			}
		} catch (Exception e) {
			log.error(e);
		}



		comboGeneralStation.setItems(generalStationList);
		comboGeneralStation.setValue(GeneralStationAll);
	}

	private void onGeneralStationChanged(ObservableValue<? extends GeneralStationInfo> observable, GeneralStationInfo oldValue, GeneralStationInfo general) {
		ObservableList<PlotInfo> plotList = FXCollections.observableArrayList();
		try {
			PlotInfo[] plotInfos = tsdb.getPlots();
			if(general==null||general.name.equals("[all]")) {
				Region region = comboRegion.getValue();
				if(region==null||region.name.equals("[all]")) {
					plotList.addAll(plotInfos);
				} else {
					for(PlotInfo plot:plotInfos) {
						if(plot.generalStationInfo.region.name.equals(region.name)) {
							plotList.add(plot);
						}
					}
				}
			} else {
				for(PlotInfo plot:plotInfos) {
					if(plot.generalStationInfo.name.equals(general.name)) {
						plotList.add(plot);
					}
				}
			}
		} catch (Exception e) {
			log.error(e);
		}
		comboPlot.setItems(plotList);
		if(plotList.isEmpty()) {
			comboPlot.setValue(null);
		} else {
			comboPlot.setValue(plotList.get(0));
		}
	}

	private void onUpdateTimestampSeries() {
		TimeSeriesDiagram  tsd = null;

		PlotInfo plot = comboPlot.getValue();

		if(plot==null) {
			tsdProperty.setValue(null);
			return;
		}

		Sensor sensor = comboSensor.getValue();
		if(sensor==null) {
			tsdProperty.setValue(null);
			return;
		}

		try {			
			TimestampSeries ts = tsdb.plot(null, plot.name, new String[]{sensor.name}, AggregationInterval.HOUR, DataQuality.STEP, false, null, null);
			if(ts!=null) {
				tsd = new TimeSeriesDiagram(ts,AggregationInterval.HOUR,SensorCategory.TEMPERATURE);
			}
		} catch (Exception e) {
			log.error(e);
		}

		tsdProperty.setValue(tsd);
	}

	private void onPlotChanged(ObservableValue<? extends PlotInfo> observable, PlotInfo oldValue, PlotInfo plot) {
		ObservableList<Sensor> sensorList = FXCollections.observableArrayList();

		try {
			Sensor[] sensors = tsdb.getSensors();
			Map<String,Sensor> sensorMap = new HashMap<String,Sensor>();
			for(Sensor sensor:sensors) {
				sensorMap.put(sensor.name, sensor);
			}
			String[] sensorNames = tsdb.getSensorNamesOfPlot(plot.name);
			for(String sensorName:sensorNames) {
				Sensor sensor = sensorMap.get(sensorName);
				if(sensor.isAggregable()) {
					sensorList.addAll(sensor);
				}
			}			
		} catch (Exception e) {
			log.error(e);
		}

		comboSensor.setItems(sensorList);
		if(sensorList.isEmpty()) {
			comboSensor.setValue(null);
		} else {
			comboSensor.setValue(sensorList.get(0));
		}

		onUpdateTimestampSeries();
	}

	private void onSensorChanged(ObservableValue<? extends Sensor> observable, Sensor oldValue, Sensor sensor) {
		onUpdateTimestampSeries();
	}

	private void onMousePressed(MouseEvent event) {
		mouseStartMovePos  = event.getX();
	}

	private void onMouseDragged(MouseEvent event) {
		double currentMovePos = event.getX();

		TimeSeriesDiagram tsd = tsdProperty.getValue();
		long timestampOffset = tsd.calcTimestamp((float) (currentMovePos-mouseStartMovePos))-tsd.calcTimestamp(0f);;
		System.out.println("MouseDragged "+(currentMovePos-mouseStartMovePos)+"    "+timestampOffset+"   "+TimeConverter.oleMinutesToText(timestampOffset));
		mouseStartMovePos = currentMovePos;
		float prevDiagramMin = tsd.getDiagramMinTimestamp();
		float prevDiagramMax = tsd.getDiagramMaxTimestamp();
		long diagramMin = (long) (prevDiagramMin - timestampOffset);
		long diagramMax = (long) (prevDiagramMax - timestampOffset);
		long min = tsd.getDataMinTimestamp();
		long max = tsd.getDataMaxTimestamp();
		if(diagramMin<min) {
			long corr = min-diagramMin;
			diagramMin += corr;
			diagramMax += corr;
			if(diagramMax>max) {
				diagramMax = max;
			}
		} else if(diagramMax>max) {
			long corr = diagramMax-max;
			diagramMin -= corr;
			diagramMax -= corr;
			if(diagramMin<min) {
				diagramMin = min;
			}
		}

		tsd.setDiagramTimestampRange(diagramMin, diagramMax);
		repaint();		
	}

	private void onScroll(ScrollEvent event) {
		TimeSeriesDiagram tsd = tsdProperty.getValue();

		double zoom = event.getDeltaY();
		if(zoom<0) {
			zoomFactor*=1.25;	
		} else {				
			zoomFactor/=1.25;
			if(zoomFactor<1) {
				zoomFactor = 1;
			}
		}

		long min = tsd.getDataMinTimestamp();
		long max = tsd.getDataMaxTimestamp();
		float prevDiagramMin = tsd.getDiagramMinTimestamp();
		float prevDiagramMax = tsd.getDiagramMaxTimestamp();
		long posTimestamp = tsd.calcTimestamp((float) event.getSceneX());
		if(posTimestamp<min) {
			posTimestamp = min;
		}
		if(posTimestamp>max) {
			posTimestamp = max;
		}

		float rangeFactor = ((float)(posTimestamp-prevDiagramMin))/((float)(prevDiagramMax-prevDiagramMin));

		long zoomedTimestampRange = (long) ((max-min)/zoomFactor);
		float zoomedMin = posTimestamp - zoomedTimestampRange*(rangeFactor);
		float zoomedMax = zoomedMin+zoomedTimestampRange;
		
		if(zoomedMin<min) {
			zoomedMin = min;
		}
		if(zoomedMax>max) {
			zoomedMax = max;
		}

		tsd.setDiagramTimestampRange(zoomedMin, zoomedMax);

		repaint();
	}

	@Override
	protected void onShown() {
		setRegions();
	}
}
