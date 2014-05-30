package dat_decode;

import java.io.FileNotFoundException;
import java.io.PrintStream;
import java.util.Locale;

/**
 * Collection of all sensor of one location.
 * @author Wöllauer
 *
 */
public class SensorData {
	
	private TimeConverter timeConverter;
	private Sensor[] sensors;
	private int badRowCount;
	
	public SensorData(TimeConverter timeConverter, SensorHeader[] sensorHeaders, float[][] data, int badRowCount) {
		this.timeConverter = timeConverter;
		sensors = new Sensor[sensorHeaders.length];
		for(int i=0;i<sensors.length;i++) {
			float[] col = new float[data.length];
			for(int r=0;r<data.length;r++) {
				col[r] = data[r][i];
			}
			sensors[i] = new Sensor(timeConverter, sensorHeaders[i],col);
		}
		this.badRowCount = badRowCount;
	}
	
	public Sensor getSensor(int sensorID) {
		return sensors[sensorID];		
	}
	
	public TimeConverter getTimeConverter() {
		return timeConverter;
	}
	
	public int getSensorCount() {
		return sensors.length;
	}
	
	public String getSensorNames() {
		String s="";
		for(Sensor sensor:sensors) {
			s += sensor.getSensorName()+" ";
		}
		return s;
	}
	
	public int getBadRowCount() {
		return badRowCount;
	}
	
	public void writeTable(String filename) throws FileNotFoundException {
		
		Locale locale = Locale.ENGLISH;
		
		PrintStream printStream = new PrintStream(filename);
		
		int rowcount = sensors[0].getSampleCount();
		
		/*
		
		for(int r=0;r<rowcount;r++) {
			printStream.print(r);
			
			for(int c=0;c<10;c++) {
				printStream.format(locale,";%2.2f", sensors[c].data[r]);
			}
			
			printStream.println();
			
		}
		
		*/
		
		printStream.print("OFFSET");
		printStream.print(" TIMESTAMP");
		for(int c=0;c<sensors.length;c++) {
			printStream.print(" "+sensors[c].getSensorName());
		}
		printStream.println();
		
		
		for(int r=0;r<rowcount;r++) {
			printStream.print(r);
			printStream.print(" "+timeConverter.offsetToDateTime(r));
			
			for(int c=0;c<sensors.length;c++) {
				printStream.format(locale," %2.2f", sensors[c].data[r]);
			}
			
			printStream.println();
			
		}
		
		
		
		
		
		printStream.close();
	}
	
	

}
