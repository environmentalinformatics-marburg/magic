package tsdb.streamdb;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Iterator;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.mapdb.BTreeMap;

import tsdb.streamdb.SensorMeta.ChunkMetaEntry;

public class StreamIterator implements Iterator<DataEntry> {
	
	private static final Logger log = LogManager.getLogger();

	private final BTreeMap<Integer, DataEntry[]> sensorChunkMap;
	public final int minTimestamp;
	public final int maxTimestamp;
	
	public final String stationName;
	public final String sensorName;

	private final Iterator<ChunkMetaEntry> chunkListIterator;
	private Iterator<DataEntry> dataEntryIterator;

	public StreamIterator(SensorMeta sensorMeta, BTreeMap<Integer, DataEntry[]> sensorChunkMap, int minTimestamp, int maxTimestamp) {
		this.sensorChunkMap = sensorChunkMap;
		this.stationName = sensorMeta.stationName;
		this.sensorName = sensorMeta.name;
		this.minTimestamp = minTimestamp;
		this.maxTimestamp = maxTimestamp;
		ArrayList<ChunkMetaEntry> list = new ArrayList<ChunkMetaEntry>();		
		for(ChunkMetaEntry entry:sensorMeta.list) {
			if(minTimestamp <= entry.lastTimestamp && entry.firstTimestamp <= maxTimestamp) {
				list.add(entry);
			}
		}
		
		this.chunkListIterator = list.iterator();
		if(chunkListIterator.hasNext()) {
			nextChunk();
		} else {
			this.dataEntryIterator = Collections.emptyIterator();
		}

	}

	private void nextChunk() {
		ChunkMetaEntry chunkEntry = chunkListIterator.next();
		DataEntry[] chunk = sensorChunkMap.get(chunkEntry.firstTimestamp);
		if(minTimestamp<=chunkEntry.firstTimestamp) {
			if(chunkEntry.lastTimestamp<=maxTimestamp) {
				dataEntryIterator = new SimpleIterator(chunk);
			} else {
				dataEntryIterator = new ClipIterator(chunk,minTimestamp,maxTimestamp);
			}
		} else {
			if(chunkEntry.lastTimestamp<=maxTimestamp) {
				dataEntryIterator = new SimpleIterator(chunk,minTimestamp);
			} else {
				dataEntryIterator = new ClipIterator(chunk,minTimestamp,maxTimestamp);
			}
		}
	}

	@Override
	public boolean hasNext() {
		while(!dataEntryIterator.hasNext()) {
			if(!chunkListIterator.hasNext()) {
				return false;
			}
			nextChunk();
		}
		return true;
	}

	@Override
	public DataEntry next() {
		return dataEntryIterator.next();
	}
	
	private static class SimpleIterator implements Iterator<DataEntry> {		
		private final DataEntry[] chunk;
		private int currentPos;		
		public SimpleIterator(DataEntry[] chunk) {
			this.chunk = chunk;
			this.currentPos = 0;
		}
		public SimpleIterator(DataEntry[] chunk, int minTimestamp) {
			this.chunk = chunk;
			this.currentPos = 0;
			while(currentPos!=chunk.length&&chunk[currentPos].timestamp<minTimestamp) {
				currentPos++;
			}
		}
		@Override
		public boolean hasNext() {
			return currentPos!=chunk.length;
		}
		@Override
		public DataEntry next() {
			return chunk[currentPos++];
		}		
	}
	
	private static class ClipIterator implements Iterator<DataEntry> {		
		private final DataEntry[] chunk;
		private final int maxTimestamp;
		private int currentPos;		
		public ClipIterator(DataEntry[] chunk, int minTimestamp, int maxTimestamp) {
			this.chunk = chunk;
			this.maxTimestamp = maxTimestamp;
			this.currentPos = 0;
			while(currentPos!=chunk.length&&chunk[currentPos].timestamp<minTimestamp) {
				currentPos++;
			}
		}
		@Override
		public boolean hasNext() {
			return currentPos!=chunk.length&&chunk[currentPos].timestamp<=maxTimestamp;
		}
		@Override
		public DataEntry next() {
			return chunk[currentPos++];
		}		
	}
}
