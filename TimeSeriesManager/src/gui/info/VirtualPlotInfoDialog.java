package gui.info;



import java.util.ArrayList;
import java.util.List;

import org.apache.logging.log4j.Logger;
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
import timeseriesdatabase.VirtualPlot;
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

public class VirtualPlotInfoDialog extends Dialog {
	
	private static Logger log = Util.log;

	private TimeSeriesDatabase timeSeriesDatabase;
	private Table table;
	private TableViewer tableViewer;
	
	private VirtualPlotViewBridge viewComparator;

	/**
	 * Create the dialog.
	 * @param parentShell
	 */
	public VirtualPlotInfoDialog(Shell parentShell, TimeSeriesDatabase timeSeriesDatabase) {
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
		tableViewer = new TableViewer(container, SWT.MULTI | SWT.H_SCROLL | SWT.V_SCROLL | SWT.FULL_SELECTION | SWT.BORDER);
		
		this.viewComparator = new VirtualPlotViewBridge(tableViewer); 

		// create the columns 
		// not yet implemented
		viewComparator.createColumns();

		table = tableViewer.getTable();
		table.setHeaderVisible(true);
		table.setLinesVisible(true);
		table.setBounds(74, 10, 300, 171);
		//formToolkit.paintBordersFor(table);

		// set the content provider
		tableViewer.setContentProvider(ArrayContentProvider.getInstance());
		
		tableViewer.setInput(timeSeriesDatabase.getVirtualPlots());
		
		
		
		tableViewer.setComparator(viewComparator);

		return container;
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
	
	

}
