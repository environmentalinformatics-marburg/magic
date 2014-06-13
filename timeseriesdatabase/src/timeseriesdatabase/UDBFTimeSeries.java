package timeseriesdatabase;

import java.nio.file.Path;

/**
 * UDBFTimeSeries contains relevant data of a UDBF-File.
 * @author Stephan Wöllauer
 *
 */
public class UDBFTimeSeries {
	
	public final Path filename;
	public final SensorHeader[] sensorHeaders;
	public final TimeConverter timeConverter;
	public final long[] time;
	public final float[][] data;

	public UDBFTimeSeries(Path filename, SensorHeader[] sensorHeaders, TimeConverter timeConverter, long[] time, float[][] data) {
		this.filename = filename;
		this.sensorHeaders = sensorHeaders;
		this.timeConverter = timeConverter;
		this.time = time;
		this.data = data;
	}

}
