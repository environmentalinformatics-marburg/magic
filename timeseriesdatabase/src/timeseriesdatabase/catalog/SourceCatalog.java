package timeseriesdatabase.catalog;

import java.io.File;
import java.util.Collection;
import java.util.List;
import java.util.NavigableSet;
import java.util.Set;
import java.util.TreeSet;
import java.util.stream.Collector;
import java.util.stream.Collectors;

import org.mapdb.BTreeMap;
import org.mapdb.Bind;
import org.mapdb.Bind.MapWithModificationListener;
import org.mapdb.DB;
import org.mapdb.DBMaker;
import org.mapdb.Fun;
import org.mapdb.Fun.Function2;
import org.mapdb.Fun.Tuple2;

public class SourceCatalog {

	private static final String DB_FILENAME_PREFIX = "SourceCatalog";
	private static final String DB_NAME_SOURCE_CATALOG = "SourceCatalog";

	private DB db;
	private BTreeMap<String, SourceEntry> catalogMap;

	public SourceCatalog(String databasePath) {
		try{
			this.db = DBMaker.newFileDB(new File(databasePath+DB_FILENAME_PREFIX))
					//.compressionEnable()
					.transactionDisable() //!!
					.mmapFileEnable() //!!
					.asyncWriteEnable() //!!
					.cacheSize(100000)  //!!
					.closeOnJvmShutdown()
					.make();
		} catch(Exception e) { // workaround for empty database open error
			this.db = DBMaker.newFileDB(new File(databasePath+DB_FILENAME_PREFIX))
					//.compressionEnable()
					.transactionDisable() //!!
					.mmapFileEnable() //!!
					.asyncWriteEnable() //!!
					.cacheSize(100000)  //!!
					.closeOnJvmShutdown()
					.make();
		}

		if(db.getAll().containsKey(DB_NAME_SOURCE_CATALOG)) {
			this.catalogMap = db.getTreeMap(DB_NAME_SOURCE_CATALOG);
		} else {
			this.catalogMap =  db.createTreeMap(DB_NAME_SOURCE_CATALOG).makeStringMap();
		}


		/*
		Function2<String, String, SourceEntry> fun = new Fun.Function2<String, String, SourceEntry>() {
			@Override
			public String run(String key, SourceEntry value) {
				// TODO Auto-generated method stub
				return value.stationName;
			}
        };
		MapWithModificationListener<String, SourceEntry> map = catalogMap;
		Set<Tuple2<String,String>> secondary = new TreeSet<Fun.Tuple2<String,String>>();		
		Bind.secondaryKey(map, secondary, fun);
		 */


	}

	public void clear() {
		catalogMap.clear();
	}

	public void insert(SourceEntry sourceEntry) {
		catalogMap.put(sourceEntry.filename.toString(), sourceEntry);
	}

	public Collection<SourceEntry> getEntries() {
		return catalogMap.values();
	}

	public List<SourceEntry> getEntriesWithStationName(String stationName) {		
		return getEntries().stream().filter((SourceEntry x)->x.stationName.equals(stationName)).collect(Collectors.toList());		
	}

}
