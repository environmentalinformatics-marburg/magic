package web;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.eclipse.jetty.server.Request;
import org.eclipse.jetty.server.handler.AbstractHandler;

import tsdb.remote.RemoteTsDB;

public class ExportHandler extends AbstractHandler {
	
	private static class ExportModel{

		public String[] plots;
		public String[] sensors;

		public ExportModel() {
			this.plots = new String[]{"plot1","plot2","plot3"};
			this.sensors = new String[]{"sensor1","sensor2","sensor3","sensor4"};
		}
	}

	private final RemoteTsDB tsdb;

	public ExportHandler(RemoteTsDB tsdb) {
		this.tsdb = tsdb;
	}

	@Override
	public void handle(String target, Request baseRequest, HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {
		System.out.println("ExportHandler: "+target);
		baseRequest.setHandled(true);
		response.setContentType("text/plain;charset=utf-8");

		HttpSession session = request.getSession();
		if(session.isNew()) {
			ExportModel model = new ExportModel();
			session.setAttribute("ExportModel", model);
			model.plots = tsdb.getStationNames();
		}
		ExportModel model = (ExportModel) session.getAttribute("ExportModel");

		PrintWriter writer = response.getWriter();


		boolean ret = false;

		switch(target) {
		case "/plots": {
			ret = handle_plots(writer,model);
			break;
		}
		case "/sensors": {
			ret = handle_sensors(writer,model);
			break;
		}
		default: {
			ret = handle_error(writer, target);
		}
		}

		if(ret) {
			response.setStatus(HttpServletResponse.SC_OK);
		} else {
			response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
		}
	}

	private boolean handle_error(PrintWriter writer, String target) {
		writer.println("error: unknown query: "+target);
		return false;
	}

	private boolean handle_plots(PrintWriter writer, ExportModel model) {		
		writeStringArray(writer,model.plots);
		return true;
	}
	
	private boolean handle_sensors(PrintWriter writer, ExportModel model) {		
		writeStringArray(writer,model.sensors);		
		return true;
	}
	
	private static void writeStringArray(PrintWriter writer, String[] array) {
		if(array==null) {
			return;
		}
		boolean notFirst = false;
		for(String s:array) {
			if(notFirst) {
				writer.print('\n');
			}
			writer.print(s);
			notFirst = true;
		}
	}

}
