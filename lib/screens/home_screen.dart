import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import 'add_edit_product_screen.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:share_plus/share_plus.dart'; // <--- Agrega esto arriba

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final fCurrency = NumberFormat.simpleCurrency(locale: "es_MX"); // Cambia según tu país

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ProductProvider>().fetchProductos());
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('My Market'),
        actions: [
          PopupMenuButton(
            icon: Icon(Icons.sort),
            onSelected: (value) {
              productProvider.sortByPrice(value == 'asc');
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(value: 'asc', child: Text('Precio: Menor a Mayor')),
              PopupMenuItem(value: 'desc', child: Text('Precio: Mayor a Menor')),
            ],
          )
        ],
      ),
      drawer: _buildDrawer(context),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SearchBar(
              controller: _searchController,
              hintText: "Buscar producto o categoría...",
              leading: Icon(Icons.search),
              onChanged: (val) => productProvider.search(val),
            ),
          ),
          Expanded(
            child: productProvider.isLoading
                ? Center(child: CircularProgressIndicator())
                : productProvider.items.isEmpty
                    ? Center(child: Text("No se encontraron productos"))
                    : ListView.builder(
                        itemCount: productProvider.items.length,
                        itemBuilder: (ctx, i) {
                          final p = productProvider.items[i];
                          return Card(
                            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              title: Text(p.nombre, style: TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(p.categoria),
                              trailing: Text(fCurrency.format(p.precio), 
                                style: TextStyle(color: Colors.green, fontSize: 18, fontWeight: FontWeight.bold)),
                              onTap: () => Navigator.push(context, MaterialPageRoute(
                                builder: (_) => AddEditProductScreen(producto: p))),
                              onLongPress: () => _confirmDelete(context, p),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditProductScreen())),
        label: Text("Nuevo Producto"),
        icon: Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(BuildContext context, dynamic p) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.question,
      title: '¿Eliminar?',
      desc: '¿Estás seguro de eliminar ${p.nombre}?',
      btnCancelText: "Cancelar",
      btnOkText: "Eliminar",
      btnOkOnPress: () => context.read<ProductProvider>().deleteProducto(p.id!),
    ).show();
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.green),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.store, color: Colors.white, size: 50),
                Text("My Market", style: TextStyle(color: Colors.white, fontSize: 24)),
              ],
            ),
          ),
          ListTile(leading: Icon(Icons.home), title: Text("Inicio"), onTap: () => Navigator.pop(context)),
          ListTile(
            leading: const Icon(Icons.share), 
            title: const Text("Exportar y Enviar"), 
            onTap: () async {
              Navigator.pop(context); // Cierra el menú
              
              // 1. Generamos el archivo (esto ya lo tenemos en el provider)
              String filePath = await context.read<ProductProvider>().exportToCSV();
              
              // 2. Abrimos la ventana de compartir de Android
              // Esto te permitirá enviarlo por WhatsApp o guardarlo donde quieras
              await Share.shareXFiles(
                [XFile(filePath)], 
                text: 'Aquí tienes la lista de precios de mi tienda.',
              );
            }
          ),
          ListTile(
            leading: const Icon(Icons.file_upload), 
            title: const Text("Importar Lista (CSV)"), 
            onTap: () async {
              Navigator.pop(context);
              bool ok = await context.read<ProductProvider>().importFromCSV();
              if (ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("¡Productos importados con éxito!"), backgroundColor: Colors.green),
                );
              }
            }
          ),
          AboutListTile(
            icon: Icon(Icons.info),
            applicationName: "My Market",
            applicationVersion: "1.0.0",
            aboutBoxChildren: [Text("Creado para control de precios local.")],
          ),
        ],
      ),
    );
  }
}