import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/class_item.dart';

class StorageService {
  static const String _storageKey = 'timetable_classes';
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  List<ClassItem> getClasses() {
    final String? classesJson = _prefs.getString(_storageKey);
    if (classesJson == null) return [];
    
    try {
      final List<dynamic> decodedList = jsonDecode(classesJson);
      return decodedList.map((item) => ClassItem.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveClasses(List<ClassItem> classes) async {
    final String encodedList = jsonEncode(classes.map((c) => c.toJson()).toList());
    await _prefs.setString(_storageKey, encodedList);
  }

  Future<void> addClass(ClassItem item) async {
    final classes = getClasses();
    classes.add(item);
    await saveClasses(classes);
  }

  Future<void> updateClass(ClassItem updatedItem) async {
    final classes = getClasses();
    final index = classes.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      classes[index] = updatedItem;
      await saveClasses(classes);
    }
  }
  
  Future<void> deleteClass(String id) async {
    final classes = getClasses();
    classes.removeWhere((item) => item.id == id);
    await saveClasses(classes);
  }
}
