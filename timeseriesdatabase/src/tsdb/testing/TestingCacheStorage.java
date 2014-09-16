package tsdb.testing;

import tsdb.CacheStorage;

public class TestingCacheStorage {

	public static void main(String[] args) {
		String cachePath = "c:/temp/";
		CacheStorage cacheStorage = new CacheStorage(cachePath);
		//cacheStorage.clear();
		cacheStorage.printInfo();
		cacheStorage.close();

	}

}
