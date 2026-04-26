import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/producto.dart';
import '../models/carrito_item.dart';
import '../utils/translations.dart';

class ProductProvider with ChangeNotifier {
  List<Producto> _items = [];
  List<Producto> _filteredItems = [];
  bool _isLoading = false;
  bool _mostrarImagenes = false;
  bool _esPrimeraVez = true; 
  String _idioma = 'en';

  final Set<int> _selectedIds = {}; 
  Set<int> get selectedIds => _selectedIds;
  bool get isSelectionMode => _selectedIds.isNotEmpty;
  bool get mostrarImagenes => _mostrarImagenes;
  bool get esPrimeraVez => _esPrimeraVez;
  String get idioma => _idioma;
  List<Producto> get items => _filteredItems;
  bool get isLoading => _isLoading;

  ProductProvider() { _cargarPreferencias(); }

  String tr(String key) => AppTexts.values[_idioma]?[key] ?? key;

  Future<void> _cargarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    _mostrarImagenes = prefs.getBool('mostrarImagenes') ?? false;
    _esPrimeraVez = prefs.getBool('esPrimeraVez') ?? true;
    _idioma = prefs.getString('idioma') ?? 'en';
    await fetchProductos();
    notifyListeners();
  }

  void toggleIdioma() async {
    _idioma = (_idioma == 'en') ? 'es' : 'en';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('idioma', _idioma);
    notifyListeners();
  }

  void toggleMostrarImagenes(bool valor) async {
    _mostrarImagenes = valor;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mostrarImagenes', valor);
    notifyListeners();
  }

  Future<void> finalizarTutorial() async {
    _esPrimeraVez = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('esPrimeraVez', false); 
    notifyListeners();
  }

  // --- CARRITO ---
  final List<CarritoItem> _carrito = [];
  List<CarritoItem> get carrito => _carrito;
  double get totalCarrito => _carrito.fold(0, (sum, item) => sum + item.subtotal);

  void agregarAlCarrito(Producto p) {
    int index = _carrito.indexWhere((item) => item.producto.id == p.id);
    if (index != -1) { _carrito[index].cantidad++; } 
    else { _carrito.add(CarritoItem(producto: p)); }
    notifyListeners();
  }

  void removerDelCarrito(int index) {
    if (_carrito[index].cantidad > 1) { _carrito[index].cantidad--; } 
    else { _carrito.removeAt(index); }
    notifyListeners();
  }

  void limpiarCarrito() { _carrito.clear(); notifyListeners(); }

  // --- CRUD ---
  Future<void> fetchProductos() async {
    _isLoading = true;
    _items = await DatabaseHelper.instance.readAllProductos();
    _filteredItems = _items;
    _isLoading = false;
    notifyListeners();
  }

  void search(String query) {
    if (query.isEmpty) { _filteredItems = _items; } 
    else {
      _filteredItems = _items.where((p) =>
          p.nombre.toLowerCase().contains(query.toLowerCase()) ||
          p.categoria.toLowerCase().contains(query.toLowerCase())).toList();
    }
    notifyListeners();
  }

  void sortByPrice(bool ascending) {
    _filteredItems.sort((a, b) => ascending ? a.precio.compareTo(b.precio) : b.precio.compareTo(a.precio));
    notifyListeners();
  }

  void toggleSelection(int id) {
    if (_selectedIds.contains(id)) { _selectedIds.remove(id); } 
    else { _selectedIds.add(id); }
    notifyListeners();
  }
  void clearSelection() { _selectedIds.clear(); notifyListeners(); }
  void selectAllFiltered() { for (var p in _filteredItems) { if (p.id != null) _selectedIds.add(p.id!); } notifyListeners(); }

  Future<void> deleteSelected() async {
    for (var id in _selectedIds) { await DatabaseHelper.instance.delete(id); }
    _selectedIds.clear();
    await fetchProductos();
  }

  Future<void> addProducto(Producto p) async { await DatabaseHelper.instance.create(p); await fetchProductos(); }
  Future<void> updateProducto(Producto p) async { await DatabaseHelper.instance.update(p); await fetchProductos(); }
  Future<void> clearAll() async { await DatabaseHelper.instance.deleteAll(); await fetchProductos(); }

  Future<String> exportToCSV() async {
    String csvData = "Nombre,Precio,Categoria,Descripcion\n";
    for (var p in _items) { csvData += "${p.nombre},${p.precio},${p.categoria},${p.descripcion ?? ''}\n"; }
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/productos_tienda.csv');
    await file.writeAsString(csvData, encoding: utf8);
    return file.path;
  }

  Future<bool> importFromCSV() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result != null) {
        File file = File(result.files.single.path!);
        String content;
        try { content = await file.readAsString(encoding: utf8); } catch (e) { content = await file.readAsString(encoding: latin1); }
        List<String> lines = content.split('\n');
        for (int i = 1; i < lines.length; i++) {
          if (lines[i].trim().isEmpty) continue;
          List<String> col = lines[i].split(',');
          if (col.length >= 3) {
            Producto n = Producto(nombre: col[0].trim(), precio: double.tryParse(col[1].trim()) ?? 0.0, categoria: col[2].trim(), descripcion: col.length > 3 ? col[3].trim() : "", fechaCreacion: DateTime.now());
            Producto? ex = await DatabaseHelper.instance.getProductoByNombre(n.nombre);
            if (ex != null) { n.id = ex.id; await DatabaseHelper.instance.update(n); } else { await DatabaseHelper.instance.create(n); }
          }
        }
        await fetchProductos();
        return true;
      }
      return false;
    } catch (e) { return false; }
  }
}