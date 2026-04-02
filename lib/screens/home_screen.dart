import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import 'add_edit_product_screen.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:share_plus/share_plus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  // 1. FORMATO DE PESOS: Símbolo al inicio y sin decimales (.00)
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
    final theme = Theme.of(context); // Para detectar colores de modo oscuro automáticamente

    return Scaffold(
      appBar: AppBar(
        title: Text(isSelected 
          ? "${productProvider.selectedIds.length} seleccionados" 
          : 'Mi Tienda - Precios'),
        // 3. COLOR ADAPTABLE: Usa el contenedor del tema para modo oscuro
        backgroundColor: isSelected ? theme.colorScheme.primaryContainer : null,
        leading: isSelected 
          ? IconButton(icon: const Icon(Icons.close), onPressed: () => productProvider.clearSelection())
          : null,
        actions: [
          if (isSelected) ...[
            IconButton(
              icon: const Icon(Icons.select_all), 
              onPressed: () => productProvider.selectAllFiltered(),
              tooltip: "Seleccionar todos",
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red), 
              onPressed: () => _confirmDeleteSelected(context),
            ),
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
            padding: const EdgeInsets.all(12.0),
            child: SearchBar(
              controller: _searchController,
              hintText: "Buscar producto o categoría...",
              leading: const Icon(Icons.search),
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
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  // 3. CONTRASTE: Usamos secondaryContainer para que resalte en oscuro y claro
                  color: isItemSelection ? theme.colorScheme.secondaryContainer : null,
                  elevation: isItemSelection ? 4 : 1,
                  child: ListTile(
                    // 2. SIN CÍRCULO: Solo mostramos checkbox si hay selección múltiple
                    leading: isSelected 
                      ? Checkbox(
                          value: isItemSelection, 
                          activeColor: theme.colorScheme.primary,
                          onChanged: (_) => productProvider.toggleSelection(p.id!))
                      : null,
                    title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(p.categoria),
                    trailing: Text(fCurrency.format(p.precio), 
                      style: const TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold)),
                    onTap: () {
                      if (isSelected) {
                        productProvider.toggleSelection(p.id!);
                      } else {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => AddEditProductScreen(producto: p)));
                      }
                    },
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
        label: const Text("Nuevo Producto"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDeleteSelected(BuildContext context) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.question,
      title: '¿Eliminar seleccionados?',
      desc: 'Borrarás ${context.read<ProductProvider>().selectedIds.length} productos.',
      btnCancelText: "No",
      btnOkText: "Sí, borrar",
      btnOkColor: Colors.red,
      btnOkOnPress: () => context.read<ProductProvider>().deleteSelected(),
    ).show();
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.green),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.store, color: Colors.white, size: 50),
                Text("Mi Tienda", style: TextStyle(color: Colors.white, fontSize: 24)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.share), 
            title: const Text("Exportar y Enviar"), 
            onTap: () async {
              Navigator.pop(context);
              String filePath = await context.read<ProductProvider>().exportToCSV();
              Share.shareXFiles([XFile(filePath)], text: 'Precios de mi tienda.');
            }
          ),
          ListTile(
            leading: const Icon(Icons.file_upload), 
            title: const Text("Importar Lista (CSV)"), 
            onTap: () async {
              Navigator.pop(context);
              bool ok = await context.read<ProductProvider>().importFromCSV();
              if (ok) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Importado!"), backgroundColor: Colors.green));
              }
            }
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_sweep, color: Colors.red),
            title: const Text("VACIAR TIENDA", style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              AwesomeDialog(
                context: context,
                dialogType: DialogType.warning,
                title: '¿BORRAR TODO?',
                desc: 'Esta acción limpiará toda la base de datos.',
                btnOkOnPress: () => context.read<ProductProvider>().clearAll(),
              ).show();
            },
          ),
        ],
      ),
    );
  }
} 