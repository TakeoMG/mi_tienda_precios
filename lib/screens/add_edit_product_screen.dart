import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/producto.dart';
import '../providers/product_provider.dart';

class AddEditProductScreen extends StatefulWidget {
  final Producto? producto;
  const AddEditProductScreen({super.key, this.producto});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _nombre, _categoria, _descripcion;
  late double _precio;
  
  // VARIABLE CLAVE: Controla si se puede editar o no
  late bool _bloqueado; 

  @override
  void initState() {
    super.initState();
    // Si el producto existe, empezamos bloqueados. Si es nuevo, empezamos editando.
    _bloqueado = widget.producto != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.producto == null ? "Nuevo Producto" : "Detalles"),
        actions: [
          if (widget.producto != null)
            IconButton(
              icon: Icon(_bloqueado ? Icons.edit : Icons.edit_off, color: _bloqueado ? Colors.green : Colors.orange),
              onPressed: () => setState(() => _bloqueado = !_bloqueado),
              tooltip: "Habilitar edición",
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
                    color: Colors.yellow[100], // Este color SÍ existe
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "Modo lectura: Toca el lápiz arriba para editar", 
                        style: TextStyle(fontSize: 12, color: Colors.black87)
                      ),
                    ),
                  ),
                TextFormField(
                  initialValue: widget.producto?.nombre,
                  readOnly: _bloqueado, // <--- Bloqueo
                  decoration: const InputDecoration(labelText: "Nombre *", border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
                  onSaved: (v) => _nombre = v!,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  initialValue: widget.producto?.precio.toString(),
                  readOnly: _bloqueado, // <--- Bloqueo
                  decoration: const InputDecoration(labelText: "Precio *", border: OutlineInputBorder(), prefixText: "\$ "),
                  keyboardType: TextInputType.number,
                  validator: (v) => (double.tryParse(v!) ?? 0) <= 0 ? "Precio inválido" : null,
                  onSaved: (v) => _precio = double.parse(v!),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  initialValue: widget.producto?.categoria,
                  readOnly: _bloqueado, // <--- Bloqueo
                  decoration: const InputDecoration(labelText: "Categoría *", border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
                  onSaved: (v) => _categoria = v!,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  initialValue: widget.producto?.descripcion,
                  readOnly: _bloqueado, // <--- Bloqueo
                  decoration: const InputDecoration(labelText: "Descripción (Opcional)", border: OutlineInputBorder()),
                  maxLines: 3,
                  onSaved: (v) => _descripcion = v ?? "",
                ),
                const SizedBox(height: 30),
                if (!_bloqueado) // Solo mostrar botón si no está bloqueado
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      onPressed: _saveForm,
                      child: const Text("GUARDAR CAMBIOS", style: TextStyle(fontWeight: FontWeight.bold)),
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
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final p = Producto(
        id: widget.producto?.id,
        nombre: _nombre,
        precio: _precio,
        categoria: _categoria,
        descripcion: _descripcion,
        fechaCreacion: widget.producto?.fechaCreacion ?? DateTime.now(),
      );

      if (widget.producto == null) {
        context.read<ProductProvider>().addProducto(p);
      } else {
        context.read<ProductProvider>().updateProducto(p);
      }
      Navigator.pop(context);
    }
  }
}