package gui.info;

import java.rmi.RemoteException;

import org.eclipse.jface.viewers.TableViewer;
import org.eclipse.swt.SWT;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.widgets.Dialog;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Table;
import org.eclipse.swt.layout.GridLayout;

import tsdb.Sensor;
import tsdb.TimeConverter;
import tsdb.catalog.SourceEntry;
import tsdb.remote.RemoteTsDB;
import tsdb.util.TsDBLogger;
import tsdb.util.Util;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.events.MouseAdapter;
import org.eclipse.swt.events.MouseEvent;

public class NewSourceCatalogInfoDialog extends Dialog implements TsDBLogger {

	protected Object result;
	protected Shell shell;
	
	private TableViewBridge<SourceEntry> tableViewBridge;
	private RemoteTsDB tsdb;

	public NewSourceCatalogInfoDialog(Shell parent, RemoteTsDB tsdb) {
		super(parent, SWT.SHELL_TRIM | SWT.BORDER);
		this.setText("Source Catalog Info");
		this.tsdb = tsdb;
	}

	/**
	 * Open the dialog.
	 * @return the result
	 */
	public Object open() {
		createContents();
		shell.open();
		shell.setMaximized(true);
		
		
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
		shell.setLayout(new GridLayout(1, false));
		
		TableViewer tableViewer = new TableViewer(shell, SWT.BORDER | SWT.FULL_SELECTION | SWT.FILL);
		Table table = tableViewer.getTable();
		table.setLayoutData(new GridData(SWT.FILL, SWT.FILL, true, true, 1, 1));		
		tableViewBridge = new TableViewBridge<SourceEntry>(tableViewer);
		
		tableViewBridge.addColumnText("Station Name",100,SourceEntry::getStationName);
		tableViewBridge.addColumn("First",100,s->TimeConverter.oleMinutesToLocalDateTime(s.firstTimestamp).toString(),s->s.firstTimestamp);
		tableViewBridge.addColumn("Last",100,s->TimeConverter.oleMinutesToLocalDateTime(s.lastTimestamp).toString(),s->s.lastTimestamp);
		tableViewBridge.addColumn("Rows",100,s->s.rows);
		tableViewBridge.addColumn("Time Step",100,s->s.timeStep);
		tableViewBridge.addColumnText("Filename",100,s->s.filename);
		tableViewBridge.addColumnText("Path",100,s->s.path);		
		tableViewBridge.addColumnText("Header Names",100,s->Util.arrayToString(s.headerNames));
		tableViewBridge.addColumnText("Sensor Names",100,s->Util.arrayToString(s.sensorNames));
		
		
		tableViewBridge.createColumns();
		
		
		Label lblStatus = new Label(shell, SWT.NONE);
		lblStatus.addMouseListener(new MouseAdapter() {
			@Override
			public void mouseDown(MouseEvent e) {
			}
		});
		lblStatus.setText("status");
		
		
		
		try {
			SourceEntry[] sourceCatalogEntries = tsdb.getSourceCatalogEntries();
			System.out.println("catalog size: "+sourceCatalogEntries.length);
			tableViewBridge.setInput(sourceCatalogEntries);
			lblStatus.setText("catalog size: "+sourceCatalogEntries.length);
			
		} catch(RemoteException e) {
			log.error(e);
		}		
	}

}
