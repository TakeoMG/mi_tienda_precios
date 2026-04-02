import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/producto.dart';
import '../providers/product_provider.dart';

class AddEditProductScreen extends StatefulWidget {
  final Producto? producto;
  final String? nuevoCodigo;

  const AddEditProductScreen({super.key, this.producto, this.nuevoCodigo});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Variables inicializadas para evitar errores de "Late Initialization"
  String _nombre = '';
  String _categoria = '';
  String _descripcion = '';
  double _precio = 0.0;
  String? _codigoBarras;
  late bool _bloqueado;

  @override
  void initState() {
    super.initState();
    _bloqueado = widget.producto != null;
    
    // Si estamos editando, cargamos los valores actuales
    if (widget.producto != null) {
      _nombre = widget.producto!.nombre;
      _categoria = widget.producto!.categoria;
      _descripcion = widget.producto!.descripcion ?? '';
      _precio = widget.producto!.precio;
      _codigoBarras = widget.producto!.codigoBarras;
    } else if (widget.nuevoCodigo != null) {
      // Si venimos del escáner con un código nuevo
      _codigoBarras = widget.nuevoCodigo;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.producto == null ? "Nuevo Producto" : "Detalles"),
        actions: [
          if (widget.producto != null)
            IconButton(
              icon: Icon(_bloqueado ? Icons.edit : Icons.edit_off, 
                color: _bloqueado ? Colors.green : Colors.orange),
              onPressed: () => setState(() => _bloqueado = !_bloqueado),
            )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (_bloqueado) 
                  Card(
                    color: Colors.yellow[100], 
                    child: const Padding(
                      padding: EdgeInsets.all(8.0), 
                      child: Text("Modo lectura: Toca el lápiz para editar", 
                        style: TextStyle(fontSize: 12, color: Colors.black87))
                    )
                  ),
                const SizedBox(height: 10),
                
                // NOMBRE
                TextFormField(
                  initialValue: _nombre,
                  readOnly: _bloqueado,
                  decoration: const InputDecoration(labelText: "Nombre del Producto *", border: OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty ? "El nombre es obligatorio" : null,
                  onChanged: (v) => _nombre = v,
                ),
                const SizedBox(height: 15),

                // CÓDIGO DE BARRAS
                TextFormField(
                  initialValue: _codigoBarras,
                  readOnly: _bloqueado,
                  decoration: const InputDecoration(
                    labelText: "Código de Barras (Opcional)", 
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.qr_code)
                  ),
                  onChanged: (v) => _codigoBarras = v,
                ),
                const SizedBox(height: 15),

                // PRECIO
                TextFormField(
                  initialValue: widget.producto != null ? _precio.toString() : "",
                  readOnly: _bloqueado,
                  decoration: const InputDecoration(
                    labelText: "Precio *", 
                    border: OutlineInputBorder(), 
                    prefixText: "\$ "
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return "El precio es obligatorio";
                    if (double.tryParse(v) == null || double.parse(v) <= 0) return "Precio inválido";
                    return null;
                  },
                  onChanged: (v) => _precio = double.tryParse(v) ?? 0.0,
                ),
                const SizedBox(height: 15),

                // CATEGORÍA
                TextFormField(
                  initialValue: _categoria,
                  readOnly: _bloqueado,
                  decoration: const InputDecoration(labelText: "Categoría *", border: OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty ? "La categoría es obligatoria" : null,
                  onChanged: (v) => _categoria = v,
                ),
                const SizedBox(height: 15),

                // DESCRIPCIÓN
                TextFormField(
                  initialValue: _descripcion,
                  readOnly: _bloqueado,
                  decoration: const InputDecoration(labelText: "Descripción (Opcional)", border: OutlineInputBorder()),
                  maxLines: 2,
                  onChanged: (v) => _descripcion = v,
                ),
                
                const SizedBox(height: 30),
                
                // BOTÓN DE GUARDAR
                if (!_bloqueado)
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, 
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                      ),
                      onPressed: _saveForm,
                      child: const Text("GUARDAR PRODUCTO", 
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _saveForm() {
    // 1. Validar que los campos obligatorios estén llenos
    if (_formKey.currentState!.validate()) {
      
      final p = Producto(
        id: widget.producto?.id,
        nombre: _nombre.trim(),
        precio: _precio,
        categoria: _categoria.trim(),
        descripcion: _descripcion.trim(),
        codigoBarras: _codigoBarras?.trim(),
        fechaCreacion: widget.producto?.fechaCreacion ?? DateTime.now(),
      );

      // 2. Guardar usando el Provider
      if (widget.producto == null) {
        context.read<ProductProvider>().addProducto(p);
      } else {
        context.read<ProductProvider>().updateProducto(p);
      }

      // 3. Cerrar la pantalla
      Navigator.pop(context);
      
      // 4. Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Producto guardado correctamente"), backgroundColor: Colors.green),
      );
    }
  }
}