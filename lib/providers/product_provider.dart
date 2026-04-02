import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../database/database_helper.dart';
import '../models/producto.dart';
import '../models/carrito_item.dart'; // <--- ESTA LÍNEA ES VITAL

class ProductProvider with ChangeNotifier {
  List<Producto> _items = [];
  List<Producto> _filteredItems = [];
  bool _isLoading = false;

  final Set<int> _selectedIds = {}; 
  Set<int> get selectedIds => _selectedIds;
  bool get isSelectionMode => _selectedIds.isNotEmpty;

  List<Producto> get items => _filteredItems;
  bool get isLoading => _isLoading;

  // --- LÓGICA DE CAJA ---
  List<CarritoItem> _carrito = [];
  List<CarritoItem> get carrito => _carrito;
  double get totalCarrito => _carrito.fold(0, (sum, item) => sum + item.subtotal);

  void agregarAlCarrito(Producto p) {
    int index = _carrito.indexWhere((item) => item.producto.id == p.id);
    if (index != -1) {
      _carrito[index].cantidad++;
    } else {
      _carrito.add(CarritoItem(producto: p));
    }
    notifyListeners();
  }

  void removerDelCarrito(int index) {
    if (_carrito[index].cantidad > 1) {
      _carrito[index].cantidad--;
    } else {
      _carrito.removeAt(index);
    }
    notifyListeners();
  }

  void limpiarCarrito() {
    _carrito.clear();
    notifyListeners();
  }

  // --- RESTO DE FUNCIONES ---
  Future<void> fetchProductos() async {
    _isLoading = true;
    _items = await DatabaseHelper.instance.readAllProductos();
    _filteredItems = _items;
    _isLoading = false;
    notifyListeners();
  }

  void search(String query) {
    if (query.isEmpty) {
      _filteredItems = _items;
    } else {
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

  Future<void> addProducto(Producto producto) async { await DatabaseHelper.instance.create(producto); await fetchProductos(); }
  Future<void> updateProducto(Producto producto) async { await DatabaseHelper.instance.update(producto); await fetchProductos(); }
  Future<void> deleteProducto(int id) async { await DatabaseHelper.instance.delete(id); await fetchProductos(); }
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
        try { content = await file.readAsString(encoding: utf8); } 
        catch (e) { content = await file.readAsString(encoding: latin1); }
        List<String> lines = content.split('\n');
        for (int i = 1; i < lines.length; i++) {
          if (lines[i].trim().isEmpty) continue;
          List<String> columns = lines[i].split(',');
          if (columns.length >= 3) {
            Producto nuevo = Producto(
              nombre: columns[0].trim(),
              precio: double.tryParse(columns[1].trim()) ?? 0.0,
              categoria: columns[2].trim(),
              descripcion: columns.length > 3 ? columns[3].trim() : "",
              fechaCreacion: DateTime.now(),
            );
            Producto? existe = await DatabaseHelper.instance.getProductoByNombre(nuevo.nombre);
            if (existe != null) { nuevo.id = existe.id; await DatabaseHelper.instance.update(nuevo); } 
            else { await DatabaseHelper.instance.create(nuevo); }
          }
        }
        await fetchProductos();
        return true;
      }
      return false;
    } catch (e) { return false; }
  }
}