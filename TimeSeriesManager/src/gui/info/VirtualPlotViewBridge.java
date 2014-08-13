package gui.info;

import org.eclipse.jface.viewers.ColumnLabelProvider;
import org.eclipse.jface.viewers.TableViewer;
import org.eclipse.jface.viewers.TableViewerColumn;
import org.eclipse.jface.viewers.Viewer;
import org.eclipse.jface.viewers.ViewerComparator;
import org.eclipse.swt.SWT;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;

import timeseriesdatabase.VirtualPlot;
import timeseriesdatabase.catalog.SourceEntry;

public class VirtualPlotViewBridge extends ViewerComparator {

	private TableViewer tableViewer;	

	public VirtualPlotViewBridge(TableViewer tableViewer) {
		this.tableViewer = tableViewer;
	}

	public int sortColumn = 0;

	public boolean sortAsc = true;

	@Override
	public int compare(Viewer viewer, Object o1, Object o2) {
		VirtualPlot e1 = (VirtualPlot) o1;
		VirtualPlot e2 = (VirtualPlot) o2;
		int cmp = 0;
		switch(sortColumn) {
		case 0:
			cmp = e1.plotID.compareTo(e2.plotID);
			break;
		case 1:
			cmp = e1.generalStation.longName.compareTo(e2.generalStation.longName);
			break;
		case 2:
			cmp = Integer.compare(e1.geoPosEasting,e2.geoPosEasting);
			break;
		case 3:
			cmp = Integer.compare(e1.geoPosNorthing,e2.geoPosNorthing);
			break;			
		case 4:
			cmp = Integer.compare(e1.intervalList.size(), e2.intervalList.size());
			break;
		default:
			cmp = 0;
			break;
		}
		if(sortAsc) {
			return cmp;
		} else {
			return -cmp;
		}
	}

	public SelectionAdapter getSelectionSortListener(int thisSortColumn) {
		return new SelectionAdapter() {
			@Override
			public void widgetSelected(SelectionEvent e) {
				if(thisSortColumn==sortColumn) {
					sortAsc = !sortAsc;
				} else {
					sortAsc = true;
				}
				sortColumn = thisSortColumn;
				tableViewer.refresh();
			}			
		};
	}

	public ColumnLabelProvider getColumnLabelProvider(int columnIndex) {
		switch(columnIndex) {
		case 0:
			return new ColumnLabelProvider() {
				@Override
				public String getText(Object element) {
					VirtualPlot e = (VirtualPlot) element;
					return e.plotID;
				}
			};
		case 1:
			return new ColumnLabelProvider() {
				@Override
				public String getText(Object element) {
					VirtualPlot e = (VirtualPlot) element;
					return e.generalStation.longName+" ("+e.generalStation.name+")";
				}
			};
		case 2:
			return new ColumnLabelProvider() {
				@Override
				public String getText(Object element) {
					VirtualPlot e = (VirtualPlot) element;
					return ""+e.geoPosEasting;
				}
			};
		case 3:
			return new ColumnLabelProvider() {
				@Override
				public String getText(Object element) {
					VirtualPlot e = (VirtualPlot) element;
					return ""+e.geoPosNorthing;
				}
			};			
		case 4:
			return new ColumnLabelProvider() {
				@Override
				public String getText(Object element) {
					VirtualPlot e = (VirtualPlot) element;
					return ""+e.intervalList.size();
				}
			};			
		default:
			return null;
		}
	}
	
	public void addTableViewerColumn(int columnIndex, String title, int width) {
		TableViewerColumn colStationName = new TableViewerColumn(tableViewer, SWT.NONE);
		colStationName.getColumn().setWidth(width);
		colStationName.getColumn().setText(title);
		colStationName.setLabelProvider(getColumnLabelProvider(columnIndex));
		colStationName.getColumn().addSelectionListener(getSelectionSortListener(columnIndex));	
	}

	public void createColumns() {		
		String[] titles = new String[]{"plotID","General Station","Longitude","Latitude","Time Intervals"};		
		for(int i=0;i<titles.length;i++) {
			addTableViewerColumn(i,titles[i],100);	
		}		
	}
}
