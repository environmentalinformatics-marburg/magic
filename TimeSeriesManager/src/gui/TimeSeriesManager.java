package gui;

import gui.export.CollectorDialog;
import gui.info.LoggerTypeInfoDialog;
import gui.info.NewSensorInfoDialog;
import gui.info.NewSourceCatalogInfoDialog;
import gui.info.StationsInfoDialog;
import gui.info.VirtualPlotInfoDialog;
import gui.query.QueryDialog;
import gui.sensorquery.SensorQueryDialog;

import java.net.InetAddress;
import java.net.UnknownHostException;
import java.rmi.NotBoundException;
import java.rmi.RemoteException;
import java.rmi.registry.LocateRegistry;
import java.rmi.registry.Registry;

import org.eclipse.core.databinding.observable.Realm;
import org.eclipse.jface.databinding.swt.SWTObservables;
import org.eclipse.swt.SWT;
import org.eclipse.swt.layout.FillLayout;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Listener;
import org.eclipse.swt.widgets.Menu;
import org.eclipse.swt.widgets.MenuItem;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Text;

import tsdb.FactoryTsDB;
import tsdb.TsDB;
import tsdb.util.TsDBLogger;
import tsdb.util.Util;
import tsdb.remote.RemoteTsDB;
import tsdb.remote.ServerTsDB;
import tsdb.run.StartServerTsDB;

public class TimeSeriesManager implements TsDBLogger {

	public RemoteTsDB remoteTsDB;

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
				try {
					init();
				} catch (RemoteException | NotBoundException e) {
					e.printStackTrace();
				}
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

	private void init() throws RemoteException, NotBoundException {
		boolean useRemote = false;
		//boolean useRemote = true;
		//boolean usedefault = true;
		boolean usedefault = false;

		System.out.println("start...");

		if(!useRemote) {
			if(usedefault) {
				TsDB tsdb = FactoryTsDB.createDefault();
				this.remoteTsDB =  new ServerTsDB(tsdb);
			} else {
				String databaseDirectory = "c:/timeseriesdatabase_database/";
				String configDirectory = "c:/git_magic/timeseriesdatabase/config/";
				String cacheDirectory = "c:/timeseriesdatabase_cache/";
				TsDB tsDB = FactoryTsDB.createDefault(databaseDirectory, configDirectory, cacheDirectory);
				//timeSeriesDatabase = TimeSeriesDatabaseFactory.createDefault();		
				this.remoteTsDB =  new ServerTsDB(tsDB);
			}
		} else {

			System.out.println("start RemoteTsDB...");
			//Registry registry = LocateRegistry.getRegistry("localhost",StartServerTsDB.REGISTRY_PORT);
			Registry registry = LocateRegistry.getRegistry("192.168.191.183",StartServerTsDB.REGISTRY_PORT);
			System.out.println("list: "+Util.arrayToString(registry.list()));


			String hostname = null;
			try {
				hostname = InetAddress.getLocalHost().getHostAddress();
			} catch (UnknownHostException e) {
				e.printStackTrace();
			}
			System.out.println("this host IP is " + hostname);

			//String server_url = "rmi://137.248.191.180:16826/ServerTsDB";
			String server_url = "rmi://192.168.191.183:16826/ServerTsDB";

			remoteTsDB = (RemoteTsDB) registry.lookup(server_url);

			System.out.println("remoteTsDB: "+remoteTsDB.toString()+"  "+remoteTsDB.getClass());

		}



		shell.setText("Time Series Database Manager");
		shell.setSize(300, 400);
		shell.setLayout(new FillLayout());

		Menu menuBar = new Menu(shell, SWT.BAR);

		Menu infoMenu = addMenuColumn(menuBar,"Info");

		addMenuItem(infoMenu,"sensors",x->(new NewSensorInfoDialog(shell,remoteTsDB)).open());
		addMenuItem(infoMenu,"stations",x->(new StationsInfoDialog(shell,remoteTsDB)).open());
		addMenuItem(infoMenu,"virtual plots",x->(new VirtualPlotInfoDialog(shell,remoteTsDB).open()));
		addMenuItem(infoMenu,"general stations",x->(new gui.info.GeneralStationInfoDialog(shell, remoteTsDB)).open());
		addMenuItem(infoMenu,"logger types",x->(new LoggerTypeInfoDialog(shell, remoteTsDB)).open());
		addMenuItem(infoMenu,"source catalog",x->(new NewSourceCatalogInfoDialog(shell, remoteTsDB)).open());

		Menu queryMenu = addMenuColumn(menuBar,"Query");
		addMenuItem(queryMenu,"query", x->(new QueryDialog(shell,remoteTsDB)).open());
		addMenuItem(queryMenu,"query sensors", x->(new SensorQueryDialog(shell,remoteTsDB)).open());
		addMenuItem(queryMenu,"export", x->(new CollectorDialog(shell,remoteTsDB)).open());

		Menu statisticsMenu = addMenuColumn(menuBar,"Statistics");
		addMenuItem(statisticsMenu, "statistics", x->(new StatisticsDialog(shell, remoteTsDB)).open());


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

	private Menu addMenuColumn(Menu menuBar, String title) {
		MenuItem menuHeader = new MenuItem(menuBar, SWT.CASCADE);
		menuHeader.setText(title);
		Menu menuEntry = new Menu(shell, SWT.DROP_DOWN);
		menuHeader.setMenu(menuEntry);
		return menuEntry; 
	}
}
