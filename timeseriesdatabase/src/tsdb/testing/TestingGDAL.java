package tsdb.testing;
import java.nio.ByteBuffer;

import org.gdal.gdal.Band;
import org.gdal.gdal.Dataset;
import org.gdal.gdal.gdal;
import org.gdal.gdalconst.gdalconst;
import org.gdal.gdalconst.gdalconstConstants;
import org.gdal.osr.CoordinateTransformation;
import org.gdal.osr.SpatialReference;
import org.la4j.inversion.GaussJordanInverter;
import org.la4j.matrix.Matrix;
import org.la4j.matrix.dense.Basic2DMatrix;
import org.la4j.vector.Vector;
import org.la4j.vector.dense.BasicVector;


public class TestingGDAL {

	public static void main(String[] args) {

		//cof1 Easting:305573 Northing:9641686 Elevation:1303.08

		gdal.AllRegister();
		String filename = "DEM_ARC1960_30m_Hemp.tif";
		Dataset dataset = gdal.Open(filename);
		System.out.println("Description: "+dataset.GetDescription());
		System.out.println("Metadata: "+dataset.GetMetadata_Dict());
		System.out.println("Projection: "+dataset.GetProjection());
		System.out.println("Projection: "+dataset.GetGCPProjection());
		System.out.println("RasterCount: "+dataset.GetRasterCount());
		System.out.println("RasterXSize: "+dataset.getRasterXSize());
		System.out.println("RasterYSize: "+dataset.getRasterYSize());




		double[] GT = dataset.GetGeoTransform();
		for(int i=0;i<GT.length;i++) {
			System.out.println(i+". geo: "+GT[i]);
		}

		int Xpixel = dataset.getRasterXSize();
		int Yline = dataset.getRasterYSize();
		double Xgeo = GT[0] + Xpixel*GT[1] + Yline*GT[2];
		double Ygeo = GT[3] + Xpixel*GT[4] + Yline*GT[5];

		System.out.println(Xpixel+" "+Yline+" -> "+Xgeo+","+Ygeo);

		Band band = dataset.GetRasterBand(1);

		System.out.println("BlockXSize: "+band.GetBlockXSize());
		System.out.println("BlockYSize: "+band.GetBlockYSize());
		System.out.println("DataType: "+band.getDataType());

		System.out.println("byte: "+gdalconst.GDT_Float32);


		SpatialReference src = new SpatialReference("");
		src.ImportFromProj4("+proj=utm +zone=37 +south +ellps=clrk80 +towgs84=-160,-6,-302,0,0,0,0 +units=m +no_defs");

		SpatialReference dst = new SpatialReference("");
		dst.ImportFromWkt(dataset.GetProjection());
		dst.ImportFromProj4("+proj=latlong +datum=WGS84 +no_defs");


		CoordinateTransformation ct = CoordinateTransformation.CreateCoordinateTransformation(src, dst);

		double[] source = new double[]{305570.1448, 9641685.5932};//cof1
		//double[] source = new double[]{361248.9375,9612620.0};//raster
		double[] result = ct.TransformPoint(source[0],source[1]);

		System.out.println("from: "+source[0]+"  "+source[1]);
		System.out.println("to: "+result[0]+"  "+result[1]);

		Matrix a = new Basic2DMatrix(new double[][]{
				{ GT[1], GT[4], 0},
				{ GT[2], GT[5], 0 },
				{ GT[0], GT[3], 1 }
		});

		a = new Basic2DMatrix(new double[][]{
				{ GT[1], GT[2], GT[0] },
				{ GT[4], GT[5], GT[3] },
				{ 0, 0, 1 }
		});

		Vector np = a.multiply(new BasicVector(new double[]{Xpixel,Yline,1}));
		System.out.println("np: "+np);



		System.out.println(a.toString());

		Matrix b = new GaussJordanInverter(a).inverse();

		System.out.println(b.toString());

		Vector arg0 = new BasicVector(new double[]{source[0],source[1],1});
		Vector arg1 = b.multiply(arg0 );

		System.out.println(arg0);
		System.out.println(arg1);

		ByteBuffer bb = ByteBuffer.allocateDirect(band.GetBlockXSize()*band.GetBlockYSize()*4);


		/*byte[] bytes = new byte[100000];
		int rx=0;
		int ry=0;
		System.out.println("read: "+band.ReadRaster_Direct(rx,ry,1,1,1,1,gdalconstConstants.GDT_Byte,bb,0,0));
		//byteBuffer.reset();
		System.out.println(INT_little_endian_TO_big_endian(bb.getInt()));
		System.out.println(bytes[1]);
		System.out.println(bytes[2]);
		System.out.println(bytes[3]);
		System.out.println(bytes[4]);
		System.out.println(bytes[5]);

		BasicVector v = new BasicVector(new double[]{10,30,1});

		System.out.println(v+" -> "+a.multiply(v)+" -> "+b.multiply(a.multiply(v)));*/

		System.out.println(band.ReadRaster_Direct((int)arg1.get(0), (int)arg1.get(1),1,1,1,1,gdalconstConstants.GDT_Float32, bb,0,0));
		bb.position(0);

		float i = Float.intBitsToFloat(swabInt(bb.getInt()));
		System.out.println(i);
		//System.out.println(INT_little_endian_TO_big_endian(i));
		//System.out.println(swabInt(i));

	}

	public final static int swabInt(int v) {
		return  (v >>> 24) | (v << 24) | ((v << 8) & 0x00FF0000) | ((v >> 8) & 0x0000FF00);
	}

}
