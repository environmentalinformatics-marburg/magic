package tsdb.streamdb;

import java.util.ArrayList;
import java.util.Iterator;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.mapdb.BTreeMap;

import tsdb.streamdb.SensorMeta.ChunkMetaEntry;

public class StreamIterator implements Iterator<DataEntry> {
	
	private static final Logger log = LogManager.getLogger();

	private final BTreeMap<Integer, ArrayList<DataEntry>> sensorChunkMap;
	public final int minTimestamp;
	public final int maxTimestamp;
	
	public final String stationName;
	public final String sensorName;

	private final Iterator<ChunkMetaEntry> chunkListIterator;
	private Iterator<DataEntry> dataEntryIterator;

	public StreamIterator(SensorMeta sensorMeta, BTreeMap<Integer, ArrayList<DataEntry>> sensorChunkMap, int minTimestamp, int maxTimestamp) {
		this.sensorChunkMap = sensorChunkMap;
		this.stationName = sensorMeta.stationName;
		this.sensorName = sensorMeta.name;
		this.minTimestamp = minTimestamp;
		this.maxTimestamp = maxTimestamp;
		ArrayList<ChunkMetaEntry> list = new ArrayList<ChunkMetaEntry>();		
		for(ChunkMetaEntry entry:sensorMeta.list) {
			log.info("entry: "+entry.firstTimestamp+"  "+entry.lastTimestamp);
			if(minTimestamp <= entry.lastTimestamp && entry.firstTimestamp <= maxTimestamp) {
				list.add(entry);
			}
		}
		
		this.chunkListIterator = list.iterator();
		if(chunkListIterator.hasNext()) {
			nextChunk();
		} else {
			this.dataEntryIterator = new ArrayList<DataEntry>(0).iterator();
		}

	}

	private void nextChunk() {
		ChunkMetaEntry chunkEntry = chunkListIterator.next();
		ArrayList<DataEntry> dataEntryList = sensorChunkMap.get(chunkEntry.firstTimestamp);
		if(minTimestamp<=chunkEntry.firstTimestamp&&chunkEntry.lastTimestamp<=maxTimestamp) {
			dataEntryIterator = dataEntryList.iterator();
		} else {
			dataEntryIterator = new ClipIterator(dataEntryList.iterator(), minTimestamp, maxTimestamp);
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
	
	private static class ClipIterator implements Iterator<DataEntry> {		
		final Iterator<DataEntry> iterator;
		final int maxTimestamp;		
		DataEntry curr;		
		public ClipIterator(Iterator<DataEntry> iterator, int minTimestamp, int maxTimestamp) {
			this.iterator = iterator;
			this.maxTimestamp = maxTimestamp;
			while(iterator.hasNext()) {
				curr = iterator.next();
				if(curr.timestamp>=minTimestamp) {
					if(curr.timestamp<=maxTimestamp) {
						return;
					} else {
						curr = null;
						return;
					}
				}
			}
			curr = null;
		}
		@Override
		public boolean hasNext() {
			return curr!=null;
		}
		@Override
		public DataEntry next() {
			DataEntry r = curr;
			if(iterator.hasNext()) {
				curr = iterator.next();
				if(maxTimestamp<curr.timestamp) {
					curr = null;
				}
			}
			return r;
		}		
	}	
}
