package tsdb.testing;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.Spliterator;
import java.util.function.Consumer;

public class IteratorPerformance {

	static class Ac implements Consumer<Integer> {
		public int sum = 0;
		@Override
		public void accept(Integer t) {
			sum += t;				
		}			
	}

	public static void main(String[] args) {
		LinkedList<Integer> a = new LinkedList<Integer>();

		for(int i=0;i<10000000;i++) {
			a.add(i*10+i%99);
		}

		Ac action = new Ac(); 
		
		int sum = 0;

		long time_start = System.currentTimeMillis();
		for(int i=0;i<100;i++) {
			Spliterator<Integer> spit = a.spliterator();		
			spit.forEachRemaining(action);

			/*for(Integer v:a) {
				action.sum += v;
			}*/
			
			/*Iterator<Integer> it = a.iterator();
			while(it.hasNext()) {
				action.sum += it.next();
			}*/
		}
		
		
		
		
		long time_end = System.currentTimeMillis();




		System.out.println(action.sum+"  "+sum);
		System.out.println((time_end-time_start)+" ms");

	}

}
