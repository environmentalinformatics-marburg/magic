package tsdb.web.api;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.eclipse.jetty.server.Request;

import tsdb.remote.RemoteTsDB;

//TODO
public class Handler_plot_location extends MethodHandler {
	private static final Logger log = LogManager.getLogger();
	
	public Handler_plot_location(RemoteTsDB tsdb, String handlerMethodName) {
		super(tsdb, "plot_location");
	}

	@Override
	public void handle(String target, Request baseRequest, HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {
		//TODO
		
	}
}
