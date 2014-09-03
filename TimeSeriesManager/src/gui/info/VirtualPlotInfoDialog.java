package gui.info;

import java.rmi.RemoteException;
import org.apache.logging.log4j.Logger;
import org.eclipse.jface.dialogs.Dialog;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Shell;

import tsdb.remote.RemoteTsDB;
import tsdb.remote.VirtualPlotInfo;
import tsdb.util.Util;

import org.eclipse.swt.widgets.Table;
import org.eclipse.jface.viewers.TableViewer;
import org.eclipse.swt.SWT;
import org.eclipse.swt.layout.FillLayout;

public class VirtualPlotInfoDialog extends Dialog {
	
	private static Logger log = Util.log;

	private RemoteTsDB timeSeriesDatabase;
	private Table table;
	private TableViewBridge<VirtualPlotInfo> tableViewBridge;

	/**
	 * Create the dialog.
	 * @param parentShell
	 */
	public VirtualPlotInfoDialog(Shell parentShell, RemoteTsDB timeSeriesDatabase) {
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

		TableViewer tableViewer = new TableViewer(container, SWT.MULTI | SWT.H_SCROLL | SWT.V_SCROLL | SWT.FULL_SELECTION | SWT.BORDER);
		tableViewBridge = new TableViewBridge<VirtualPlotInfo>(tableViewer);
		
		tableViewBridge.addColumn("plotID",100,v->v.plotID);		
		tableViewBridge.addColumnText("General Station",100,v->v.generalStationInfo.longName+" ("+v.generalStationInfo.name+")");
		tableViewBridge.addColumnInteger("Easting", 100,v->v.geoPosEasting);
		tableViewBridge.addColumnInteger("Northing", 100,v->v.geoPosNorthing);
		tableViewBridge.addColumnInteger("Northing", 100,v->v.geoPosNorthing);
		tableViewBridge.addColumnInteger("Time Intervals", 100,v->v.intervalList.size());

		tableViewBridge.createColumns();
		table = tableViewer.getTable();
		table.setHeaderVisible(true);
		table.setLinesVisible(true);
		table.setBounds(74, 10, 300, 171);
		//formToolkit.paintBordersFor(table);

		try {
		// set the content provider
		//tableViewer.setContentProvider(ArrayContentProvider.getInstance());
		tableViewBridge.setInput(timeSeriesDatabase.getVirtualPlots());		
		//tableViewer.setComparator(tableViewBridge);
		} catch(RemoteException e) {
			log.error(e);
		}
		
		return container;
	}


	@Override
	protected void createButtonsForButtonBar(Composite parent) {
		// TODO Auto-generated method stub
		//super.createButtonsForButtonBar(parent);
	}

	/**
	 * Return the initial size of the dialog.
	 */
	@Override
	protected Point getInitialSize() {
		return new Point(450, 300);
	}
	
	

}
