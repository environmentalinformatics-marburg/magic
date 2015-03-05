package tsdb.explorer;

import javafx.application.Application;
import javafx.beans.property.SimpleStringProperty;
import javafx.beans.property.StringProperty;
import javafx.geometry.Pos;
import javafx.scene.Parent;
import javafx.scene.control.Button;
import javafx.scene.control.Label;
import javafx.scene.layout.BorderPane;
import javafx.scene.layout.FlowPane;
import javafx.stage.Stage;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import tsdb.TsDBFactory;
import tsdb.explorer.metadata.MetadataScene;
import tsdb.remote.RemoteTsDB;

public class Explorer extends Application {



	public static String ESCAPE = ""+(char)27;

	private static final Logger log = LogManager.getLogger();

	@Override
	public void start(Stage primaryStage) {
		
		//log.info("java.awt.headless: "+System.getProperty("java.awt.headless"));
		System.setProperty("java.awt.headless", "true");
		//log.info("java.awt.headless: "+System.getProperty("java.awt.headless"));
		
		StringProperty connectionTextProperty = new SimpleStringProperty();

		RemoteTsDB tsdb = TsDBFactory.createDefaultServer(); connectionTextProperty.set("local direct connection to db");
		//RemoteTsDB tsdb = TsDBFactory.createRemoteConnection("137.248.191.180"); connectionTextProperty.set("local rmi connection to db");
		//RemoteTsDB tsdb = TsDBFactory.createRemoteConnection(); connectionTextProperty.set("remote rmi connection to db (183er)");
		//RemoteTsDB tsdb = TsDBFactory.createRemoteConnection("137.248.191.241"); connectionTextProperty.set("remote rmi connection to db (lab)");

		if(tsdb==null) {
			log.error("no connection");
			connectionTextProperty.set("error no connection to db");
		}

		//final String cText = connectionText;
		new TsdbScene(primaryStage,"Time Series Explorer") {			
			@Override
			protected Parent createContent() {
				stage.setMaximized(false);
				FlowPane hboxMain = new FlowPane(10,10);
				hboxMain.setAlignment(Pos.CENTER);

				if(tsdb!=null) {
					Button buttonSourceCatalog = new Button("source catalog");
					hboxMain.getChildren().add(buttonSourceCatalog);
					buttonSourceCatalog.setOnAction(e->new SourceCatalogScene(tsdb).show());

					Button buttonTimeSeriesView = new Button("time series view");
					hboxMain.getChildren().add(buttonTimeSeriesView);
					buttonTimeSeriesView.setOnAction(e->new TimeSeriesViewScene(tsdb).show());
					
					Button buttonTimeSeriesMultiView = new Button("time series multi view");
					hboxMain.getChildren().add(buttonTimeSeriesMultiView);
					buttonTimeSeriesMultiView.setOnAction(e->new TimeSeriesMultiViewScene(tsdb).show());
					
					Button buttonMetadataView = new Button("metadata view");
					hboxMain.getChildren().add(buttonMetadataView);
					buttonMetadataView.setOnAction(e->new MetadataScene(tsdb).show());
				}

				BorderPane borderPane = new BorderPane();
				//VBox vbox = new VBox(hboxMain);
				borderPane.setCenter(hboxMain);
				
				Label labelConnection = new Label();
				labelConnection.textProperty().bind(connectionTextProperty);
				labelConnection.setStyle("-fx-border-color: gray;");
				
				borderPane.setTop(labelConnection);
				return borderPane;
			}
		}.show();
	}

	/**
	 * @param args the command line arguments
	 */
	public static void main(String[] args) {
		launch(args);
	}
}
