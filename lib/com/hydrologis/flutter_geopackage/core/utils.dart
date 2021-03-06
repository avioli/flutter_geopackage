part of flutter_geopackage;

class SQLException implements Exception {
  String msg;

  SQLException(this.msg);

  String toString() => "SQLException: " + msg;
}

/// A simple table info.
///
/// <p>If performance is needed, this should not be used.</p>
class QueryResult {
  String geomName;

  /// This can optionally be used to identify record sources
  /// in case of mixed data sources (ex. merging together
  /// QueryResults from different queries.
  List<String> ids;

  List<Geometry> geoms = [];

  List<Map<String, dynamic>> data = [];
}

/// Class representing a geometry_columns record.
class GeometryColumn {
  // VARIABLES
  String tableName;
  String geometryColumnName;

  /// The type, as compatible with {@link EGeometryType#fromGeometryTypeCode(int)} and {@link ESpatialiteGeometryType#forValue(int)}.
  EGeometryType geometryType;
  int coordinatesDimension;
  int srid;
  int isSpatialIndexEnabled;
}

class GeometryUtilities {
  /// Create a polygon of the supplied [env].
  ///
  /// In case of [makeCircle] set to true, a buffer of half the width
  /// of the [env] is created in the center point.
  static Geometry fromEnvelope(Envelope env, {bool makeCircle = false}) {
    double w = env.getMinX();
    double e = env.getMaxX();
    double s = env.getMinY();
    double n = env.getMaxY();

    if (makeCircle) {
      var centre = env.centre();
      var point = GeometryFactory.defaultPrecision().createPoint(centre);
      var buffer = point.buffer(env.getWidth() / 2.0);
      return buffer;
    }
    return GeometryFactory.defaultPrecision().createPolygonFromCoords([
      Coordinate(w, s),
      Coordinate(w, n),
      Coordinate(e, n),
      Coordinate(e, s),
      Coordinate(w, s),
    ]);
  }
}

class DataType {
  static const Feature = const DataType._("features");
  static const Tile = const DataType._("tiles");

  final String value;

  const DataType._(this.value);

  static DataType of(String type) {
    if (type == Feature.value) {
      return Feature;
    } else if (type == Tile.value) {
      return Tile;
    } else {
      return null;
    }
  }
}

/// Entry in a geopackage.
///
/// <p>This class corresponds to the "geopackage_contents" table.
///
/// @author Justin Deoliveira, OpenGeo
class Entry {
  String tableName;
  DataType dataType;
  String identifier;
  String description;
  Envelope bounds;
  int srid;

  String getTableName() {
    return tableName;
  }

  void setTableName(String tableName) {
    this.tableName = tableName;
  }

  DataType getDataType() {
    return dataType;
  }

  void setDataType(DataType dataType) {
    this.dataType = dataType;
  }

  String getIdentifier() {
    return identifier;
  }

  void setIdentifier(String identifier) {
    this.identifier = identifier;
  }

  String getDescription() {
    return description;
  }

  void setDescription(String description) {
    this.description = description;
  }

  Envelope getBounds() {
    return bounds;
  }

  void setBounds(Envelope bounds) {
    this.bounds = bounds;
  }

  int getSrid() {
    return srid;
  }

  void setSrid(int srid) {
    this.srid = srid;
  }

  void init(Entry e) {
    setDescription(e.getDescription());
    setIdentifier(e.getIdentifier());
    setDataType(e.getDataType());
    setBounds(e.getBounds());
    setSrid(e.getSrid());
    setTableName(e.getTableName());
  }

  Entry copy() {
    Entry e = new Entry();
    e.init(this);
    return e;
  }
}

/// Feature entry in a geopackage.
///
/// <p>This class corresponds to the "geometry_columns" table.
///
/// @author Justin Deoliveira, OpenGeo
/// @author Niels Charlier
class FeatureEntry extends Entry {
  EGeometryType geometryType;
  bool z = false;
  bool m = false;
  String geometryColumn;

  FeatureEntry() {
    setDataType(DataType.Feature);
  }

  String getGeometryColumn() {
    return geometryColumn;
  }

  void setGeometryColumn(String geometryColumn) {
    this.geometryColumn = geometryColumn;
  }

  EGeometryType getGeometryType() {
    return geometryType;
  }

  void setGeometryType(EGeometryType geometryType) {
    this.geometryType = geometryType;
  }

  void init(Entry e) {
    super.init(e);
    if (e is FeatureEntry) {
      setGeometryColumn(e.getGeometryColumn());
      setGeometryType(e.getGeometryType());
      setZ(e.isZ());
      setM(e.isM());
    }
  }

  bool isZ() {
    return z;
  }

  void setZ(bool z) {
    this.z = z;
  }

  bool isM() {
    return m;
  }

  void setM(bool m) {
    this.m = m;
  }

  FeatureEntry copy() {
    FeatureEntry e = new FeatureEntry();
    e.init(this);
    return e;
  }
}

/// Tiles Entry inside a GeoPackage.
///
/// @author Justin Deoliveira
/// @author Niels Charlier
/// @author Andrea Antonello (www.hydrologis.com)
class TileEntry extends Entry {
  List<TileMatrix> tileMatricies = [];

  Envelope tileMatrixSetBounds;

  TileEntry() {
    setDataType(DataType.Tile);
  }

  List<TileMatrix> getTileMatricies() {
    return tileMatricies;
  }

  void setTileMatricies(List<TileMatrix> tileMatricies) {
    this.tileMatricies = tileMatricies;
  }

  void init(Entry e) {
    super.init(e);
    TileEntry te = e as TileEntry;
    setTileMatricies(te.getTileMatricies());
    this.tileMatrixSetBounds = te.tileMatrixSetBounds == null ? null : new Envelope.fromEnvelope(te.tileMatrixSetBounds);
  }

  /// Returns the tile matrix set bounds. The bounds are expressed in the same CRS as the entry,
  /// but they might differ in extent (if null, then the tile matrix bounds are supposed to be the
  /// same as the entry)
  Envelope getTileMatrixSetBounds() {
    return tileMatrixSetBounds != null ? tileMatrixSetBounds : bounds;
  }

  void setTileMatrixSetBounds(Envelope tileMatrixSetBounds) {
    this.tileMatrixSetBounds = tileMatrixSetBounds;
  }
}

/// A TileMatrix inside a Geopackage. Corresponds to the gpkg_tile_matrix table.
///
/// @author Justin Deoliveira
/// @author Niels Charlier
class TileMatrix {
  int zoomLevel;
  int matrixWidth, matrixHeight;
  int tileWidth, tileHeight;
  double xPixelSize;
  double yPixelSize;
  bool tiles;

  TileMatrix(this.zoomLevel, this.matrixWidth, this.matrixHeight, this.tileWidth, this.tileHeight, this.xPixelSize, this.yPixelSize);

  int getZoomLevel() {
    return zoomLevel;
  }

  void setZoomLevel(int zoomLevel) {
    this.zoomLevel = zoomLevel;
  }

  int getMatrixWidth() {
    return matrixWidth;
  }

  void setMatrixWidth(int matrixWidth) {
    this.matrixWidth = matrixWidth;
  }

  int getMatrixHeight() {
    return matrixHeight;
  }

  void setMatrixHeight(int matrixHeight) {
    this.matrixHeight = matrixHeight;
  }

  int getTileWidth() {
    return tileWidth;
  }

  void setTileWidth(int tileWidth) {
    this.tileWidth = tileWidth;
  }

  int getTileHeight() {
    return tileHeight;
  }

  void setTileHeight(int tileHeight) {
    this.tileHeight = tileHeight;
  }

  double getXPixelSize() {
    return xPixelSize;
  }

  void setXPixelSize(double xPixelSize) {
    this.xPixelSize = xPixelSize;
  }

  double getYPixelSize() {
    return yPixelSize;
  }

  void setYPixelSize(double yPixelSize) {
    this.yPixelSize = yPixelSize;
  }

  bool hasTiles() {
    return tiles;
  }

  void setTiles(bool tiles) {
    this.tiles = tiles;
  }

  String toString() {
    return "TileMatrix [zoomLevel=$zoomLevel, matrixWidth=" +
        "$matrixWidth , matrixHeight=$matrixHeight, tileWidth=" +
        "$tileWidth , tileHeight=$tileHeight, xPixelSize=" +
        "$xPixelSize, yPixelSize=$yPixelSize, tiles=$tiles]";
  }
}

/// Geometry types used by the utility.
///
/// @author Andrea Antonello (www.hydrologis.com)
class EGeometryType {
//  static const NONE = const EGeometryType._(0, 0);
  static const POINT = const EGeometryType._(Point, MultiPoint, "Point");
  static const MULTIPOINT = const EGeometryType._(MultiPoint, MultiPoint, "MultiPoint");
  static const LINESTRING = const EGeometryType._(LineString, MultiLineString, "LineString");
  static const MULTILINESTRING = const EGeometryType._(MultiLineString, MultiLineString, "MultiLineString");
  static const POLYGON = const EGeometryType._(Polygon, MultiPolygon, "Polygon");
  static const MULTIPOLYGON = const EGeometryType._(MultiPolygon, MultiPolygon, "MultiPolygon");
  static const GEOMETRYCOLLECTION = const EGeometryType._(GeometryCollection, GeometryCollection, "GeometryCollection");
  static const GEOMETRY = const EGeometryType._(Geometry, Geometry, "GEOMETRY");
  static const UNKNOWN = const EGeometryType._(null, null, "Unknown");

  final clazz;
  final multiClazz;
  final String typeName;

  const EGeometryType._(this.clazz, this.multiClazz, this.typeName);

  dynamic getClazz() {
    return clazz;
  }

  dynamic getMultiClazz() {
    return multiClazz;
  }

// static EGeometryType forClass( Class< ? > clazz ) {
//if (POINT.getClazz().isAssignableFrom(clazz)) {
//return POINT;
//} else if (MULTIPOINT.getClazz().isAssignableFrom(clazz)) {
//return MULTIPOINT;
//} else if (LINESTRING.getClazz().isAssignableFrom(clazz)) {
//return LINESTRING;
//} else if (MULTILINESTRING.getClazz().isAssignableFrom(clazz)) {
//return MULTILINESTRING;
//} else if (POLYGON.getClazz().isAssignableFrom(clazz)) {
//return POLYGON;
//} else if (MULTIPOLYGON.getClazz().isAssignableFrom(clazz)) {
//return MULTIPOLYGON;
//} else if (GEOMETRYCOLLECTION.getClazz().isAssignableFrom(clazz)) {
//return GEOMETRYCOLLECTION;
//} else if (GEOMETRY.getClazz().isAssignableFrom(clazz)) {
//return GEOMETRY;
//} else {
//return UNKNOWN;
//}
//}

  bool isMulti() {
    switch (this) {
      case MULTILINESTRING:
      case MULTIPOINT:
      case MULTIPOLYGON:
        return true;
      default:
        return false;
    }
  }

  bool isPoint() {
    switch (this) {
      case MULTIPOINT:
      case POINT:
        return true;
      default:
        return false;
    }
  }

  bool isLine() {
    switch (this) {
      case MULTILINESTRING:
      case LINESTRING:
        return true;
      default:
        return false;
    }
  }

  bool isPolygon() {
    switch (this) {
      case MULTIPOLYGON:
      case POLYGON:
        return true;
      default:
        return false;
    }
  }

  bool isCompatibleWith(EGeometryType geometryType) {
    switch (geometryType) {
      case LINESTRING:
        return this == LINESTRING;
      case MULTILINESTRING:
        return this == LINESTRING || this == MULTILINESTRING;
      case POINT:
        return this == POINT;
      case MULTIPOINT:
        return this == POINT || this == MULTIPOINT;
      case POLYGON:
        return this == POLYGON;
      case MULTIPOLYGON:
        return this == POLYGON || this == MULTIPOLYGON;
      default:
        return false;
    }
  }

  /// Returns the {@link EGeometryType} for a given {@link Geometry}.
  ///
  /// @param geometry the geometry to check.
  /// @return the type.
  static EGeometryType forGeometry(Geometry geometry) {
    if (geometry is LineString) {
      return EGeometryType.LINESTRING;
    } else if (geometry is MultiLineString) {
      return EGeometryType.MULTILINESTRING;
    } else if (geometry is Point) {
      return EGeometryType.POINT;
    } else if (geometry is MultiPoint) {
      return EGeometryType.MULTIPOINT;
    } else if (geometry is Polygon) {
      return EGeometryType.POLYGON;
    } else if (geometry is MultiPolygon) {
      return EGeometryType.MULTIPOLYGON;
    } else if (geometry is GeometryCollection) {
      return EGeometryType.GEOMETRYCOLLECTION;
    } else {
      return EGeometryType.GEOMETRY;
    }
  }

  static EGeometryType forWktName(String wktName) {
    if (StringUtils.equalsIgnoreCase(wktName, POINT.getTypeName())) {
      return POINT;
    } else if (StringUtils.equalsIgnoreCase(wktName, MULTIPOINT.getTypeName())) {
      return MULTIPOINT;
    } else if (StringUtils.equalsIgnoreCase(wktName, LINESTRING.getTypeName())) {
      return LINESTRING;
    } else if (StringUtils.equalsIgnoreCase(wktName, MULTILINESTRING.getTypeName())) {
      return MULTILINESTRING;
    } else if (StringUtils.equalsIgnoreCase(wktName, POLYGON.getTypeName())) {
      return POLYGON;
    } else if (StringUtils.equalsIgnoreCase(wktName, MULTIPOLYGON.getTypeName())) {
      return MULTIPOLYGON;
    } else if (StringUtils.equalsIgnoreCase(wktName, GEOMETRYCOLLECTION.getTypeName())) {
      return GEOMETRYCOLLECTION;
    } else if (StringUtils.equalsIgnoreCase(wktName, GEOMETRY.getTypeName())) {
      return GEOMETRY;
    }
    return UNKNOWN;
  }

  static EGeometryType forTypeName(String typeName) {
    return forWktName(typeName);
  }

  /// Checks if the given geometry is a {@link LineString} (or {@link MultiLineString}) geometry.
  ///
  /// @param geometry the geometry to check.
  /// @return <code>true</code> if there are lines in there.
  static bool isGeomLine(Geometry geometry) {
    if (geometry is LineString || geometry is MultiLineString) {
      return true;
    }
    return false;
  }

  /// Checks if the given geometry is a {@link Polygon} (or {@link MultiPolygon}) geometry.
  ///
  /// @param geometry the geometry to check.
  /// @return <code>true</code> if there are polygons in there.
  static bool isGeomPolygon(Geometry geometry) {
    if (geometry is Polygon || geometry is MultiPolygon) {
      return true;
    }
    return false;
  }

  /// Checks if the given geometry is a {@link Point} (or {@link MultiPoint}) geometry.
  ///
  /// @param geometry the geometry to check.
  /// @return <code>true</code> if there are points in there.
  static bool isGeomPoint(Geometry geometry) {
    if (geometry is Point || geometry is MultiPoint) {
      return true;
    }
    return false;
  }

  /// Returns the base geometry type for a spatialite geometries types.
  ///
  /// @param value the code.
  /// @return the type.
  static EGeometryType fromGeometryTypeCode(int value) {
    switch (value) {
      case 0:
        return GEOMETRY;
      case 1:
        return POINT;
      case 2:
        return LINESTRING;
      case 3:
        return POLYGON;
      case 4:
        return MULTIPOINT;
      case 5:
        return MULTILINESTRING;
      case 6:
        return MULTIPOLYGON;
      case 7:
        return GEOMETRYCOLLECTION;
/*
         * XYZ
         */
      case 1000:
        return GEOMETRY;
      case 1001:
        return POINT;
      case 1002:
        return LINESTRING;
      case 1003:
        return POLYGON;
      case 1004:
        return MULTIPOINT;
      case 1005:
        return MULTILINESTRING;
      case 1006:
        return MULTIPOLYGON;
      case 1007:
        return GEOMETRYCOLLECTION;
/*
         * XYM
         */
      case 2000:
        return GEOMETRY;
      case 2001:
        return POINT;
      case 2002:
        return LINESTRING;
      case 2003:
        return POLYGON;
      case 2004:
        return MULTIPOINT;
      case 2005:
        return MULTILINESTRING;
      case 2006:
        return MULTIPOLYGON;
      case 2007:
        return GEOMETRYCOLLECTION;
/*
         * XYZM
         */
      case 3000:
        return GEOMETRY;
      case 3001:
        return POINT;
      case 3002:
        return LINESTRING;
      case 3003:
        return POLYGON;
      case 3004:
        return MULTIPOINT;
      case 3005:
        return MULTILINESTRING;
      case 3006:
        return MULTIPOLYGON;
      case 3007:
        return GEOMETRYCOLLECTION;
      default:
        break;
    }
    return UNKNOWN;
  }

// ESpatialiteGeometryType toSpatialiteGeometryType() {
//switch( this ) {
//case LINESTRING:
//return ESpatialiteGeometryType.LINESTRING_XY;
//case MULTILINESTRING:
//return ESpatialiteGeometryType.MULTILINESTRING_XY;
//case POINT:
//return ESpatialiteGeometryType.POINT_XY;
//case MULTIPOINT:
//return ESpatialiteGeometryType.MULTIPOINT_XY;
//case POLYGON:
//return ESpatialiteGeometryType.POLYGON_XY;
//case MULTIPOLYGON:
//return ESpatialiteGeometryType.MULTIPOLYGON_XY;
//case GEOMETRY:
//return ESpatialiteGeometryType.GEOMETRY_XY;
//case GEOMETRYCOLLECTION:
//return ESpatialiteGeometryType.GEOMETRYCOLLECTION_XY;
//default:
//return null;
//}
//}

  String getTypeName() {
    return typeName;
  }
}

class GeopackageTableNames {
  static final String startsWithIndexTables = "rtree_";

  // METADATA
  static final List<String> metadataTables = [
    "gpkg_contents", //
    "gpkg_geometry_columns", //
    "gpkg_spatial_ref_sys", //
    "gpkg_data_columns", //
    "gpkg_tile_matrix", //
    "gpkg_metadata", //
    "gpkg_metadata_reference", //
    "gpkg_tile_matrix_set", //
    "gpkg_data_column_constraints", //
    "gpkg_extensions", //
    "gpkg_ogr_contents", //
    "gpkg_spatial_index", //
    "spatial_ref_sys", //
    "st_spatial_ref_sys", //
    "android_metadata", //
  ];

  // INTERNAL DATA
  static final List<String> internalDataTables = [
    //
    "sqlite_stat1", //
    "sqlite_stat3", //
    "sql_statements_log", //
    "sqlite_sequence" //
  ];

  static const USERDATA = "User Data";
  static const SYSTEM = "System tables";

  /// Sorts all supplied table names by type.
  ///
  /// <p>
  /// Supported types are:
  /// <ul>
  /// <li>{@value ISpatialTableNames#INTERNALDATA} </li>
  /// <li>{@value ISpatialTableNames#SYSTEM} </li>
  /// </ul>
  ///
  /// @param allTableNames list of all tables.
  /// @param doSort if <code>true</code>, table names are alphabetically sorted.
  /// @return the {@link LinkedHashMap}.
  static Map<String, List<String>> getTablesSorted(List<String> allTableNames, bool doSort) {
    Map<String, List<String>> tablesMap = {};
    tablesMap[USERDATA] = [];
    tablesMap[SYSTEM] = [];

    for (String tableName in allTableNames) {
      tableName = tableName.toLowerCase();
      if (tableName.startsWith(startsWithIndexTables) || metadataTables.contains(tableName) || internalDataTables.contains(tableName)) {
        List<String> list = tablesMap[SYSTEM];
        list.add(tableName);
        continue;
      }
      List<String> list = tablesMap[USERDATA];
      list.add(tableName);
    }

    if (doSort) {
      for (List<String> values in tablesMap.values) {
        values.sort();
      }
    }

    return tablesMap;
  }
}

class DbsUtilities {
  /// Check the tablename and fix it if necessary.
  ///
  /// @param tableName the name to check.
  /// @return the fixed name.
  static String fixTableName(String tableName) {
    double num = double.tryParse(tableName.substring(0, 1)) ?? null;
    if (num != null) return "'" + tableName + "'";
    return tableName;
  }
}
