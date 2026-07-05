import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/table_model.dart';
import '../models/menu_data.dart';

class DummyDataGenerator {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> seedData() async {
    // 1. Seed Users
    await _seedUsers();
    
    // 2. Seed Tables
    await _seedTables();

    // 3. Seed Menu
    await _seedMenu();
  }

  static Future<void> _seedUsers() async {
    final usersCol = _firestore.collection('users');
    
    // Dọn dẹp tài khoản cũ nếu có quá nhiều (do code cũ tạo 40 tài khoản khách hàng)
    final snapshotCust = await usersCol.where('role', isEqualTo: 'customer').get();
    if (snapshotCust.docs.length > 30) {
      final batch = _firestore.batch();
      for (var doc in snapshotCust.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    // Create 30 customer accounts (A01-10, B01-10, C01-10) if they don't exist
    final snapshot = await usersCol.doc('A01').get();
    if (!snapshot.exists) {
      final batch = _firestore.batch();
      for (String area in ['A', 'B', 'C']) {
        for (int i = 1; i <= 10; i++) {
          String id = '$area${i.toString().padLeft(2, '0')}';
          batch.set(usersCol.doc(id), {
            'role': 'customer',
            'name': 'Bàn $id',
            'password': 'abc1', 
          });
        }
      }
      await batch.commit();
    }

    // Luôn đảm bảo các account nhân viên được tạo (tránh trường hợp seed bị ngắt giữa chừng)
    await usersCol.doc('cashier1').set({'role': 'cashier', 'name': 'Thu ngân 1', 'password': '123'});
    await usersCol.doc('cashier2').set({'role': 'cashier', 'name': 'Thu ngân 2', 'password': '123'});

    await usersCol.doc('chef1').set({'role': 'chef', 'name': 'Bếp trưởng', 'password': '123'});
    await usersCol.doc('chef2').set({'role': 'chef', 'name': 'Bếp phó', 'password': '123'});

    await usersCol.doc('manager1').set({'role': 'manager', 'name': 'Quản lý', 'password': 'admin'});
  }

  static Future<void> _seedTables() async {
    final tablesCol = _firestore.collection('tables');
    
    // Dọn dẹp bàn cũ nếu có quá nhiều (do code cũ tạo 60 bàn)
    final snapshotAll = await tablesCol.get();
    if (snapshotAll.docs.length > 30) {
      final batch = _firestore.batch();
      for (var doc in snapshotAll.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } else if (snapshotAll.docs.isNotEmpty) {
      return; // Đã có đủ 30 bàn
    }

    for (String area in ['A', 'B', 'C']) {
      for (int i = 1; i <= 10; i++) {
        String id = '$area${i.toString().padLeft(2, '0')}';
        final table = TableModel(id: id, area: area, number: i);
        await tablesCol.doc(id).set(table.toMap());
      }
    }
  }

  static Future<void> _seedMenu() async {
    final menuCol = _firestore.collection('menu');
    
    final snapshot = await menuCol.limit(1).get();
    if (snapshot.docs.isNotEmpty) return;

    for (var category in menuData) {
      for (var item in category.items) {
        // TFP logic: if it's hotpot/water, fast (5 mins). If it's main dish, slow (15-20 mins).
        int tfp = 10;
        if (category.icon == 'soup' || category.icon == 'cup-soda') tfp = 5;
        if (category.icon == 'chef-hat') tfp = 20;

        final menuItem = MenuItem(
          id: item.id,
          name: item.name,
          price: item.price,
          description: item.description,
          ingredients: item.ingredients,
          imageUrl: item.imageUrl,
          isAvailable: item.isAvailable,
          tfp: tfp,
          category: category.category,
        );

        await menuCol.doc(item.id).set(menuItem.toMap());
      }
    }
  }
}
