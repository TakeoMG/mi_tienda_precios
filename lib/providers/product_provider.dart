import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../database/database_helper.dart';
import '../models/producto.dart';
import 'package:file_picker/file_picker.dart';

class ProductProvider with ChangeNotifier {
  List<Producto> _items = [];
  List<Producto> _filteredItems = [];
  bool _isLoading = false;

  List<Producto> get items => _filteredItems;
  bool get isLoading => _isLoading;

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
      _filteredItems = _items
          .where((p) =>
              p.nombre.toLowerCase().contains(query.toLowerCase()) ||
              p.categoria.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  void sortByPrice(bool ascending) {
    _filteredItems.sort((a, b) => ascending 
      ? a.precio.compareTo(b.precio) 
      : b.precio.compareTo(a.precio));
    notifyListeners();
  }

  Future<void> addProducto(Producto producto) async {
    await DatabaseHelper.instance.create(producto);
    await fetchProductos();
  }

  Future<void> updateProducto(Producto producto) async {
    await DatabaseHelper.instance.update(producto);
    await fetchProductos();
  }

  Future<void> deleteProducto(int id) async {
    await DatabaseHelper.instance.delete(id);
    await fetchProductos();
  }
Future<String> exportToCSV() async {
    // Creamos el encabezado del archivo
    String csvData = "Nombre,Precio,Categoria,Descripcion\n";
    
    // Recorremos los productos y los añadimos como filas
    for (var p in _items) {
      // Limpiamos comas de los textos para no romper el formato CSV
      String nombre = p.nombre.replaceAll(',', ' ');
      String categoria = p.categoria.replaceAll(',', ' ');
      String desc = (p.descripcion ?? "").replaceAll(',', ' ');
      
      csvData += "$nombre,${p.precio},$categoria,$desc\n";
    }
    
    // Guardamos el archivo en el celular
    final directory = await getExternalStorageDirectory();
    final file = File('${directory!.path}/productos_tienda.csv');
    await file.writeAsString(csvData);
    
    return file.path;
  }



  Future<bool> importFromCSV() async {
    try {
      // 1. Abrir el selector de archivos
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        
        // 2. Procesar las líneas
        List<String> lines = content.split('\n');
        
        // Empezamos en 1 para saltar el encabezado (Nombre, Precio...)
        for (int i = 1; i < lines.length; i++) {
          if (lines[i].trim().isEmpty) continue;
          
          List<String> columns = lines[i].split(',');
          if (columns.length >= 3) {
            String nombre = columns[0].trim();
            double precio = double.tryParse(columns[1].trim()) ?? 0.0;
            String categoria = columns[2].trim();
            String desc = columns.length > 3 ? columns[3].trim() : "";

            // 3. Crear el producto
            Producto nuevo = Producto(
              nombre: nombre,
              precio: precio,
              categoria: categoria,
              descripcion: desc,
              fechaCreacion: DateTime.now(),
            );

            // 4. Guardar en DB (puedes mejorar esto verificando si ya existe por nombre)
            await DatabaseHelper.instance.create(nuevo);
          }
        }
        await fetchProductos(); // Refrescar lista
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error importando: $e");
      return false;
    }
  }


}