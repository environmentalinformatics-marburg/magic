package tsdb.web.api;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.Arrays;
import java.util.function.Function;
import java.util.function.Predicate;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.eclipse.jetty.server.Request;

import tsdb.remote.GeneralStationInfo;
import tsdb.remote.PlotInfo;
import tsdb.remote.RemoteTsDB;

public class Handler_plot_list extends MethodHandler {	
	private static final Logger log = LogManager.getLogger();

	public Handler_plot_list(RemoteTsDB tsdb) {
		super(tsdb, "plot_list");
	}

	@Override
	public void handle(String target, Request baseRequest, HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {
		baseRequest.setHandled(true);
		response.setContentType("text/plain;charset=utf-8");
		String generalstationName = request.getParameter("generalstation");
		String regionName = request.getParameter("region");
		if((generalstationName==null&&regionName==null)||(generalstationName!=null&&regionName!=null)) {
			log.warn("wrong call");
			response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
			return;
		}
		try {
			PlotInfo[] plotInfos = tsdb.getPlotInfos();
			if(plotInfos==null) {
				log.error("plotInfos null: ");
				response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);				
				return;
			}
			Predicate<PlotInfo> plotFilter;
			if(generalstationName!=null) {
				plotFilter = p->p.generalStationInfo.name.equals(generalstationName);
			} else {
				plotFilter = p->p.generalStationInfo.region.name.equals(regionName);
			}
			String[] webList = Arrays.stream(plotInfos)
					.filter(plotFilter)
					.map(p->p.name)
					.toArray(String[]::new);
			PrintWriter writer = response.getWriter();
			writeStringArray(writer, webList);
			response.setStatus(HttpServletResponse.SC_OK);
		} catch (Exception e) {
			log.error(e);
			response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
		}
	}
}
