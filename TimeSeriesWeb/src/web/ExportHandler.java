package web;

import java.io.BufferedReader;
import static tsdb.util.Util.log;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.util.ArrayList;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.eclipse.jetty.server.Request;
import org.eclipse.jetty.server.handler.AbstractHandler;
import org.json.JSONObject;
import org.json.JSONWriter;

import tsdb.DataQuality;
import tsdb.Region;
import tsdb.aggregated.AggregationInterval;
import tsdb.remote.RemoteTsDB;
import tsdb.util.ZipExport;

public class ExportHandler extends AbstractHandler {

	private static class ExportModel{

		public String[] plots;
		public String[] sensors;
		public boolean interpolate;
		public boolean description;
		public boolean allinone;
		public AggregationInterval aggregationInterval;
		public DataQuality quality;
		public Region region;

		public ExportModel() {
			this.plots = new String[]{"plot1","plot2","plot3"};
			this.sensors = new String[]{"sensor1","sensor2","sensor3","sensor4"};
			this.interpolate = false;
			this.description = true;
			this.allinone = false;
			this.aggregationInterval = AggregationInterval.DAY;
			this.quality = DataQuality.STEP;
			this.region = null;
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
			model.plots = new String[]{"HEG01","HEG02"};
			model.sensors = new String[]{"Ta_200",};
			try {
				model.region = tsdb.getRegions()[0];
			} catch(Exception e) {
				log.error(e);
			}
		}
		ExportModel model = (ExportModel) session.getAttribute("ExportModel");
		boolean ret = false;

		switch(target) {
		case "/plots": {
			ret = handle_plots(response.getWriter(),model);
			break;
		}
		case "/sensors": {
			ret = handle_sensors(response.getWriter(),model);
			break;
		}
		case "/apply_plots": {
			ArrayList<String> lines = new ArrayList<String>();
			BufferedReader reader = new BufferedReader(new InputStreamReader(request.getInputStream()));
			String line = reader.readLine();
			while(line!=null) {
				lines.add(line);
				line = reader.readLine();
			}			
			ret = apply_plots(response.getWriter(),model,lines);
			break;
		}
		case "/apply_sensors": {
			ArrayList<String> lines = new ArrayList<String>();
			BufferedReader reader = new BufferedReader(new InputStreamReader(request.getInputStream()));
			String line = reader.readLine();
			while(line!=null) {
				lines.add(line);
				line = reader.readLine();
			}			
			ret = apply_sensors(response.getWriter(),model,lines);
			break;
		}
		case "/result.zip": {
			ret = handle_download(response,model);
			break;
		}
		case "/settings": {
			ret = handle_settings(response.getWriter(),model);
			break;
		}
		case "/apply_settings": {
			BufferedReader reader = new BufferedReader(new InputStreamReader(request.getInputStream()));
			ret = apply_settings(reader,model);
			break;
		}
		case "/region": {
			ret = handle_region(response.getWriter(),model);
			break;
		}
		case "/apply_region": {
			BufferedReader reader = new BufferedReader(new InputStreamReader(request.getInputStream()));
			ret = handle_apply_region(reader,model);
			break;
		}		
		default: {
			ret = handle_error(response.getWriter(), target);
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

	private boolean apply_plots(PrintWriter writer, ExportModel model, ArrayList<String> lines) {		
		model.plots = lines.toArray(new String[0]);		
		System.out.println(lines);
		return true;
	}

	private boolean apply_sensors(PrintWriter writer, ExportModel model, ArrayList<String> lines) {
		model.sensors = lines.toArray(new String[0]);
		System.out.println(lines);
		return true;
	}

	private boolean handle_download(HttpServletResponse response, ExportModel model) {
		response.setContentType("application/zip");
		try {
			OutputStream outputstream = response.getOutputStream();
			String[] sensorNames = model.sensors;
			String[] plotIDs = model.plots;
			AggregationInterval aggregationInterval = model.aggregationInterval;
			DataQuality dataQuality = model.quality;
			boolean interpolated = model.interpolate;
			ZipExport zipexport = new ZipExport(tsdb, sensorNames, plotIDs, aggregationInterval, dataQuality, interpolated);
			zipexport.writeToStream(outputstream);
			//writer.print("download");
			return true;
		} catch (IOException e) {
			e.printStackTrace();
			return false;
		}	
	}

	private boolean handle_settings(PrintWriter writer, ExportModel model) {

		JSONWriter json = new JSONWriter(writer);
		json.object();
		json.key("interpolate");
		json.value(model.interpolate);
		json.key("description");
		json.value(model.description);
		json.key("allinone");
		json.value(model.allinone);
		json.key("timestep");
		json.value(model.aggregationInterval.getText());
		json.key("quality");
		json.value(model.quality.getText());
		json.endObject();


		return true;
	}

	private boolean apply_settings(BufferedReader reader, ExportModel model) {
		try {
			String line = reader.readLine();
			JSONObject json = new JSONObject(line);
			model.interpolate = json.getBoolean("interpolate");
			model.description = json.getBoolean("description");
			model.allinone = json.getBoolean("allinone");
			model.aggregationInterval = AggregationInterval.parse(json.getString("timestep"));
			model.quality = DataQuality.parse(json.getString("quality"));
			return true;
		} catch (Exception e) {
			e.printStackTrace();
			return false;
		}

	}

	private boolean handle_region(PrintWriter writer, ExportModel model) {
		writer.print(model.region.name+";"+model.region.longName);
		return true;
	}

	private boolean handle_apply_region(BufferedReader reader, ExportModel model) {
		try {
			String line = reader.readLine();
			for(Region region:tsdb.getRegions()) {
				if(region.name.equals(line)) {
					if(!model.region.name.equals(region.name)) {
						model.region = region;
						model.plots = new String[0];
						model.sensors = new String[0];
					}					
					return true;
				}
			}
			return false;
		} catch (Exception e) {
			e.printStackTrace();
			return false;
		}
	}

}
