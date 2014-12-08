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
import javafx.scene.layout.VBox;
import javafx.stage.Stage;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import tsdb.TsDBFactory;
import tsdb.remote.RemoteTsDB;

public class Explorer extends Application {



	public static String ESCAPE = ""+(char)27;

	private static final Logger log = LogManager.getLogger();

	@Override
	public void start(Stage primaryStage) {
		
		StringProperty connectionTextProperty = new SimpleStringProperty();

		RemoteTsDB tsdb = TsDBFactory.createDefaultServer(); connectionTextProperty.set("local direct connection to db");
		//RemoteTsDB tsdb = TsDBFactory.createRemoteConnection("137.248.191.180"); connectionTextProperty.set("local remote connection to db");
		//RemoteTsDB tsdb = TsDBFactory.createRemoteConnection(); connectionTextProperty.set("remote connection to db (183er)");
		//RemoteTsDB tsdb = TsDBFactory.createRemoteConnection("137.248.191.241"); connectionTextProperty.set("remote connection to db (lab)");

		if(tsdb==null) {
			log.error("no connection");
			connectionTextProperty.set("error no connection to db");
			//connectionText = "Error: no connection to db";
			//primaryStage.show();
			//primaryStage.close();
			//return;
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
				}

				BorderPane borderPane = new BorderPane();
				VBox vbox = new VBox(hboxMain);
				borderPane.setCenter(hboxMain);
				
				Label labelConnection = new Label();
				labelConnection.textProperty().bind(connectionTextProperty);
				labelConnection.setStyle("-fx-border-color: gray;");
				
				borderPane.setTop(labelConnection);
				return borderPane;
			}
		}.show();





		/*FlowPane hboxMain = new FlowPane();

		Button buttonSourceCatalog = new Button("source catalog");
		hboxMain.getChildren().add(buttonSourceCatalog);
		buttonSourceCatalog.setOnAction(e->new SourceCatalogSceneNew(tsdb).show());

		Button buttonTimeSeriesView = new Button("time series view");
		hboxMain.getChildren().add(buttonTimeSeriesView);
		buttonTimeSeriesView.setOnAction(e->new TimeSeriesViewSceneNew(tsdb).show());

		BorderPane borderPane = new BorderPane();
		borderPane.setCenter(hboxMain);

		Scene scene = new Scene(borderPane);

		scene.setOnKeyTyped(value->{			
			if(value.getCharacter().equals(ESCAPE)) {
				primaryStage.close();
			}
		});

		primaryStage.setTitle("Time Series Explorer");
		primaryStage.setScene(scene);
		//primaryStage.setMinWidth(300);
		primaryStage.setWidth(300);

		primaryStage.show();*/
	}

	/**
	 * @param args the command line arguments
	 */
	public static void main(String[] args) {
		launch(args);
	}
}
