package tsdb.testing;

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.util.Iterator;

import de.umr.eventstore.Stream;
import de.umr.eventstore.storage.validation.Action;
import de.umr.eventstore.storage.validation.Actions;
import de.umr.eventstore.storage.validation.CheckConstraint;
import de.umr.eventstore.storage.validation.CompoundAction;
import de.umr.eventstore.storage.validation.Constraint;
import de.umr.eventstore.storage.validation.Constraint.CheckMode;
import de.umr.eventstore.storage.validation.ConstraintPredicate;
import de.umr.eventstore.storage.validation.Equal;
import de.umr.eventstore.storage.validation.Not;
import de.umr.eventstore.storage.validation.UniqueConstraint;
import de.umr.eventstore.storage.validation.Variable;
import de.umr.jepc.Attribute;
import de.umr.jepc.Attribute.DataType;
import de.umr.jepc.store.Event;
import de.umr.jepc.store.btree.TimeSplitBTreeEventStore;
import de.umr.jepc.util.Timer;
import de.umr.jepc.util.enums.TimeRepresentation;

public class TestingUniqueConstraint {

	public static void main(String[] args) throws FileNotFoundException, InterruptedException {
		String databaseDirectory = "c:/TestingUniqueConstraint/";
		String configDirectory = databaseDirectory;

		FileInputStream configStream = new FileInputStream(configDirectory+"eventstore_config.properties");
		TimeSplitBTreeEventStore store = new TimeSplitBTreeEventStore(TimeRepresentation.POINT,databaseDirectory,configStream);		
		try {
			store.open();
			store.clear();
		} catch (Exception e) {
			System.out.println(e);
		}
		store.open();


		final String STREAM1_NAME= "stream1";
		Attribute[] schema = new Attribute[3];
		schema[0] = new Attribute("a0",DataType.FLOAT);
		schema[1] = new Attribute("a1",DataType.FLOAT);
		schema[2] = new Attribute("a2",DataType.FLOAT);
		store.registerStream(STREAM1_NAME,schema);

		Stream stream1 = store.getStream(STREAM1_NAME);

		
		Constraint constraint = new UniqueTimestampConstraint(store, STREAM1_NAME);		
		//stream1.getSchema().addConstraint(constraint);
		


		/*
		String constraintName = "timestamp_unique_constraint";
		//Action action = new CompoundAction(Actions.PRINT_ACTION,Actions.DISCARD_ACTION);
		Action action = Actions.DISCARD_ACTION;
		String checkAttribute = "tstart";
		//String checkAttribute = "a0";
		UniqueConstraint constraint = new UniqueConstraint(constraintName,stream1,action,checkAttribute);
		stream1.getSchema().addConstraint(constraint);
		*/  

		/*
		String constraintName = "simple_check_constraint";
		ConstraintPredicate predicate = new Not(new Equal(new Variable("a0"),new Variable("a1")));
		//ConstraintPredicate predicate = new Not(new Equal(new Variable("a0"),new Variable("a0")));
		//Action action = Actions.DISCARD_ACTION;
		Action action =  new CompoundAction(Actions.PRINT_ACTION, Actions.DISCARD_ACTION);
		CheckMode checkMode = CheckConstraint.CheckMode.IMMEDIATELY;
		CheckConstraint constraint = new CheckConstraint(constraintName,predicate,action,checkMode);
		stream1.getSchema().addConstraint(constraint);
		 */


		Timer timer = new Timer();

		final String PUSH="push";

		timer.start(PUSH);

		//final int EVENT_COUNT = 1000000;
		//final int EVENT_COUNT = 26;
		final int EVENT_COUNT = 1000;
		for(int i=0;i<EVENT_COUNT;i++) {

			Object[] payload = new Float[]{1.001f+i*7,2.002f*11+i,3.003f+i*23};
			long timestamp = i;
			//System.out.println("push\t"+STREAM1_NAME+"\t"+timestamp);
			store.pushEvent(STREAM1_NAME,payload, timestamp+123456789);
		}

		timer.stop(PUSH);

		timer.printTime(PUSH);
		System.out.println("EVENT_COUNT: "+EVENT_COUNT);

		store.flushStream(STREAM1_NAME);



		store.close();

		System.out.println("TotalEventCount: "+store.getTotalEventCount());

		store.open();

		Iterator<Event> it = store.getHistory(STREAM1_NAME);

		final String QUERY="query";

		timer.start(QUERY);

		long resultCount = 0;
		while(it.hasNext()) {
			Event next = it.next();
			//System.out.println(next.getTimestamp()/*-123456789*/);
			resultCount++;
		}

		timer.stop(QUERY);		

		timer.printTime(QUERY);
		System.out.println("resultCount: "+resultCount);

		store.close();


	}

}
