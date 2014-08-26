package gui;

import gui.info.GeneralStationsInfoDialogOLD;
import gui.info.LoggerTypeInfoDialog;
import gui.info.SensorsInfoDialog;
import gui.info.SourceCatalogInfoDialog;
import gui.info.StationsInfoDialog;
import gui.info.VirtualPlotInfoDialog;
import gui.query.QueryDialog;
import gui.sensorquery.SensorQueryDialog;

import java.time.LocalDateTime;
import java.util.function.Consumer;
import java.util.function.Supplier;

import org.apache.logging.log4j.Logger;
import org.eclipse.core.databinding.observable.Realm;
import org.eclipse.jface.databinding.swt.SWTObservables;
import org.eclipse.jface.window.Window;
import org.eclipse.swt.SWT;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.events.SelectionListener;
import org.eclipse.swt.layout.FillLayout;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.Listener;
import org.eclipse.swt.widgets.Menu;
import org.eclipse.swt.widgets.MenuItem;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Text;

import com.sun.xml.internal.messaging.saaj.packaging.mime.util.QEncoderStream;

import tsdb.FactoryTsDB;
import tsdb.Sensor;
import tsdb.Station;
import tsdb.TsDB;
import tsdb.aggregated.TimeSeries;
import tsdb.raw.TimestampSeries;
import tsdb.util.CSVTimeType;
import tsdb.util.Util;

public class TimeSeriesManager {
	
	private static Logger log = Util.log;

	public TsDB timeSeriesDatabase;
	
	public Shell shell;
	public Text textBox;
	
	public PrintBox printbox;

	public static void main(String[] args) {		
		TimeSeriesManager timeSeriesManager = new TimeSeriesManager();
		timeSeriesManager.run();
	}	

	public void run() {
		Display display = new Display();
		Realm.runWithDefault(SWTObservables.getRealm(display), new Runnable() {
			public void run() {
				shell = new Shell(display);
				init();
				//shell.pack();
				shell.open();
				while (!shell.isDisposed()) {
					if (!display.readAndDispatch())
						display.sleep();
				}
				display.dispose();
				System.out.println("...end");
			}
		});
		display.dispose();	
	}	
	
	private void init() {
		System.out.println("start...");
		String databaseDirectory = "c:/timeseriesdatabase_database/";
		String configDirectory = "c:/git_magic/timeseriesdatabase/config/";
		String cacheDirectory = "c:/timeseriesdatabase_cache/";
		timeSeriesDatabase = FactoryTsDB.createDefault(databaseDirectory, configDirectory, cacheDirectory);
		//timeSeriesDatabase = TimeSeriesDatabaseFactory.createDefault();

		shell.setText("time series database manager");
		shell.setSize(300, 400);
		shell.setLayout(new FillLayout());

		Menu menuBar = new Menu(shell, SWT.BAR);
		
		Menu infoMenu = addMenuColumn(menuBar,"info");
		addMenuItem(infoMenu,"sensors",x->(new SensorsInfoDialog(shell,timeSeriesDatabase)).open());
		addMenuItem(infoMenu,"stations",x->(new StationsInfoDialog(shell,timeSeriesDatabase)).open());
		addMenuItem(infoMenu,"virtual plots",x->(new VirtualPlotInfoDialog(shell,timeSeriesDatabase).open()));
		addMenuItem(infoMenu,"general stations",x->(new gui.info.GeneralStationInfoDialog(shell, timeSeriesDatabase)).open());
		addMenuItem(infoMenu,"logger types",x->(new LoggerTypeInfoDialog(shell, timeSeriesDatabase)).open());
		addMenuItem(infoMenu,"source catalog",x->(new SourceCatalogInfoDialog(shell, timeSeriesDatabase)).open());

		Menu queryMenu = addMenuColumn(menuBar,"Query");
		addMenuItem(queryMenu,"query", x->(new QueryDialog(shell,timeSeriesDatabase)).open());
		addMenuItem(queryMenu,"query sensors", new SensorQueryDialog(shell,timeSeriesDatabase));
		
		Menu statisticsMenu = addMenuColumn(menuBar,"Statistics");
		addMenuItem(statisticsMenu, "statistics", x->(new StatisticsDialog(shell, timeSeriesDatabase)).open());


		textBox = new Text(shell, SWT.MULTI | SWT.BORDER | SWT.WRAP | SWT.V_SCROLL);
		textBox.append("start");
		textBox.setEditable(false);		
		printbox = new PrintBox(this);

		shell.setMenuBar(menuBar); 
		
	}
	
	private void addMenuItem(Menu menu,String title,Listener listener) {
		MenuItem dataGenerationItem = new MenuItem(menu, SWT.PUSH);
		dataGenerationItem.setText(title);
		dataGenerationItem.addListener(SWT.Selection, listener);	
	}
	
	private void addMenuItem(Menu menu,String title, Window window) {
		addMenuItem(menu,title,x->window.open());
	}
	
	private Menu addMenuColumn(Menu menuBar, String title) {
		MenuItem menuHeader = new MenuItem(menuBar, SWT.CASCADE);
		menuHeader.setText(title);
		Menu menuEntry = new Menu(shell, SWT.DROP_DOWN);
		menuHeader.setMenu(menuEntry);
		return menuEntry; 
	}
}
