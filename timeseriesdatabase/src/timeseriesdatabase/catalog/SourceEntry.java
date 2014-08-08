package timeseriesdatabase.catalog;

import java.io.Serializable;
import java.nio.file.Path;

import timeseriesdatabase.TimeConverter;

public class SourceEntry implements Serializable {
	private static final long serialVersionUID = 8603819733815550502L;
	
	public final String path;
	public final String filename;	
	public long firstTimestamp;
	public long lastTimestamp;	
	public final String stationName;
	public final int rows;
	public final String[] headerNames;
	public final String[] sensorNames;
	public final int timeStep;
	
	
	public SourceEntry(Path filename, String stationName, long firstTimestamp, long lastTimestamp, int rows, String[] headerNames, String[] sensorNames, int timeStep) {
		this.path = filename.subpath(0, filename.getNameCount()-1).toString();
		this.filename = filename.getFileName().toString();
		this.stationName = stationName;
		this.firstTimestamp = firstTimestamp;
		this.lastTimestamp = lastTimestamp;
		this.rows = rows;
		this.headerNames = headerNames;
		this.sensorNames = sensorNames;
		this.timeStep = timeStep;
	}
	
	@Override
	public String toString() {
		return filename+"\t"+stationName+"\t"+TimeConverter.oleMinutesToText(firstTimestamp)+"\t"+TimeConverter.oleMinutesToText(lastTimestamp);
	}

}
