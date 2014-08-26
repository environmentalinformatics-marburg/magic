import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.eclipse.jetty.server.Handler;
import org.eclipse.jetty.server.Request;
import org.eclipse.jetty.server.Server;
import org.eclipse.jetty.server.handler.AbstractHandler;
import org.eclipse.jetty.server.handler.DefaultHandler;
import org.eclipse.jetty.server.handler.HandlerList;
import org.eclipse.jetty.server.handler.ResourceHandler;








import tsdb.DataQuality;
import tsdb.aggregated.AggregationInterval;
import tsdb.raw.TimestampSeries;
import tsdb.server.TSDServerInterface;
import tsdb.util.Util;
import tsdb.util.iterator.TimeSeriesIterator;


public class TestingHandler extends AbstractHandler {
	
	private TSDServerInterface stub;
	
	public TestingHandler(TSDServerInterface stub) {
		this.stub = stub;
	}

	@Override
	public void handle(String target, Request baseRequest, HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {

		System.out.println("TestingHandler baseRequest: "+baseRequest.getRequestURL());
		System.out.println("request: "+request.getRequestURI());

		String uri = request.getRequestURI();

		if(uri.equals("/timeseries")) {

			response.setContentType("text/html;charset=utf-8");
			response.setStatus(HttpServletResponse.SC_OK);
			baseRequest.setHandled(true);
			response.getWriter().println("<html>");
			response.getWriter().println("<body>");
			response.getWriter().println("<h1>time series</h1>");
			response.getWriter().println("</body>");
			response.getWriter().println("</html>");

		} else {

			response.setContentType("text/html;charset=utf-8");
			response.setStatus(HttpServletResponse.SC_OK);
			baseRequest.setHandled(true);
			response.getWriter().println("<html>");
			response.getWriter().println("<body>");
			response.getWriter().println("<h1>TimeSeriesDatabase Web Interface</h1>");
			response.getWriter().println("<a href=\"timeseries\">timeseries</a><br>");



			String plotID = "HEG01";
			String[] querySchema = null;
			Long queryStart = null;
			Long queryEnd = null;
			DataQuality dataQuality = DataQuality.EMPIRICAL;
			AggregationInterval aggregationInterval = AggregationInterval.DAY;
			boolean interpolated = false;
			TimestampSeries result = stub.query(plotID, querySchema, queryStart, queryEnd, dataQuality, aggregationInterval, interpolated);

			TimeSeriesIterator it = result.timeSeriesIterator();

			while(it.hasNext()) {
				response.getWriter().println(Util.arrayToString(it.next().data)+"<br>");
			}


			response.getWriter().println("</body>");
			response.getWriter().println("</html>");

		}
	}

}
