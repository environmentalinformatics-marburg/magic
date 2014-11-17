package tsdb.gui.info;

import java.rmi.RemoteException;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Stream;
import java.util.stream.StreamSupport;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.eclipse.jface.viewers.TableViewer;
import org.eclipse.swt.SWT;
import org.eclipse.swt.events.MouseAdapter;
import org.eclipse.swt.events.MouseEvent;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.widgets.Dialog;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Table;

import tsdb.StationProperties;
import tsdb.TimeConverter;
import tsdb.catalog.SourceEntry;
import tsdb.gui.bridge.ComboBridge;
import tsdb.gui.bridge.TableBridge;
import tsdb.remote.RemoteTsDB;
import tsdb.util.TimestampInterval;
import tsdb.util.Util;

import org.eclipse.swt.widgets.Group;
import org.eclipse.swt.widgets.Combo;
import org.eclipse.swt.layout.FillLayout;
import org.eclipse.swt.custom.CLabel;

public class NewSourceCatalogInfoDialog extends Dialog {

	private static final Logger log = LogManager.getLogger();

	protected Object result;
	protected Shell shell;

	private TableBridge<SourceEntry> tableViewBridge;
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
		shell.setSize(458, 343);
		shell.setText(getText());
		shell.setLayout(new GridLayout(1, false));

		Group grpFilterBy = new Group(shell, SWT.NONE);
		grpFilterBy.setLayout(new FillLayout(SWT.HORIZONTAL));
		grpFilterBy.setLayoutData(new GridData(SWT.FILL, SWT.FILL, true, false, 1, 1));
		grpFilterBy.setText("filter by");

		Group grpPlot = new Group(grpFilterBy, SWT.NONE);
		grpPlot.setText("Plot");
		grpPlot.setLayout(new GridLayout(1, false));

		Combo comboPlot = new Combo(grpPlot, SWT.READ_ONLY);
		comboPlot.setLayoutData(new GridData(SWT.FILL, SWT.CENTER, true, false, 1, 1));
		ComboBridge<String> comboBridgePlot = new ComboBridge<String>(comboPlot);




		CLabel labelInfo = new CLabel(shell, SWT.NONE);
		labelInfo.setLayoutData(new GridData(SWT.FILL, SWT.CENTER, true, false, 1, 1));
		labelInfo.setText("...");

		TableViewer tableViewer = new TableViewer(shell, SWT.BORDER | SWT.FULL_SELECTION | SWT.FILL);
		Table table = tableViewer.getTable();
		table.setLayoutData(new GridData(SWT.FILL, SWT.FILL, true, true, 1, 1));		
		tableViewBridge = new TableBridge<SourceEntry>(tableViewer);

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
			comboBridgePlot.setInput(Stream.concat(Stream.of("[all]"),Arrays.stream(tsdb.getPlotInfos()).map(p->p.name)).toArray(String[]::new));
		} catch (RemoteException e1) {
			e1.printStackTrace();
		}

		comboBridgePlot.setSelection("[all]");
		comboBridgePlot.addSelectionChangedCallback(s->{
			if(s.equals("[all]")) {
				tableViewBridge.setFilter(null);
			} else {
				try {
					if(Arrays.stream(tsdb.getStationNames()).anyMatch(n->n.equals(s))) {
						labelInfo.setText(s);
						tableViewBridge.setFilter(se->se.stationName.equals(s));
					} else {

						List<TimestampInterval<StationProperties>> list = tsdb.getVirtualPlotInfo(s).intervalList;
						String info = "";
						for(TimestampInterval<StationProperties> i:list) {
							info += "  "+i.value.get_serial();
						}
						labelInfo.setText(info);
						tableViewBridge.setFilter(se->{
							boolean valid = false;

							for(TimestampInterval<StationProperties> i:list) {

								if(se.stationName.equals(i.value.get_serial())) {
									if(i.contains(se.firstTimestamp, se.lastTimestamp)) {
										valid = true;
										break;
									}
								}
							}

							return valid;
						});
					}
				} catch (RemoteException e1) {
					e1.printStackTrace();
				}
			}
		});



		try {

			/*List<TimestampInterval<StationProperties>> list = tsdb.getVirtualPlotInfo("foc0").intervalList;


			tableViewBridge.setFilter(se->{
				boolean valid = false;
				String info = "";
				for(TimestampInterval<StationProperties> i:list) {
					info += "  "+i.value.get_serial();
					if(se.stationName.equals(i.value.get_serial())) {
						valid = true;
						break;
					}
				}
				labelInfo.setText(info);
				return valid;
			});*/
			SourceEntry[] sourceCatalogEntries = tsdb.getSourceCatalogEntries();
			System.out.println("catalog size: "+sourceCatalogEntries.length);
			tableViewBridge.setInput(sourceCatalogEntries);
			lblStatus.setText("catalog size: "+sourceCatalogEntries.length);

		} catch(RemoteException e) {
			log.error(e);
		}		
	}
}
