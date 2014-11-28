package tsdb.explorer;



import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.scene.canvas.Canvas;
import javafx.scene.layout.BorderPane;
import javafx.util.Callback;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import tsdb.remote.RemoteTsDB;

public class TimeSeriesViewScene {
	
	private static String ESCAPE = ""+(char)27;
	
	private static final Logger log = LogManager.getLogger();
	
	private final RemoteTsDB tsdb;
	
	private Scene scene;
	
	public TimeSeriesViewScene(RemoteTsDB tsdb) {
		this.tsdb = tsdb;
		
		Canvas canvas = new Canvas();
		
		BorderPane mainBoderPane = new BorderPane();
		mainBoderPane.setCenter(canvas);
		this.scene = new Scene(mainBoderPane, 400, 400);
	}
	
	public void setOnClose(Callback<Boolean,Boolean> cb) {
		scene.setOnKeyTyped(value->{			
			if(value.getCharacter().equals(ESCAPE)) {
				cb.call(true);
			}
		});
	}
	
	public Scene getScene() {
		return scene;
	}

}
