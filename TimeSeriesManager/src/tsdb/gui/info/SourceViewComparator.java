package tsdb.gui.info;

import org.eclipse.jface.viewers.Viewer;
import org.eclipse.jface.viewers.ViewerComparator;

import tsdb.catalog.SourceEntry;

public class SourceViewComparator extends ViewerComparator {
	
	public enum SortType {STATION_NAME,FILE_NAME,FIRST_TIMESTAMP,LAST_TIMESTAMP,ROW_COUNT,HEADER_NAMES,SENSOR_NAMES,TIME_STEP};
	
	public SortType sorttype = SortType.STATION_NAME;
	
	public boolean sortAsc = true;
	
	@Override
	public int compare(Viewer viewer, Object o1, Object o2) {
		SourceEntry e1 = (SourceEntry) o1;
		SourceEntry e2 = (SourceEntry) o2;
		int cmp = 0;
		switch(sorttype) {
		case FILE_NAME:
			cmp = e1.filename.compareTo(e2.filename);
			break;
		case FIRST_TIMESTAMP:
			cmp = Long.compare(e1.firstTimestamp, e2.firstTimestamp);
			break;
		case LAST_TIMESTAMP:
			cmp = Long.compare(e1.lastTimestamp, e2.lastTimestamp);
			break;
		case ROW_COUNT:
			cmp = Integer.compare(e1.rows, e2.rows);
			break;
		case HEADER_NAMES:
			cmp = 0;
			break;
		case SENSOR_NAMES:
			cmp = 0;
			break;
		case TIME_STEP:
			cmp = Integer.compare(e1.timeStep, e2.timeStep);
			break;
		default:
			cmp = e1.stationName.compareTo(e2.stationName);
			break;
		}
		if(sortAsc) {
			return cmp;
		} else {
			return -cmp;
		}
	}
}
