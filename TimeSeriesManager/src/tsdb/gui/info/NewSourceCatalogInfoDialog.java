package tsdb.gui.info;

import java.rmi.RemoteException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.stream.Stream;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.eclipse.jface.viewers.TableViewer;
import org.eclipse.swt.SWT;
import org.eclipse.swt.custom.CLabel;
import org.eclipse.swt.events.MouseAdapter;
import org.eclipse.swt.events.MouseEvent;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.widgets.Combo;
import org.eclipse.swt.widgets.Dialog;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Group;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Table;

import tsdb.StationProperties;
import tsdb.component.Region;
import tsdb.component.SourceEntry;
import tsdb.gui.bridge.ComboBridge;
import tsdb.gui.bridge.TableBridge;
import tsdb.remote.RemoteTsDB;
import tsdb.remote.VirtualPlotInfo;
import tsdb.util.TimeConverter;
import tsdb.util.TimestampInterval;
import tsdb.util.Util;

public class NewSourceCatalogInfoDialog extends Dialog {

	private static final Logger log = LogManager.getLogger();

	protected Object result;
	protected Shell shell;

	private TableBridge<SourceEntry> tableViewBridge;
	private RemoteTsDB tsdb;

	private CLabel labelInfo;

	private SourceEntry[] sourceCatalogEntries;
	HashMap<String, ArrayList<SourceEntry>> stationCatalogEntryMap;

	public NewSourceCatalogInfoDialog(Shell parent, RemoteTsDB tsdb) {
		super(parent, SWT.SHELL_TRIM | SWT.BORDER);
		this.setText("Source Catalog Info");
		this.tsdb = tsdb;

		try {
			sourceCatalogEntries = tsdb.getSourceCatalogEntries();
			System.out.println("catalog size: "+sourceCatalogEntries.length);			
		} catch(RemoteException e) {
			log.error(e);
		}		
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
		grpFilterBy.setLayout(new GridLayout(2, false));
		grpFilterBy.setLayoutData(new GridData(SWT.FILL, SWT.FILL, true, false, 1, 1));
		grpFilterBy.setText("filter by");

		Group grpRegion = new Group(grpFilterBy, SWT.NONE);
		grpRegion.setText("Region");
		grpRegion.setLayout(new GridLayout(1, false));

		Combo comboRegion = new Combo(grpRegion, SWT.READ_ONLY);
		ComboBridge<Region> comboBridgeRegion = new ComboBridge<Region>(comboRegion);
		comboBridgeRegion.setLabelMapper(r->r.longName);


		Group grpPlot = new Group(grpFilterBy, SWT.NONE);
		grpPlot.setText("Plot");
		grpPlot.setLayout(new GridLayout(1, false));

		Combo comboPlot = new Combo(grpPlot, SWT.READ_ONLY);
		comboPlot.setLayoutData(new GridData(SWT.FILL, SWT.CENTER, true, false, 1, 1));
		ComboBridge<String> comboBridgePlot = new ComboBridge<String>(comboPlot);





		labelInfo = new CLabel(shell, SWT.NONE);
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
		lblStatus.setText("catalog size: "+sourceCatalogEntries.length);


		Region[] regions = null;
		try {
			regions = tsdb.getRegions();
		} catch (RemoteException e2) {
			log.error(e2);
		}
		comboBridgeRegion.setInput(regions);
		if(regions!=null) {
			comboBridgeRegion.setSelection(regions[0]);
		}


		try {
			comboBridgePlot.setInput(Stream.concat(Stream.of("[all]"),Arrays.stream(tsdb.getPlots()).map(p->p.name)).toArray(String[]::new));
		} catch (RemoteException e1) {
			e1.printStackTrace();
		}

		comboBridgePlot.setSelection("[all]");
		comboBridgePlot.addSelectionChangedCallback(this::onPlotChanged);


		tableViewBridge.setInput(sourceCatalogEntries);
		stationCatalogEntryMap = new HashMap<String, ArrayList<SourceEntry>>();
		for(SourceEntry sourceEntry:sourceCatalogEntries) {
			ArrayList<SourceEntry> list = stationCatalogEntryMap.get(sourceEntry.stationName);
			if(list==null) {
				list = new ArrayList<SourceEntry>();
				stationCatalogEntryMap.put(sourceEntry.stationName, list);
			}
			list.add(sourceEntry);			
		}

	}

	public void onPlotChanged(String plotID) {
		if(plotID.equals("[all]")) {
			tableViewBridge.setInput(sourceCatalogEntries);
		} else {
			if(stationCatalogEntryMap.containsKey(plotID)) {						
				ArrayList<SourceEntry> resultList = stationCatalogEntryMap.get(plotID);
				if(resultList==null) {
					resultList = new ArrayList<SourceEntry>(0);
				}
				tableViewBridge.setInput(resultList.toArray(new SourceEntry[0]));
				labelInfo.setText("station "+plotID);
			} else {
				ArrayList<SourceEntry> resultList = new ArrayList<SourceEntry>();
				String info = "station ";
				try {
					VirtualPlotInfo virtualPlot = tsdb.getVirtualPlot(plotID);
					if(virtualPlot!=null) {
						List<TimestampInterval<StationProperties>> intervals = virtualPlot.intervalList;
						for(TimestampInterval<StationProperties> i:intervals) {
							info += "  "+i.value.get_serial();
							ArrayList<SourceEntry> entryList = stationCatalogEntryMap.get(i.value.get_serial());
							if(entryList!=null) {
								for(SourceEntry entry:entryList) {
									if(i.contains(entry.firstTimestamp, entry.lastTimestamp)) {
										resultList.add(entry);
									}
								}
							}
						}
					}
				} catch (RemoteException e1) {
					log.error(e1);
					info = "error";
				}
				tableViewBridge.setInput(resultList.toArray(new SourceEntry[0]));
				labelInfo.setText(info);						
			}

		}

	}
}
