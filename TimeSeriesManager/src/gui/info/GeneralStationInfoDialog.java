package gui.info;

import java.rmi.RemoteException;

import org.apache.logging.log4j.Logger;
import org.eclipse.jface.dialogs.Dialog;
import org.eclipse.jface.viewers.TableViewer;
import org.eclipse.swt.SWT;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.layout.FillLayout;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Table;

import tsdb.remote.GeneralStationInfo;
import tsdb.remote.RemoteTsDB;
import tsdb.util.Util;

public class GeneralStationInfoDialog extends Dialog {

	private static Logger log = Util.log;

	private RemoteTsDB timeSeriesDatabase;

	private TableViewBridge<GeneralStationInfo> tableViewBridge;

	private Table table;

	/**
	 * Create the dialog.
	 * @param parentShell
	 */
	public GeneralStationInfoDialog(Shell parent, RemoteTsDB timeSeriesDatabase) {
		super(parent);
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
		tableViewBridge = new TableViewBridge<GeneralStationInfo>(tableViewer);

		tableViewBridge.addColumnText("ID",50,GeneralStationInfo::getName);
		tableViewBridge.addColumnText("Name",200,g->Util.ifnull(g.longName, "---"));
		tableViewBridge.addColumnText("Region",200,g->Util.ifnull(g.region,x->""+x.longName+" ("+x.name+")","---"));
		tableViewBridge.addColumnText("Group",70,GeneralStationInfo::getGroup);
		tableViewBridge.addColumnInteger("Stations and Virtual Plots",100,g->(g.stationCount+g.virtualPlotCount));


		tableViewBridge.createColumns();
		table = tableViewer.getTable();
		table.setHeaderVisible(true);
		table.setLinesVisible(true);
		table.setBounds(74, 10, 300, 171);

		//tableViewer.setContentProvider(ArrayContentProvider.getInstance());
		try {
			tableViewer.setInput(timeSeriesDatabase.getGeneralStations());
		} catch(RemoteException e) {
			log.error(e);
		}
		tableViewer.setComparator(tableViewBridge);
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
