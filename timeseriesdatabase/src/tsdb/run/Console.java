package tsdb.run;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.rmi.NotBoundException;
import java.rmi.RemoteException;
import java.rmi.registry.LocateRegistry;
import java.rmi.registry.Registry;
import java.util.ArrayList;

import tsdb.remote.RemoteTsDB;
import tsdb.util.Util;

public class Console {

	static boolean run = true;

	final static String server_url = "rmi://192.168.191.183:16826/ServerTsDB";
	
	RemoteTsDB remoteTsDB;
	
	final String input_line;
	
	ArrayList<String> output_lines;

	public static void main(String[] args) {
		try {
			System.out.println("start RemoteTsDB...");
			Registry registry;

			registry = LocateRegistry.getRegistry("192.168.191.183",StartServerTsDB.REGISTRY_PORT);

			System.out.println("list: "+Util.arrayToString(registry.list()));

			String hostname = null;
			try {
				hostname = InetAddress.getLocalHost().getHostAddress();
			} catch (UnknownHostException e) {
				e.printStackTrace();
			}
			System.out.println("this host IP is " + hostname);

			RemoteTsDB remoteTsDB = (RemoteTsDB) registry.lookup(server_url);

			System.out.println("remoteTsDB: "+remoteTsDB.toString()+"  "+remoteTsDB.getClass());
		} catch (RemoteException | NotBoundException e1) {
			e1.printStackTrace();
		}

		BufferedReader reader = new BufferedReader(new InputStreamReader(System.in));

		


		String line = "intro";

		while(run&&line!=null) {
			Console console = new Console(line);
			console.run();
			if(run) {
				line = readLine(reader);
			}
		}
	}

	public Console(String input_line){
		this.input_line = input_line;
		output_lines = new ArrayList<String>();
	}

	public void run() {
		interprete(input_line);
	}

	public static String readLine(BufferedReader reader) {
		System.out.println();
		System.out.print("tsdb:$ ");
		try {
			return reader.readLine();
		} catch (IOException e) {
			e.printStackTrace();
			return null;
		}
	}

	public void interprete(String line) {
		if(line==null||line.isEmpty()) {
			return;
		}
		String command = line;
		int endIndex = line.indexOf(' ');
		if(endIndex>=0) {
			command = line.substring(0, endIndex);
		}
		command = command.trim().toLowerCase();
		//System.out.println("command: ["+command+"]");
		switch(command) {
		case "intro":
			command_intro();			
			break;
		case "exit":
			command_exit();
			break;
		case "commands":
			command_commands();
			break;
		case "status":
			command_status();
			break;
		case "create-empirical-reference":
			command_create_empirical_reference();
		default:
			command_unknown(command);
		}
	}
	
	public void println() {
		System.out.println();
	}
	
	
	public void println(String text) {
		System.out.println(text);
	}
	
	public void command_intro() {
		println();
		println("tsdb*------------------------------------------*tsdb");
		println("tsdb*----------------tsdb-console--------------*tsdb");
		println("tsdb*------------------------------------------*tsdb");
		println();
	}
	
	public void command_exit() {
		println("...closing console...");
		run = false;
	}
	
	private void command_status() {
		println("--- tsdb status ---");		
	}
	
	private void command_unknown(String command) {
		println("unknown command: "+command);	
	}
	
	private void command_commands() {
		println("commands: intro exit commands status");		
	}
	
	private void command_create_empirical_reference() {
		// TODO Auto-generated method stub
		
	}


}
