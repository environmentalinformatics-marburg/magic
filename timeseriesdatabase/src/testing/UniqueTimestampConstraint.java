package testing;

import java.util.Iterator;

import de.umr.eventstore.Stream;
import de.umr.eventstore.queries.QueryResult;
import de.umr.eventstore.queries.SQLQuery;
import de.umr.eventstore.storage.Schema;
import de.umr.eventstore.storage.validation.Constraint;
import de.umr.eventstore.storage.validation.UniqueConstraint;
import de.umr.jepc.Attribute;
import de.umr.jepc.store.Event;
import de.umr.jepc.store.btree.TimeSplitBTreeEventStore;

public class UniqueTimestampConstraint extends Constraint {
	
	private final TimeSplitBTreeEventStore store;
	private final String streamName;

	public UniqueTimestampConstraint(TimeSplitBTreeEventStore store, String streamName) {
		super("UniqueTimestampConstraint", CheckMode.IMMEDIATELY);
		this.store = store;
		this.streamName = streamName;
	}

	@Override
	public boolean evaluate(Object[] event, Schema schema) {		
		long timestamp = (long) event[event.length-1];		
		Iterator<Event> it = store.getHistoryPoint(streamName, timestamp);
		return !it.hasNext();		
	}
}
