package gui;

import java.rmi.RemoteException;
import java.util.function.Function;
import java.util.function.Supplier;

import org.apache.logging.log4j.Logger;
import org.eclipse.swt.SWT;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.widgets.Dialog;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Group;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Text;

import swing2swt.layout.BorderLayout;
import tsdb.TimeConverter;
import tsdb.raw.TimeSeriesEntry;
import tsdb.remote.RemoteTsDB;
import tsdb.util.Util;
import tsdb.util.iterator.TimeSeriesIterator;

public class StatisticsDialog extends Dialog {
	
	private static Logger log = Util.log;
	
	private RemoteTsDB tsdb;

	protected Object result;
	protected Shell shell;
	private Text textBox;

	/**
	 * Create the dialog.
	 * @param parent
	 * @param tsdb
	 */
	public StatisticsDialog(Shell parent, RemoteTsDB tsdb) {
		super(parent, SWT.DIALOG_TRIM | SWT.APPLICATION_MODAL | SWT.MAX | SWT.RESIZE);
		setText("Statistics");
		this.tsdb = tsdb;
	}

	/**
	 * Open the dialog.
	 * @return the result
	 */
	public Object open() {
		createContents();
		shell.open();
		shell.layout();
		Display display = getParent().getDisplay();
		while (!shell.isDisposed()) {
			if (!display.readAndDispatch()) {
				display.sleep();
			}
		}
		return result;
	}

	/**
	 * Create contents of the dialog.
	 */
	private void createContents() {
		shell = new Shell(getParent(), getStyle());
		shell.setSize(450, 300);
		shell.setText(getText());
		shell.setLayout(new BorderLayout(0, 0));
		
		textBox = new Text(shell, SWT.BORDER | SWT.H_SCROLL | SWT.V_SCROLL | SWT.CANCEL | SWT.MULTI);
		textBox.setLayoutData(BorderLayout.CENTER);
		
		Group grpConfig = new Group(shell, SWT.NONE);
		grpConfig.setText("control");
		grpConfig.setLayoutData(BorderLayout.NORTH);
		
		Button btnRun = new Button(grpConfig, SWT.NONE);
		btnRun.addSelectionListener(new SelectionAdapter() {
			@Override
			public void widgetSelected(SelectionEvent e) {				
				Thread worker = new Thread() {
					@Override
					public void run(){						
						process();
					}
				};
				worker.start();				
			}
		});
		btnRun.setBounds(349, 32, 75, 25);
		btnRun.setText("run");

	}
	
	private void println(String text) {
		print(text+'\n');
	}
	
	private void print(String text) {
		getParent().getDisplay().asyncExec(new Runnable() {
			@Override
			public void run() {
				textBox.append(text);
			}
		});
	}
	
	private void process() {
		try {
		long station_counter = 0;
		long total_entry_counter = 0;
		long total_data_values_counter = 0;
		
		for(String stationName:tsdb.getStationNames()) {
			
			TimeSeriesIterator it = tsdb.query_raw(stationName, null, null, null);
			if(it==null) {
				//println(null);
			} else {
				long entry_counter = 0;
				TimeSeriesEntry e=null;
				Long start=null;
				Long end=null;
				//Timer timer = new Timer();
				//timer.start(stationName);
				while(it.hasNext()) {
					e = it.next();
					
					for(float v:e.data) {
						if(!Float.isNaN(v)) {
							total_data_values_counter++;
						}
					}
					
					
					if(start==null) {
						start = e.timestamp;
					}
					entry_counter++;
				}
				//timer.stop(stationName);
				end = Util.ifnull(e, x->x.timestamp);
				Function<Long,String> f = ((Long x)->TimeConverter.oleMinutesToLocalDateTime(x).toString());
				Supplier<String> s = () -> "---";
				println(stationName+": "+Util.ifnull(start, f)+" - "+Util.ifnull(end, f)+"\t\t entries:\t\t"+Util.bigNumberToString(entry_counter)+"\t"/*+timer.toString(stationName)*/);
				
				total_entry_counter += entry_counter;
				station_counter++;
			}
		}
		
		
		
		println("stations with data entries: "+Util.bigNumberToString(station_counter));
		println("total data entries: "+Util.bigNumberToString(total_entry_counter));
		println("total data values: "+Util.bigNumberToString(total_data_values_counter));
		} catch(RemoteException e) {
			log.error(e);
		}

	}	
}
