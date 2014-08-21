package processinggraph;

@FunctionalInterface
public interface ContinuousGen {	
	public Continuous_temp get(String stationName, String[] schema);
}
