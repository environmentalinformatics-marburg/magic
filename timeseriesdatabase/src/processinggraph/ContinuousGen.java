package processinggraph;

@FunctionalInterface
public interface ContinuousGen {	
	public Continuous get(String stationName, String[] schema);
}
