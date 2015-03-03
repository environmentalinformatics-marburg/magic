package tsdb;

import java.io.DataInput;
import java.io.IOException;

import tsdb.raw.TimestampSeries;
import tsdb.streamdb.DataEntry;

public class TimeSeriesArchivReader {

	public static enum EntryType {
		TIMESTAMPSERIES,
		DATAENTRYARRAY,
		END 
	}

	private DataInput in;

	private boolean open = false;
	
	private EntryType currentEntryType = null;

	public TimeSeriesArchivReader(DataInput in) {
		this.in = in;
	}

	public void open() throws IOException {
		if(in==null) {
			throw new RuntimeException("no data source");
		}
		if(open) {
			in = null;
			throw new RuntimeException("already open");
		}

		String toc_head = in.readUTF();
		if(!toc_head.equals(TimeSeriesArchivWriter.TOC_HEAD)) {
			in = null;
			throw new RuntimeException("file format error");
		}

		String toc_start = in.readUTF();
		if(!toc_start.equals(TimeSeriesArchivWriter.TOC_START)) {
			in = null;
			throw new RuntimeException("file format error");
		}

		open = true;
	}

	private EntryType readNextEntryType() throws IOException {
		if(!open) {
			in = null;
			throw new RuntimeException("not open");
		}
		String entry = in.readUTF();
		if(entry.equals(TimeSeriesArchivWriter.TOC_END)) {
			return EntryType.END;
		}
		if(!entry.equals(TimeSeriesArchivWriter.TOC_ENTRY)) {
			in = null;
			open = false;
			throw new RuntimeException("file format error");
		}
		String type = in.readUTF();
		switch(type) {
		case TimeSeriesArchivWriter.TOC_TYPE_TIMESTAMPSERIES:
			return EntryType.TIMESTAMPSERIES;
		case TimeSeriesArchivWriter.TOC_TYPE_DATAENTRYARRAY:
			return EntryType.DATAENTRYARRAY;
		default:
			in = null;
			open = false;
			throw new RuntimeException("file format error");
		}
	}
	
	public EntryType getNextEntryType() throws IOException {
		if(currentEntryType!=null) {
			in = null;
			open = false;
			throw new RuntimeException("file format error");
		}
		EntryType e = readNextEntryType();
		currentEntryType = e;
		return e;
	}
	
	public TimestampSeries getTimestampSeries() throws IOException {
		if(!open) {
			in = null;
			throw new RuntimeException("not open");
		}
		if(currentEntryType!=EntryType.TIMESTAMPSERIES) {
			throw new RuntimeException("wrong type");
		}
		return TimestampSeries.TIMESERIESARCHIV_SERIALIZER.deserialize(in, -1);
	}
	
	public DataEntry[] getDataEntryArray() throws IOException {
		if(!open) {
			in = null;
			throw new RuntimeException("not open");
		}
		if(currentEntryType!=EntryType.DATAENTRYARRAY) {
			throw new RuntimeException("wrong type");
		}
		return DataEntry.TIMESERIESARCHIV_SERIALIZER.deserialize(in, -1);
	}

	public void close() {
		in = null;
		open = false;
	}

}
