import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/product_provider.dart';
import '../database/database_helper.dart';
import '../models/producto.dart';
import 'add_edit_product_screen.dart';
import 'checkout_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final fCurrency = NumberFormat.currency(locale: 'es_CO', symbol: '\$ ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ProductProvider>().fetchProductos());
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final isSelected = productProvider.isSelectionMode;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isSelected 
          ? "${productProvider.selectedIds.length} seleccionados" 
          : 'Mi Tienda - Precios'),
        backgroundColor: isSelected ? theme.colorScheme.primaryContainer : null,
        leading: isSelected 
          ? IconButton(icon: const Icon(Icons.close), onPressed: () => productProvider.clearSelection())
          : null,
        actions: [
          if (isSelected) ...[
            IconButton(icon: const Icon(Icons.select_all), onPressed: () => productProvider.selectAllFiltered()),
            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDeleteSelected(context)),
          ] else ...[
            PopupMenuButton(
              icon: const Icon(Icons.sort),
              onSelected: (val) => productProvider.sortByPrice(val == 'asc'),
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'asc', child: Text('Precio: Menor a Mayor')),
                const PopupMenuItem(value: 'desc', child: Text('Precio: Mayor a Menor')),
              ],
            )
          ]
        ],
      ),
      drawer: isSelected ? null : _buildDrawer(context),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: SearchBar(
              controller: _searchController,
              hintText: "Buscar o escanear...",
              leading: const Icon(Icons.search),
              trailing: [
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner, color: Colors.green), 
                  onPressed: () => _abrirEscanner(context)
                )
              ],
              onChanged: (val) => productProvider.search(val),
            ),
          ),
          Expanded(
            child: productProvider.isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: productProvider.items.length,
                  itemBuilder: (ctx, i) {
                    final p = productProvider.items[i];
                    final isItemSelection = productProvider.selectedIds.contains(p.id);

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      color: isItemSelection ? theme.colorScheme.secondaryContainer : null,
                      elevation: 1,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        leading: productProvider.mostrarImagenes 
                          ? Container(
                              width: 60, height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey[200],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: p.imagenPath != null 
                                  ? Image.file(File(p.imagenPath!), width: 60, height: 60, fit: BoxFit.cover)
                                  : const Icon(Icons.image_outlined, color: Colors.grey),
                              ),
                            )
                          : isSelected 
                              ? Checkbox(value: isItemSelection, onChanged: (_) => productProvider.toggleSelection(p.id!)) 
                              : null,
                        title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text(p.categoria, style: const TextStyle(fontSize: 13)),
                        trailing: Text(fCurrency.format(p.precio), 
                          style: const TextStyle(color: Colors.green, fontSize: 17, fontWeight: FontWeight.bold)),
                        onTap: () => isSelected 
                          ? productProvider.toggleSelection(p.id!) 
                          : Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditProductScreen(producto: p))),
                        onLongPress: () => productProvider.toggleSelection(p.id!),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
      floatingActionButton: isSelected ? null : FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditProductScreen())),
        label: const Text("Nuevo"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  // --- ESCÁNER ---
  void _abrirEscanner(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: MobileScanner(
          onDetect: (capture) async {
            final barcodes = capture.barcodes;
            if (barcodes.isNotEmpty) {
              final code = barcodes.first.rawValue ?? "";
              Navigator.pop(ctx);
              final p = await DatabaseHelper.instance.getProductoByCodigo(code);
              if (p != null) {
                if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditProductScreen(producto: p)));
              } else {
                if (mounted) {
                  AwesomeDialog(
                    context: context, 
                    dialogType: DialogType.question, 
                    title: 'No encontrado', 
                    desc: '¿Deseas agregarlo?', 
                    btnOkOnPress: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditProductScreen(nuevoCodigo: code)))
                  ).show();
                }
              }
            }
          },
        ),
      ),
    );
  }

  void _confirmDeleteSelected(BuildContext context) {
    AwesomeDialog(context: context, dialogType: DialogType.question, title: '¿Eliminar?', desc: 'Borrarás ${context.read<ProductProvider>().selectedIds.length} productos.', btnOkOnPress: () => context.read<ProductProvider>().deleteSelected()).show();
  }

  // --- DRAWER (MENÚ LATERAL) CORREGIDO ---
  Widget _buildDrawer(BuildContext context) {
    final pp = context.watch<ProductProvider>();
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ENCABEZADO COMPACTO Y HORIZONTAL
          Container(
            height: 110,
            decoration: const BoxDecoration(color: Colors.green),
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 10),
            child: const Row(
              children: [
                Icon(Icons.store, color: Colors.white, size: 32),
                SizedBox(width: 12),
                Text("Mi Tienda", 
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.calculate, color: Colors.blue), 
            title: const Text("CAJA / VENDER", style: TextStyle(fontWeight: FontWeight.bold)), 
            onTap: () { 
              Navigator.pop(context); 
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen())); 
            }
          ),
          ListTile(
            leading: const Icon(Icons.share), 
            title: const Text("Exportar CSV"), 
            onTap: () async { 
              Navigator.pop(context); 
              String path = await pp.exportToCSV(); 
              Share.shareXFiles([XFile(path)], text: 'Lista de precios.'); 
            }
          ),
          ListTile(
            leading: const Icon(Icons.file_upload), 
            title: const Text("Importar CSV"), 
            onTap: () async { 
              Navigator.pop(context); 
              await pp.importFromCSV(); 
            }
          ),
          const Divider(),
          SwitchListTile(
            secondary: const Icon(Icons.image_outlined),
            title: const Text("Usar fotos"),
            value: pp.mostrarImagenes,
            onChanged: (val) => pp.toggleMostrarImagenes(val),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_sweep, color: Colors.red), 
            title: const Text("VACIAR TIENDA", style: TextStyle(color: Colors.red)), 
            onTap: () { 
              Navigator.pop(context); 
              AwesomeDialog(context: context, title: '¿BORRAR TODO?', btnOkOnPress: () => pp.clearAll()).show(); 
            }
          ),
        ],
      ),
    );
  }
}