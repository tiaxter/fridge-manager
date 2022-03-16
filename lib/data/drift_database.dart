import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:jiffy/jiffy.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

part 'drift_database.g.dart';

@DataClassName("Product")
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  DateTimeColumn get expiration => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

class ProductWithExpirationsDays {
  final Product product;
  final int expirationDays;

  ProductWithExpirationsDays(this.product, this.expirationDays);
}

@DriftDatabase(tables: [Products])
class AppDb extends _$AppDb {
  AppDb() : super(_openConnection());

  AppDb.connect(DatabaseConnection connection) : super.connect(connection);
  AppDb.connectIsolated(String dbPath) : super(_openIsolatedConnection(dbPath));

  @override
  int get schemaVersion => 1;

  Stream<List<Product>> watchProducts() {
    return (
      select(products)..where(
        (t) => t.deletedAt.isNull()
      )..orderBy([
        (t) => OrderingTerm(expression: t.expiration)
      ])
    ).watch();
  }

  Future<Product> getProductById(int id) {
    return (
      select(products)..where(
        (t) => t.id.equals(id)
      )
    ).getSingle();
  }

  Future<int> addProduct(ProductsCompanion product) {
    return into(products).insert(product);
  }

  Future updateProduct(Product product) {
    return update(products).replace(product);
  }

  Future deleteProduct(int id) {
    return (
      update(products)
      ..where(
        (t) => t.id.equals(id)
      )
    ).write(ProductsCompanion(
        deletedAt: Value(DateTime.now())
    ));
  }

  Future undoDeleteProduct(int id) {
    return (
      update(products)
      ..where(
        (t) => t.id.equals(id)
      )
    ).write(const ProductsCompanion(
        deletedAt: Value(null)
    ));
  }

  Future<List<Product>> getExpiringProducts() {
    final expirationDays = products.expiration;
    return (
      select(products)
      ..addColumns([expirationDays])
      ..where(
        (t) {
          DateTime start = Jiffy().startOf(Units.DAY).dateTime;
          DateTime end = Jiffy().add(days: 3).endOf(Units.DAY).dateTime;
          return t.expiration.isBetweenValues(start, end) & t.deletedAt.isNull();
        }
      )
    ).get();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    Directory dbFolder = await getApplicationDocumentsDirectory();
    File file = File(path.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}

LazyDatabase _openIsolatedConnection(String dbPath) {
  return LazyDatabase(() => NativeDatabase(File(dbPath)));
}
