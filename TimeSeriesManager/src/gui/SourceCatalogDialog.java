package gui;

import gui.SourceViewComparator.SortType;

import java.util.ArrayList;
import java.util.List;

import org.eclipse.jface.dialogs.Dialog;
import org.eclipse.jface.dialogs.IDialogConstants;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.events.SelectionListener;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Shell;

import timeseriesdatabase.TimeConverter;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.catalog.SourceEntry;
import util.Util;

import org.eclipse.swt.widgets.Table;
import org.eclipse.jface.viewers.ArrayContentProvider;
import org.eclipse.jface.viewers.ColumnLabelProvider;
import org.eclipse.jface.viewers.TableViewer;
import org.eclipse.jface.viewers.TableViewerColumn;
import org.eclipse.jface.viewers.Viewer;
import org.eclipse.jface.viewers.ViewerComparator;
import org.eclipse.swt.SWT;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.layout.FillLayout;

public class SourceCatalogDialog extends Dialog {

	private TimeSeriesDatabase timeSeriesDatabase;
	private Table table;
	private TableViewer viewer;
	
	private SourceViewComparator sourceViewComparator = new SourceViewComparator();

	/**
	 * Create the dialog.
	 * @param parentShell
	 */
	public SourceCatalogDialog(Shell parentShell, TimeSeriesDatabase timeSeriesDatabase) {
		super(parentShell);
		setShellStyle(SWT.MAX | SWT.RESIZE);
		this.timeSeriesDatabase = timeSeriesDatabase;
	}

	/**
	 * Create contents of the dialog.
	 * @param parent
	 */
	@Override
	protected Control createDialogArea(Composite parent) {
		Composite container = (Composite) super.createDialogArea(parent);
		container.setLayout(new FillLayout(SWT.HORIZONTAL));

		// define the TableViewer
		viewer = new TableViewer(container, SWT.MULTI | SWT.H_SCROLL | SWT.V_SCROLL | SWT.FULL_SELECTION | SWT.BORDER);

		// create the columns 
		// not yet implemented
		createColumns(viewer);

		table = viewer.getTable();
		table.setHeaderVisible(true);
		table.setLinesVisible(true);
		table.setBounds(74, 10, 300, 171);
		//formToolkit.paintBordersFor(table);

		// set the content provider
		viewer.setContentProvider(ArrayContentProvider.getInstance());

		viewer.setInput(timeSeriesDatabase.sourceCatalog.getEntries());
		
		
		
		viewer.setComparator(sourceViewComparator);

		return container;
	}

	private void createColumns(TableViewer viewer) {
		TableViewerColumn colStationName = new TableViewerColumn(viewer, SWT.NONE);
		colStationName.getColumn().setWidth(100);
		colStationName.getColumn().setText("Station Name");
		colStationName.setLabelProvider(new ColumnLabelProvider() {
		  @Override
		  public String getText(Object element) {
			  SourceEntry e = (SourceEntry) element;
		    return ""+e.stationName;
		  }
		});
		colStationName.getColumn().addSelectionListener(getSelectionSortListener(SortType.STATION_NAME));		
		
		TableViewerColumn colFirstTimestamp = new TableViewerColumn(viewer, SWT.NONE);
		colFirstTimestamp.getColumn().setWidth(120);
		colFirstTimestamp.getColumn().setText("First Timestamp");
		colFirstTimestamp.setLabelProvider(new ColumnLabelProvider() {
		  @Override
		  public String getText(Object element) {
			  SourceEntry e = (SourceEntry) element;
		    return ""+TimeConverter.oleMinutesToText(e.firstTimestamp);
		  }
		});
		colFirstTimestamp.getColumn().addSelectionListener(getSelectionSortListener(SortType.FIRST_TIMESTAMP));	
		
		TableViewerColumn colLastTimestamp = new TableViewerColumn(viewer, SWT.NONE);
		colLastTimestamp.getColumn().setWidth(120);
		colLastTimestamp.getColumn().setText("Last Timestamp");
		colLastTimestamp.setLabelProvider(new ColumnLabelProvider() {
		  @Override
		  public String getText(Object element) {
			  SourceEntry e = (SourceEntry) element;
		    return ""+TimeConverter.oleMinutesToText(e.lastTimestamp);
		  }
		});
		colLastTimestamp.getColumn().addSelectionListener(getSelectionSortListener(SortType.LAST_TIMESTAMP));
		
		TableViewerColumn colRowCount = new TableViewerColumn(viewer, SWT.NONE);
		colRowCount.getColumn().setWidth(50);
		colRowCount.getColumn().setText("Row Count");
		colRowCount.setLabelProvider(new ColumnLabelProvider() {
		  @Override
		  public String getText(Object element) {
			  SourceEntry e = (SourceEntry) element;
		    return ""+e.rows;
		  }
		});
		colRowCount.getColumn().addSelectionListener(getSelectionSortListener(SortType.ROW_COUNT));		
		
		TableViewerColumn colFileName = new TableViewerColumn(viewer, SWT.NONE);
		colFileName.getColumn().setWidth(300);
		colFileName.getColumn().setText("File Name");
		colFileName.setLabelProvider(new ColumnLabelProvider() {
		  @Override
		  public String getText(Object element) {
			  SourceEntry e = (SourceEntry) element;
		    return ""+e.filename;
		  }
		});
		colFileName.getColumn().addSelectionListener(getSelectionSortListener(SortType.FILE_NAME));
		
		TableViewerColumn colHeaderNames = new TableViewerColumn(viewer, SWT.NONE);
		colHeaderNames.getColumn().setWidth(300);
		colHeaderNames.getColumn().setText("Header Names");
		colHeaderNames.setLabelProvider(new ColumnLabelProvider() {
		  @Override
		  public String getText(Object element) {
			  SourceEntry e = (SourceEntry) element;
		    return ""+Util.arrayToString(e.headerNames);
		  }
		});
		colHeaderNames.getColumn().addSelectionListener(getSelectionSortListener(SortType.HEADER_NAMES));
		
		TableViewerColumn colSensorNames = new TableViewerColumn(viewer, SWT.NONE);
		colSensorNames.getColumn().setWidth(300);
		colSensorNames.getColumn().setText("Sensor Names");
		colSensorNames.setLabelProvider(new ColumnLabelProvider() {
		  @Override
		  public String getText(Object element) {
			  SourceEntry e = (SourceEntry) element;
		    return ""+Util.arrayToString(e.sensorNames);
		  }
		});
		colSensorNames.getColumn().addSelectionListener(getSelectionSortListener(SortType.SENSOR_NAMES));
		
		TableViewerColumn colTimeStep = new TableViewerColumn(viewer, SWT.NONE);
		colTimeStep.getColumn().setWidth(50);
		colTimeStep.getColumn().setText("Time Step");
		colTimeStep.setLabelProvider(new ColumnLabelProvider() {
		  @Override
		  public String getText(Object element) {
			  SourceEntry e = (SourceEntry) element;
		    return ""+e.timeStep;
		  }
		});
		colTimeStep.getColumn().addSelectionListener(getSelectionSortListener(SortType.TIME_STEP));
	}

	/**
	 * Create contents of the button bar.
	 * @param parent
	 */
	@Override
	protected void createButtonsForButtonBar(Composite parent) {
		/*createButton(parent, IDialogConstants.OK_ID, IDialogConstants.OK_LABEL,
				true);
		createButton(parent, IDialogConstants.CANCEL_ID,
				IDialogConstants.CANCEL_LABEL, false);*/
	}

	/**
	 * Return the initial size of the dialog.
	 */
	@Override
	protected Point getInitialSize() {
		return new Point(450, 300);
	}
	
	private SelectionAdapter getSelectionSortListener(SortType sorttype) {
		return new SelectionAdapter() {
			@Override
			public void widgetSelected(SelectionEvent e) {
				if(sorttype==sourceViewComparator.sorttype) {
					sourceViewComparator.sortAsc = !sourceViewComparator.sortAsc;
				} else {
					sourceViewComparator.sortAsc = true;
				}
				sourceViewComparator.sorttype = sorttype;
				viewer.refresh();
			}			
		};
	}

}
