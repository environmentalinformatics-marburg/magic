package tsdb.web;

import java.rmi.RemoteException;

import tsdb.TsDB;
import tsdb.TsDBFactory;
import tsdb.remote.RemoteTsDB;
import tsdb.remote.ServerTsDB;
import tsdb.remote.StartServerTsDB;

public class Run {
	public static void main(String[] args) throws RemoteException, InterruptedException {

		TsDB tsdb = TsDBFactory.createDefault();
		RemoteTsDB remoteTsdb = new ServerTsDB(tsdb);


		Runnable runnerRMI = ()->{
			try {
				StartServerTsDB.run(remoteTsdb);
			} catch (Exception e) {
				e.printStackTrace();
			}
		};

		Thread threadRMI = new Thread(runnerRMI);
		threadRMI.start();

		Runnable runnerWEB = ()->{
			try {
				Main.run(remoteTsdb);
			} catch (Exception e) {
				e.printStackTrace();
			}
		};

		Thread threadWEB = new Thread(runnerWEB);
		threadWEB.start();

		threadRMI.join();
		threadWEB.join();

		tsdb.close();
	}
}
