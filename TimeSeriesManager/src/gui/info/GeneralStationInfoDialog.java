package gui.info;

import org.eclipse.jface.dialogs.Dialog;
import org.eclipse.jface.dialogs.IDialogConstants;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.SWT;
import org.eclipse.swt.widgets.Table;
import org.eclipse.jface.viewers.TableViewer;
import org.eclipse.jface.layout.TableColumnLayout;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.layout.FillLayout;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.widgets.TableColumn;
import org.eclipse.jface.viewers.ArrayContentProvider;
import org.eclipse.jface.viewers.TableViewerColumn;
import org.eclipse.jface.viewers.ColumnPixelData;

import timeseriesdatabase.GeneralStation;
import timeseriesdatabase.TimeSeriesDatabase;
import timeseriesdatabase.VirtualPlot;
import util.Util;

public class GeneralStationInfoDialog extends Dialog {
	
	private TimeSeriesDatabase timeSeriesDatabase;
	
	private TableViewBridge<GeneralStation> tableViewBridge;
	
	private Table table;

	/**
	 * Create the dialog.
	 * @param parentShell
	 */
	public GeneralStationInfoDialog(Shell parent, TimeSeriesDatabase timeSeriesDatabase) {
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
		/*Composite container = (Composite) super.createDialogArea(parent);
		GridLayout gridLayout = (GridLayout) container.getLayout();*/
		Composite container = (Composite) super.createDialogArea(parent);
		container.setLayout(new FillLayout(SWT.HORIZONTAL));
		
		TableViewer tableViewer = new TableViewer(container, SWT.MULTI | SWT.H_SCROLL | SWT.V_SCROLL | SWT.FULL_SELECTION | SWT.BORDER);
		tableViewBridge = new TableViewBridge<GeneralStation>(tableViewer);
		
		/*
		 * String[] titles = {"ID", "Name","Region","Group","Stations and Virtual Plots"};
		 * 
		 * 
		item.setText (0, Util.ifnull(generalStation.name, "---"));
		item.setText (1, Util.ifnull(generalStation.longName, "---"));
		item.setText (2, Util.ifnull(generalStation.region,x->""+x.longName+" ("+x.name+")","---"));
		item.setText (3, Util.ifnull(generalStation.group,"---"));
		
		int pCount = generalStation.stationList.size()+generalStation.virtualPlotList.size();
		item.setText (4, ""+pCount);
		*/
		
		tableViewBridge.addColumn("ID",50,g->g.name);
		tableViewBridge.addColumn("Name",200,g->Util.ifnull(g.longName, "---"));
		tableViewBridge.addColumn("Region",200,g->Util.ifnull(g.region,x->""+x.longName+" ("+x.name+")","---"));
		tableViewBridge.addColumn("Group",70,g->Util.ifnull(g.group, "---"));
		tableViewBridge.addColumn("Stations and Virtual Plots",100,g->""+(g.stationList.size()+g.virtualPlots.size()));


		tableViewBridge.createColumns();
		table = tableViewer.getTable();
		table.setHeaderVisible(true);
		table.setLinesVisible(true);
		table.setBounds(74, 10, 300, 171);
		//formToolkit.paintBordersFor(table);

		// set the content provider
		tableViewer.setContentProvider(ArrayContentProvider.getInstance());
		tableViewer.setInput(timeSeriesDatabase.getGeneralStations());		
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
