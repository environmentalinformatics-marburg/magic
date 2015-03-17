package tsdb.util.iterator;

import java.io.DataOutput;
import java.io.IOException;

import tsdb.util.DataEntry;

public class TimeSeriesArchivWriter {

	final static String TOC_HEAD = "Time_Series_Archiv_v_1_0_0";

	final static String TOC_START = "TimeSeriesArchiv:start";
	final static String TOC_END = "TimeSeriesArchiv:end";
	
	final static String TOC_ENTRY = "Entry";
	
	final static String TOC_TYPE_TIMESTAMPSERIES = "TimestampSeries";
	final static String TOC_TYPE_DATAENTRYARRAY = "DataEntryArray";

	private DataOutput out;

	private boolean open = false;

	public TimeSeriesArchivWriter(DataOutput out) {
		this.out = out;
	}

	public void open() throws IOException {
		if(out==null) {
			throw new RuntimeException("no data target");
		}
		if(open) {
			out = null;
			throw new RuntimeException("already open");
		}
		out.writeUTF(TOC_HEAD);
		out.writeUTF(TOC_START);
		open = true;
	}

	public void close() throws IOException {
		if(!open) {
			throw new RuntimeException("already closed");
		}
		open = false;
		out.writeUTF(TOC_END);
		out = null;
	}
	
	private void writeEntry(String typeName) throws IOException {
		if(!open) {
			throw new RuntimeException("not open");
		}
		out.writeUTF(TOC_ENTRY);
		out.writeUTF(typeName);
	}
	
	public void writeTimestampSeries(TimestampSeries timestampSeries) throws IOException {
		if(!open) {
			throw new RuntimeException("not open");
		}
		writeEntry(TOC_TYPE_TIMESTAMPSERIES);
		TimestampSeries.TIMESERIESARCHIV_SERIALIZER.serialize(out, timestampSeries);
	}
	
	public void writeDataEntryArray(String stationName, String sensorName, DataEntry[] dataEntries) throws IOException {
		if(!open) {
			throw new RuntimeException("not open");
		}
		writeEntry(TOC_TYPE_DATAENTRYARRAY);
		out.writeUTF(stationName);
		out.writeUTF(sensorName);
		DataEntry.TIMESERIESARCHIV_SERIALIZER.serialize(out, dataEntries);
	}
}
