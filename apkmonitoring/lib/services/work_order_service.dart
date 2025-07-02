import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/work_order_model.dart';

class WorkOrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Tactical Work Orders
  Future<List<WorkOrderModel>> getTacticalWorkOrders({String? userId}) async {
    try {
      Query query = _firestore.collection('tactical_work_orders');
      
      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => WorkOrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error getting tactical work orders: $e');
      return [];
    }
  }

  // Non-Tactical Work Orders
  Future<List<WorkOrderModel>> getNonTacticalWorkOrders({String? userId}) async {
    try {
      Query query = _firestore.collection('nontactical_work_order');
      
      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => WorkOrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error getting non-tactical work orders: $e');
      return [];
    }
  }

  // Save Work Order
  Future<void> saveWorkOrder(WorkOrderModel workOrder, bool isTactical) async {
    try {
      final collection = isTactical ? 'tactical_work_orders' : 'nontactical_work_order';
      
      if (workOrder.id.isEmpty) {
        await _firestore.collection(collection).add(workOrder.toMap());
      } else {
        await _firestore.collection(collection).doc(workOrder.id).set(workOrder.toMap());
      }
    } catch (e) {
      print('Error saving work order: $e');
      rethrow;
    }
  }

  // Update Work Order Status
  Future<void> updateWorkOrderStatus(String id, String status, bool isTactical) async {
    try {
      final collection = isTactical ? 'tactical_work_orders' : 'nontactical_work_order';
      await _firestore.collection(collection).doc(id).update({
        'status': status,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error updating work order status: $e');
      rethrow;
    }
  }

  // Delete Work Order
  Future<void> deleteWorkOrder(String id, bool isTactical) async {
    try {
      final collection = isTactical ? 'tactical_work_orders' : 'nontactical_work_order';
      await _firestore.collection(collection).doc(id).delete();
    } catch (e) {
      print('Error deleting work order: $e');
      rethrow;
    }
  }

  // Get Work Order History
  Future<List<WorkOrderModel>> getWorkOrderHistory({String? userId}) async {
    try {
      Query query = _firestore.collection('work_order_history');
      
      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      final snapshot = await query.orderBy('createdAt', descending: true).get();
      return snapshot.docs
          .map((doc) => WorkOrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error getting work order history: $e');
      return [];
    }
  }
}