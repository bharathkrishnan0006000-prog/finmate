import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/categories_table.dart';

part 'categories_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoriesDao extends DatabaseAccessor<AppDatabase>
    with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  Future<void> insertCategory(CategoriesCompanion entry) =>
      into(categories).insertOnConflictUpdate(entry);

  Future<void> insertBatch(List<CategoriesCompanion> entries) =>
      batch((b) => b.insertAllOnConflictUpdate(categories, entries));

  Future<void> deleteCategory(String id) => (update(categories)
        ..where((c) => c.id.equals(id)))
      .write(const CategoriesCompanion(isDeleted: Value(true)));

  Stream<List<Category>> watchByType(String type) {
    return (select(categories)
          ..where((c) => c.type.equals(type) & c.isDeleted.equals(false))
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .watch();
  }

  Future<List<Category>> allActive() => (select(categories)
        ..where((c) => c.isDeleted.equals(false)))
      .get();

  Future<int> count() async {
    final rows = await select(categories).get();
    return rows.length;
  }
}
