package gui;



import java.util.Map.Entry;

import org.eclipse.swt.SWT;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.widgets.Dialog;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Table;
import org.eclipse.swt.widgets.TableColumn;
import org.eclipse.swt.widgets.TableItem;

import timeseriesdatabase.GeneralStation;
import timeseriesdatabase.Sensor;
import timeseriesdatabase.Station;
import timeseriesdatabase.TimeSeriesDatabase;

public class GeneralStationsInfoDialog extends Dialog {
	
	TimeSeriesDatabase timeSeriesDatabase; 

	public GeneralStationsInfoDialog(Shell parent, TimeSeriesDatabase timeSeriesDatabase) {
		this(parent, SWT.DIALOG_TRIM | SWT.APPLICATION_MODAL, timeSeriesDatabase);
		
	}
	
	public GeneralStationsInfoDialog(Shell parent, int style,TimeSeriesDatabase timeSeriesDatabase) {
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
		String[] titles = {"name", "sensor name translation"};
		for (int i=0; i<titles.length; i++) {
			TableColumn column = new TableColumn (table, SWT.NONE);
			column.setText (titles [i]);
		}	

		for(GeneralStation generalStation:timeSeriesDatabase.generalStationMap.values()) {
			TableItem item = new TableItem (table, SWT.NONE);
			item.setText (0, generalStation.name);
			
			String s ="";
			for(Entry<String, String> entry:generalStation.sensorNameTranlationMap.entrySet()) {
				s+=entry.getKey()+"->"+entry.getValue()+"  ";
			}
			
			item.setText (1, s);
			
		}
		
		
		for (int i=0; i<titles.length; i++) {
			table.getColumn (i).pack ();
		}	

	   
	  }	

}

