package tsdb.run;

import java.lang.Thread.UncaughtExceptionHandler;
import java.rmi.registry.LocateRegistry;
import java.rmi.registry.Registry;
import java.rmi.server.UnicastRemoteObject;

import tsdb.FactoryTsDB;
import tsdb.TsDB;
import tsdb.remote.RemoteTsDB;
import tsdb.remote.ServerTsDB;

public class StartServerTsDB {	
	public static final String SERVERTSDB_NAME = "ServerTsDB";
	public static void main(String[] args) {
		System.out.println("start...");
		TsDB tsdb = FactoryTsDB.createDefault();
		try {
			ServerTsDB servertsdb = new ServerTsDB(tsdb);
			RemoteTsDB stubTsDB = (RemoteTsDB) UnicastRemoteObject.exportObject((RemoteTsDB)servertsdb, 0);
			System.out.println("create registry..."+stubTsDB.getClass().getMethods().length);
			Registry registry = LocateRegistry.createRegistry(Registry.REGISTRY_PORT);
			System.out.println("bind tsdserver...");
			registry.rebind(SERVERTSDB_NAME, stubTsDB);
			System.out.println("...tsdserver bound");
		} catch (Exception e) {
			e.printStackTrace();
		}		
		System.out.println("...ready");
		Thread.setDefaultUncaughtExceptionHandler(new UncaughtExceptionHandler() {		
			@Override
			public void uncaughtException(Thread t, Throwable e) {
				System.out.println(e);				
			}
		});
	}
}
