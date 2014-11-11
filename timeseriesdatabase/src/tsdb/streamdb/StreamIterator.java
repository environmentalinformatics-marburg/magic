package tsdb.streamdb;

import java.util.Collections;
import java.util.Iterator;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.mapdb.BTreeMap;

public class StreamIterator implements Iterator<DataEntry> {
	
	private static final Logger log = LogManager.getLogger();

	private final BTreeMap<Integer, Chunk> sensorChunkMap;
	public final int minTimestamp;
	public final int maxTimestamp;
	
	public final String stationName;
	public final String sensorName;

	private final Iterator<ChunkMeta> chunkMetaIterator;
	private Iterator<DataEntry> dataEntryIterator;

	public StreamIterator(SensorMeta sensorMeta, BTreeMap<Integer, ChunkMeta> chunkMetaMap, BTreeMap<Integer, Chunk> sensorChunkMap, int minTimestamp, int maxTimestamp) {
		this.sensorChunkMap = sensorChunkMap;
		this.stationName = sensorMeta.stationName;
		this.sensorName = sensorMeta.sensorName;
		this.minTimestamp = minTimestamp;
		this.maxTimestamp = maxTimestamp;
		this.chunkMetaIterator = ChunkMeta.createIterator(chunkMetaMap, minTimestamp, maxTimestamp);
		if(chunkMetaIterator.hasNext()) {
			nextChunk();
		} else {
			this.dataEntryIterator = Collections.emptyIterator();
		}
	}

	private void nextChunk() {
		ChunkMeta chunkMeta = chunkMetaIterator.next();
		Chunk chunk = sensorChunkMap.get(chunkMeta.firstTimestamp);
		if(minTimestamp<=chunkMeta.firstTimestamp) {
			if(chunkMeta.lastTimestamp<=maxTimestamp) {
				dataEntryIterator = new SimpleIterator(chunk.data);
			} else {
				dataEntryIterator = new ClipIterator(chunk.data,minTimestamp,maxTimestamp);
			}
		} else {
			if(chunkMeta.lastTimestamp<=maxTimestamp) {
				dataEntryIterator = new SimpleIterator(chunk.data,minTimestamp);
			} else {
				dataEntryIterator = new ClipIterator(chunk.data,minTimestamp,maxTimestamp);
			}
		}
	}

	@Override
	public boolean hasNext() {
		while(!dataEntryIterator.hasNext()) {
			if(!chunkMetaIterator.hasNext()) {
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
