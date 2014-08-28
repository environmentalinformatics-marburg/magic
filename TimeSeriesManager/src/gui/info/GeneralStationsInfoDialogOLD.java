package gui.info;



import java.util.Map.Entry;

import org.apache.logging.log4j.Logger;
import org.eclipse.swt.SWT;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.widgets.Dialog;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Table;
import org.eclipse.swt.widgets.TableColumn;
import org.eclipse.swt.widgets.TableItem;

import tsdb.GeneralStation;
import tsdb.Sensor;
import tsdb.Station;
import tsdb.TsDB;
import tsdb.util.Util;

public class GeneralStationsInfoDialogOLD extends Dialog {
	
	private static Logger log = Util.log;

	private TsDB timeSeriesDatabase; 

	public GeneralStationsInfoDialogOLD(Shell parent, TsDB timeSeriesDatabase) {
		this(parent, SWT.DIALOG_TRIM | SWT.APPLICATION_MODAL, timeSeriesDatabase);

	}

	/**
	 * @wbp.parser.constructor
	 */
	public GeneralStationsInfoDialogOLD(Shell parent, int style,TsDB timeSeriesDatabase) {
		super(parent, style);
		this.timeSeriesDatabase = timeSeriesDatabase;
		setText("General Station Info");
	}

	public String open() {
		// Create the dialog window
		Shell shell = new Shell(getParent(), getStyle());
		shell.setText(getText());
		createContents(shell);
		shell.pack();
		shell.open();
		Display display = getParent().getDisplay();
		while (!shell.isDisposed()) {
			if (!display.readAndDispatch()) {
				display.sleep();
			}
		}
		// Return the entered value, or null
		return null;
	}

	private void createContents(final Shell shell) {
		;
		shell.setLayout(new GridLayout());
		Table table = new Table (shell, SWT.MULTI | SWT.BORDER | SWT.FULL_SELECTION);
		table.setLinesVisible (true);
		table.setHeaderVisible (true);
		GridData data = new GridData(SWT.FILL, SWT.FILL, true, true);
		data.heightHint = 200;
		table.setLayoutData(data);
		String[] titles = {"ID", "Name","Region","Group","Stations and Virtual Plots"};
		for (int i=0; i<titles.length; i++) {
			TableColumn column = new TableColumn (table, SWT.NONE);
			column.setText (titles [i]);
		}	

		for(GeneralStation generalStation:timeSeriesDatabase.getGeneralStations()) {
			TableItem item = new TableItem (table, SWT.NONE);
			
			item.setText (0, Util.ifnull(generalStation.name, "---"));
			item.setText (1, Util.ifnull(generalStation.longName, "---"));
			item.setText (2, Util.ifnull(generalStation.region,x->""+x.longName+" ("+x.name+")","---"));
			item.setText (3, Util.ifnull(generalStation.group,"---"));
			
			int pCount = generalStation.stationList.size()+generalStation.virtualPlots.size();
			item.setText (4, ""+pCount);
		}


		for (int i=0; i<titles.length; i++) {
			table.getColumn (i).pack ();
		}	


	}	

}


