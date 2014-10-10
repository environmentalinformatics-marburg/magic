package tsdb.run;

import java.util.ArrayList;

import tsdb.Sensor;
import tsdb.Station;
import tsdb.TsDB;
import tsdb.VirtualPlot;

public class ConsoleRunner implements Runnable {

	private final TsDB tsdb;
	private final String input_line;
	private ArrayList<String> output_lines;

	public ConsoleRunner(TsDB tsdb, String input_line){
		this.tsdb = tsdb;
		this.input_line = input_line;
		this.output_lines = new ArrayList<String>();
	}


	@Override
	public void run() {
		interprete(input_line);
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
			break;
		case "plots":
			command_plots();
			break;
		case "sensors":
			command_sensors();
			break;
		case "stations":
			command_stations();
			break;
		case "help":
			command_help();
			break;			
		default:
			command_unknown(command);
		}
	}

	private void command_help() {
		println("With this console commands can be executed at tsdb server.");
		
	}


	private void command_stations() {
		for(Station station:tsdb.getStations()) {
				println(station.stationID);
		}		
	}


	private void command_sensors() {
		for(Sensor sensor:tsdb.getSensors()) {
			println(sensor.name);
		}		
	}

	private void command_plots() {
		for(VirtualPlot virtualplot:tsdb.getVirtualPlots()) {
			println(virtualplot.plotID);
		}
		for(Station station:tsdb.getStations()) {
			if(station.isPlot) {
				println(station.stationID);
			}
		}
	}


	public void println() {
		synchronized (output_lines) {
			output_lines.add("");
		} 
		System.out.println();
	}


	public void println(String text) {
		synchronized (output_lines) {
			output_lines.add(text);
		}		
	}

	public String[] getOutputLines() {
		String[] lines;
		synchronized (output_lines) {
			lines = output_lines.toArray(new String[0]);
			output_lines.clear();
		}
		return lines;
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
	}

	private void command_status() {
		println("--- tsdb status ---");		
	}

	private void command_unknown(String command) {
		println("unknown command: "+command);	
	}

	private void command_commands() {
		println("commands: intro exit commands status plots sensors stations");		
	}

	private void command_create_empirical_reference() {
		println("create group averages...");	
		new CreateStationGroupAverageCache(tsdb,this::println).run();
	}


}
