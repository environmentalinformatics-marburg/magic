package tsdb.util;

public class ProcessingChainTitle implements ProcessingChainEntry {
	
	public final String title;
	
	public ProcessingChainTitle(String title) {
		this.title = title;
	}

	@Override
	public String getProcessingTitle() {
		return title;
	}
	
	@Override
	public String toString() {
		return getProcessingTitle();
	}

}
