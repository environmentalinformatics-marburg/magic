package tsdb.explorer;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import tsdb.TsDBFactory;
import tsdb.remote.RemoteTsDB;
import tsdb.remote.ServerTsDB;
import javafx.application.Application;
import javafx.beans.value.ChangeListener;
import javafx.event.ActionEvent;
import javafx.event.EventHandler;
import javafx.scene.Scene;
import javafx.scene.canvas.Canvas;
import javafx.scene.control.Button;
import javafx.scene.control.ScrollPane;
import javafx.scene.input.KeyCodeCombination;
import javafx.scene.layout.BorderPane;
import javafx.scene.layout.FlowPane;
import javafx.scene.layout.HBox;
import javafx.scene.layout.VBox;
import javafx.scene.paint.Color;
import javafx.scene.text.FontSmoothingType;
import javafx.stage.Modality;
import javafx.stage.Stage;
import javafx.stage.StageStyle;

public class Explorer extends Application {
	
	
	
	public static String ESCAPE = ""+(char)27;
	
	private static final Logger log = LogManager.getLogger();

	@Override
	public void start(Stage primaryStage) {

		//RemoteTsDB tsdb = TsDBFactory.createDefaultServer();
		RemoteTsDB tsdb = TsDBFactory.createRemoteConnection();
		//RemoteTsDB tsdb = TsDBFactory.createRemoteConnection("137.248.191.180");
		
		if(tsdb==null) {
			log.error("no connection");
			return;
		}

		FlowPane hboxMain = new FlowPane();

		Button buttonSourceCatalog = new Button("source catalog");
		hboxMain.getChildren().add(buttonSourceCatalog);
		buttonSourceCatalog.setOnAction(e->{
			SourceCatalogScene sourceCatalogScene = new SourceCatalogScene(tsdb);
			Scene subScene = sourceCatalogScene.getScene();
			if(subScene!=null) {
				Stage subStage = new Stage(StageStyle.DECORATED);
				subStage.initModality(Modality.APPLICATION_MODAL);
				subStage.setTitle("source catalog");
				subStage.setScene(subScene);
				subStage.show();
				sourceCatalogScene.setOnClose(x->{subStage.close();return true;});
				sourceCatalogScene.createData();
				subStage.setFullScreenExitKeyCombination(KeyCodeCombination.valueOf("F11"));
				subStage.setFullScreenExitHint("");
				//subStage.setFullScreen(true);
			}
		});
		
		Button buttonTimeSeriesView = new Button("time series view");
		hboxMain.getChildren().add(buttonTimeSeriesView);
		buttonTimeSeriesView.setOnAction(e->{
			TimeSeriesViewScene timeSeriesViewScene = new TimeSeriesViewScene(tsdb);
			Scene subScene = timeSeriesViewScene.getScene();
			if(subScene!=null) {
				Stage subStage = new Stage(StageStyle.DECORATED);
				subStage.initModality(Modality.APPLICATION_MODAL);
				subStage.setTitle("time series view");
				subStage.setScene(subScene);
				subStage.show();				
				timeSeriesViewScene.setOnClose(x->{subStage.close();return true;});
				subStage.setFullScreenExitKeyCombination(KeyCodeCombination.valueOf("F11"));
				subStage.setFullScreenExitHint("");
				subStage.setFullScreen(true);
				
			}
		});


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

		primaryStage.show();
		
		

	}

	/**
	 * @param args the command line arguments
	 */
	public static void main(String[] args) {
		launch(args);
	}
}
