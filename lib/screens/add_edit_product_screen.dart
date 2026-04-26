import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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
  final TextEditingController _barcodeController = TextEditingController();
  String _nombre = '';
  String _categoria = '';
  String _descripcion = '';
  double _precio = 0.0;
  String? _imagenPath;
  late bool _bloqueado;

  @override
  void initState() {
    super.initState();
    _bloqueado = widget.producto != null;
    _barcodeController.text = widget.producto?.codigoBarras ?? widget.nuevoCodigo ?? '';
    if (widget.producto != null) {
      _nombre = widget.producto!.nombre;
      _categoria = widget.producto!.categoria;
      _descripcion = widget.producto!.descripcion ?? '';
      _precio = widget.producto!.precio;
      _imagenPath = widget.producto!.imagenPath;
    }
  }

  Future<void> _tomarFoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    if (file != null) setState(() => _imagenPath = file.path);
  }

  void _escanear() {
    showModalBottomSheet(context: context, builder: (ctx) => SizedBox(height: 400, child: MobileScanner(onDetect: (cap) { _barcodeController.text = cap.barcodes.first.rawValue ?? ""; Navigator.pop(ctx); })));
  }

  void _saveForm() {
    if (_nombre.isEmpty || _precio <= 0) return;
    final p = Producto(id: widget.producto?.id, nombre: _nombre.trim(), precio: _precio, categoria: _categoria.trim(), descripcion: _descripcion, codigoBarras: _barcodeController.text, imagenPath: _imagenPath, fechaCreacion: widget.producto?.fechaCreacion ?? DateTime.now());
    if (widget.producto == null) { context.read<ProductProvider>().addProducto(p); } else { context.read<ProductProvider>().updateProducto(p); }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<ProductProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(widget.producto == null ? pp.tr('new') : pp.tr('details')), actions: [if (widget.producto != null) IconButton(icon: Icon(_bloqueado ? Icons.edit : Icons.edit_off, color: _bloqueado ? Colors.green : Colors.orange), onPressed: () => setState(() => _bloqueado = !_bloqueado))]),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                if (_bloqueado) Card(color: Colors.yellow[100], child: Padding(padding: const EdgeInsets.all(8.0), child: Text(pp.tr('read_only'), style: const TextStyle(fontSize: 12, color: Colors.black87)))),
                if (pp.mostrarImagenes) ...[
                  GestureDetector(
                    onTap: _bloqueado ? null : _tomarFoto,
                    child: Container(height: 160, width: double.infinity, decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(12)), child: _imagenPath != null ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(_imagenPath!), fit: BoxFit.cover)) : Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.camera_alt, size: 40), Text(pp.tr('drawer_photos'))])),
                  ),
                  const SizedBox(height: 20),
                ],
                TextFormField(initialValue: _nombre, readOnly: _bloqueado, decoration: InputDecoration(labelText: pp.tr('name'), border: const OutlineInputBorder()), onChanged: (v) => _nombre = v),
                const SizedBox(height: 20),
                TextFormField(controller: _barcodeController, readOnly: _bloqueado, decoration: InputDecoration(labelText: pp.tr('barcode'), border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.qr_code), suffixIcon: _bloqueado ? null : IconButton(icon: const Icon(Icons.qr_code_scanner), onPressed: _escanear))),
                const SizedBox(height: 20),
                TextFormField(initialValue: widget.producto != null ? _precio.toString() : "", readOnly: _bloqueado, decoration: InputDecoration(labelText: pp.tr('price'), border: const OutlineInputBorder(), prefixText: "\$ "), keyboardType: TextInputType.number, onChanged: (v) => _precio = double.tryParse(v) ?? 0.0),
                const SizedBox(height: 20),
                TextFormField(initialValue: _categoria, readOnly: _bloqueado, decoration: InputDecoration(labelText: pp.tr('category'), border: const OutlineInputBorder()), onChanged: (v) => _categoria = v),
                const SizedBox(height: 30),
                if (!_bloqueado) SizedBox(width: double.infinity, height: 55, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), onPressed: _saveForm, child: Text(pp.tr('save'), style: const TextStyle(fontWeight: FontWeight.bold)))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}