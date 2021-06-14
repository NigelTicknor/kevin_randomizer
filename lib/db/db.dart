import 'package:moor/moor.dart';

export 'db/shared.dart';

// assuming that your file is called filename.dart. This will give an error at first,
// but it's needed for moor to know about the generated code
part 'db.g.dart';

// this will generate a table called "todos" for us. The rows of that table will
// be represented by a class called "Todo".
@DataClassName("Category")
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 32)();
}

// This will make moor generate a class called "Category" to represent a row in this table.
// By default, "Categorie" would have been used because it only strips away the trailing "s"
// in the table name.
@DataClassName("Entry")
class Entries extends Table {

  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer()
      .nullable()
      .customConstraint('NULLABLE REFERENCES categories(id)')();
  TextColumn get entry => text().withLength(min: 1, max: 32)();
}

// this annotation tells moor to prepare a database class that uses both of the
// tables we just defined. We'll see how to use that database class in a moment.
@UseMoor(tables: [Categories, Entries])
class MyDatabase extends _$MyDatabase {
  // we tell the database where to store the data with this constructor
  MyDatabase(QueryExecutor e) : super(e);

  // you should bump this number whenever you change or add a table definition. Migrations
  // are covered later in this readme.
  @override
  int get schemaVersion => 1;


  // loads all categories
  Future<List<Category>> get allCategories => select(categories).get();

  Future<int> addCategory(String category) {
    return into(categories).insert(CategoriesCompanion(id: Value.absent(), title: Value(category)));
  }

  Future<int> removeCategory(int categoryId) {
    (delete(entries)..where((tbl) => tbl.categoryId.equals(categoryId))).go();
    return (delete(categories)..where((tbl) => tbl.id.equals(categoryId))).go();
  }

  Future<List<Entry>> getEntriesForCategory(int categoryId) {
    return (select(entries)..where((tbl) => tbl.categoryId.equals(categoryId))).get();
  }

  Future<int> addEntry(int categoryId, String entry) {
    return into(entries).insert(EntriesCompanion(id: Value.absent(), categoryId: Value(categoryId), entry: Value(entry)));
  }

  Future<int> deleteEntry(int entryId) {
    return (delete(entries)..where((tbl) => tbl.id.equals(entryId))).go();
  }
}