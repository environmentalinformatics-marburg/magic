package processinggraph;

@FunctionalInterface
public interface NodeFunc {	
	public Node build(String stationName, String[] schema);
}
