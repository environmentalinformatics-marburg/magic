package tsdb.graph;

@FunctionalInterface
public interface ContinuousGen {	
	public Continuous get(String stationName, String[] schema);
}
