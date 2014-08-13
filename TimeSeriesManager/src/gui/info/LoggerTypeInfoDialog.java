package gui.info;



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
import timeseriesdatabase.LoggerType;
import timeseriesdatabase.Sensor;
import timeseriesdatabase.Station;
import timeseriesdatabase.TimeSeriesDatabase;

public class LoggerTypeInfoDialog extends Dialog {

	TimeSeriesDatabase timeSeriesDatabase; 

	public LoggerTypeInfoDialog(Shell parent, TimeSeriesDatabase timeSeriesDatabase) {
		this(parent, SWT.DIALOG_TRIM | SWT.APPLICATION_MODAL | SWT.MAX | SWT.RESIZE, timeSeriesDatabase);

	}

	public LoggerTypeInfoDialog(Shell parent, int style,TimeSeriesDatabase timeSeriesDatabase) {
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
		
		int maxColumnCount=0;
		for(LoggerType loggertype:timeSeriesDatabase.getLoggerTypes()) {
			if(loggertype.sensorNames.length>maxColumnCount) {
				maxColumnCount = loggertype.sensorNames.length;
			}
		}
		
		String[] titles = new String[2+maxColumnCount];
		titles[0] = "type name";
		titles[1] = "Attributes";
		for(int i=0;i<maxColumnCount;i++) {
			titles[2+i] = ""+(i+1);
		}		
		for (int i=0; i<titles.length; i++) {
			TableColumn column = new TableColumn (table, SWT.NONE);
			column.setText (titles [i]);
		}
		
		for(LoggerType loggertype:timeSeriesDatabase.getLoggerTypes()) {
			TableItem item = new TableItem (table, SWT.NONE);
			item.setText(0, loggertype.typeName);
			item.setText(1, ""+loggertype.sensorNames.length);
			
			/*String sensorNames="";
			for(String name:loggertype.sensorNames) {
				sensorNames += name+" ";
			}			
			item.setText(1, sensorNames);*/
			
			for(int i=0;i<loggertype.sensorNames.length;i++) {
				item.setText(2+i, loggertype.sensorNames[i]);
			}
			
		}

		for (int i=0; i<titles.length; i++) {
			table.getColumn (i).pack ();
		}
		
		shell.setMaximized(true);
	}	

}



