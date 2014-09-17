package web;

import java.io.IOException;
import java.io.PrintWriter;

import javafx.scene.control.Tab;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.eclipse.jetty.server.Request;
import org.eclipse.jetty.server.Server;
import org.eclipse.jetty.server.handler.AbstractHandler;

import tsdb.Sensor;
import tsdb.remote.PlotInfo;
import tsdb.remote.RemoteTsDB;

public class InfoHandler extends AbstractHandler
{ 
	private final RemoteTsDB tsdb;

	public InfoHandler(RemoteTsDB tsdb)
	{
		this.tsdb=tsdb;
	}

	public void handle(String target, Request baseRequest, HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException
	{				
		response.setContentType("text/plain;charset=utf-8");
        response.setStatus(HttpServletResponse.SC_OK);
        baseRequest.setHandled(true);
		System.out.println("target "+target);

		PrintWriter writer = response.getWriter();

		switch(target) {
		case "/plots":
			handle_plots(writer);
			break;
		case "/sensors":
			handle_sensors(writer);
			break;
		case "/region_list":
			handle_region_list(writer);
			break;					
		default:
			handle_error(writer, target);
		}		
	}



	void handle_plots(PrintWriter writer) {
		try {
			PlotInfo[] plotInfos = tsdb.getPlotInfos();
			for(PlotInfo plotInfo:plotInfos) {
				writer.println(plotInfo.toString());
			}
		} catch (Exception e) {
			writer.println("error");
		}
	}
	
	void handle_sensors(PrintWriter writer) {
		try {
			Sensor[] sensors = tsdb.getSensors();
			for(Sensor sensor:sensors) {
				writer.println(sensor.name+"  "+sensor.description+"  "+sensor.unitDescription);
			}
		} catch (Exception e) {
			writer.println("error");
		}
	}

	void handle_error(PrintWriter writer, String target) {
		writer.println("error: unknown query: "+target);
	}
	
	private void handle_region_list(PrintWriter writer) {
		try {
			String[] regions = tsdb.getRegionLongNames();
			boolean notFirst = false;
			for(String region:regions) {
				if(notFirst) {
					writer.print('\n');
				}
				writer.print(region);
				notFirst = true;
			}
		} catch (Exception e) {
			writer.println("error");
		}
	}	
}
