import java.io.IOException;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.util.Enumeration;

import javax.servlet.ServletException;
import javax.servlet.ServletOutputStream;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.eclipse.jetty.server.Handler;
import org.eclipse.jetty.server.Request;
import org.eclipse.jetty.server.Server;
import org.eclipse.jetty.server.handler.AbstractHandler;
import org.eclipse.jetty.server.handler.DefaultHandler;
import org.eclipse.jetty.server.handler.HandlerList;
import org.eclipse.jetty.server.handler.ResourceHandler;















import org.json.JSONArray;

import tsdb.DataQuality;
import tsdb.aggregated.AggregationInterval;
import tsdb.raw.TimeSeriesEntry;
import tsdb.raw.TimestampSeries;
import tsdb.server.TSDServerInterface;
import tsdb.usecase.QualityFlag;
import tsdb.util.CSV;
import tsdb.util.CSVTimeType;
import tsdb.util.Util;
import tsdb.util.iterator.TimeSeriesIterator;


public class QueryHandler extends AbstractHandler {

	private TSDServerInterface stub;

	public QueryHandler(TSDServerInterface stub) {
		this.stub = stub;
	}

	@Override
	public void handle(String target, Request baseRequest, HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {

		System.out.println("QueryHandler baseRequest: "+baseRequest.getRequestURL());
		System.out.println("request: "+request.getRequestURI());

		System.out.println("request.getParameterNames(): ");
		Enumeration<String> re = request.getParameterNames();
		while(re.hasMoreElements()) {
			String e = re.nextElement();
			String v = request.getParameter(e);
			System.out.println(e+" -> "+v);
		}

		String uri = request.getRequestURI();


		System.out.println("uri: ["+uri+"]");




		if(uri.equals("/timeseries.csv")||uri.equals("/timeseries.html")) {

			boolean useHtml = false;

			if(uri.equals("/timeseries.html")) {
				System.out.println("process query timeseries.html");
				useHtml = true;
			} else {
				System.out.println("process query timeseries.csv");
			}			

	

			String plotID = "HEG01";

			String r = request.getParameter("plotid");
			if(r!=null) {
				plotID = r;
			}

			String[] querySchema = null;
			Long queryStart = null;
			Long queryEnd = null;
			DataQuality dataQuality = DataQuality.EMPIRICAL;
			AggregationInterval aggregationInterval = AggregationInterval.DAY;
			boolean interpolated = false;

			System.out.println("query: "+plotID);

			TimestampSeries result = stub.query(plotID, querySchema, queryStart, queryEnd, dataQuality, aggregationInterval, interpolated);

			TimeSeriesIterator it = result.timeSeriesIterator();

			String[] schema = it.getOutputSchema();
			
			if(!useHtml) { // CSV
				response.setContentType("text/csv;charset=utf-8");
				response.setStatus(HttpServletResponse.SC_OK);
				baseRequest.setHandled(true);
				
				
				
				OutputStream out = response.getOutputStream();
				
				CSV.write(it, true, out, ",", "NA", CSVTimeType.TIMESTAMP_AND_DATETIME,false,false);
				
				
				/*PrintWriter out = response.getWriter();
				 * while(it.hasNext()) {
					out.println(Util.arrayToString(it.next().data));
				}*/
			} else { // HTML				
				response.setContentType("text/html;charset=utf-8");
				response.setStatus(HttpServletResponse.SC_OK);
				baseRequest.setHandled(true);
				
				PrintWriter out = response.getWriter();
				
				
				out.println("<html>");
				
				out.println("<head><style>table,th,td{border:1px solid black;font-family:monospace;border-collapse:collapse;}th,td{padding:5px;}</style></head>");
				
				
				
				
				
				out.println("<body>");
				out.println("<h1>TimeSeriesDatabase Web Interface</h1>");
				out.println("<a href=\"timeseries\">timeseries</a><br>");
				out.println("<table>");
				
				
				
				out.println("<th>");
				out.println("timestamp");
				out.println("</th>");
				
				for(int i=0;i<schema.length;i++) {
					out.println("<th>");
					out.println(schema[i]);
					out.println("</th>");
				}
				
				
				while(it.hasNext()) {
					out.println("<tr>");
					
					TimeSeriesEntry element = it.next();
					
					out.println("<td>");
					out.println(element.timestamp);
					out.println("</td>");
					
					float[] data = element.data;
					
					for(int i=0;i<data.length;i++) {
						out.println("<td>");
						out.println(Util.floatToString(data[i]));
						out.println("</td>");
					}

					out.println("</tr>");
				}
				
				
				out.println("</table>");


				


				out.println("</body>");
				out.println("</html>");				
				
			}
			

			

		} // end of *** timeseries.csv, timeseries.html
		else if(uri.equals("/plotids.json")) {
			response.setContentType("text/html;charset=utf-8");
			response.setStatus(HttpServletResponse.SC_OK);
			baseRequest.setHandled(true);
			
			String generalstation = "HEG";

			String r = request.getParameter("generalstation");
			if(r!=null) {
				generalstation = r;
			}
			
			String[] plotids = stub.queryPlotIds(generalstation);
			
			if(plotids==null) {
				plotids = new String[0];
			}
			
			//String[] plotids = new String[]{"HEG01","HEW01","HEG02","HEG03","HEG04"};
			
			JSONArray json = new JSONArray(plotids);
			
			System.out.println(json.toString());
			
			PrintWriter out = response.getWriter();
			out.print(json);
			
			
			
			
		} else if(uri.equals("/generalstations.json")) {
			response.setContentType("text/html;charset=utf-8");
			response.setStatus(HttpServletResponse.SC_OK);
			baseRequest.setHandled(true);
			
			
			
			String[] generalstaions = stub.queryGeneralStations();
			
			if(generalstaions==null) {
				generalstaions = new String[0];
			}
			
			//String[] plotids = new String[]{"HEG01","HEW01","HEG02","HEG03","HEG04"};
			
			JSONArray json = new JSONArray(generalstaions);
			
			System.out.println(json.toString());
			
			PrintWriter out = response.getWriter();
			out.print(json);
			
			
			
			
		}
	}

}
