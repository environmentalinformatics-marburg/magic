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
import javafx.scene.layout.BorderPane;
import javafx.scene.layout.HBox;
import javafx.scene.layout.VBox;
import javafx.scene.paint.Color;
import javafx.scene.text.FontSmoothingType;
import javafx.stage.Modality;
import javafx.stage.Stage;
import javafx.stage.StageStyle;

public class Explorer extends Application {
	
	private static final Logger log = LogManager.getLogger();

	@Override
	public void start(Stage primaryStage) {

		RemoteTsDB tsdb = TsDBFactory.createDefaultServer();

		VBox vboxMain = new VBox();

		Button button = new Button("source catalog");
		vboxMain.getChildren().add(button);
		button.setOnAction(e->{
			Scene subScene = new SourceCatalogScene(tsdb).getScene();
			if(subScene!=null) {
				Stage subStage = new Stage(StageStyle.DECORATED);
				subStage.initModality(Modality.APPLICATION_MODAL);
				subStage.setTitle("source catalog");
				subStage.setScene(subScene);
				subStage.show();
			}
		});


		BorderPane borderPane = new BorderPane();
		borderPane.setCenter(vboxMain);

		Scene scene = new Scene(borderPane);

		primaryStage.setTitle("TsDB Explorer");
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
