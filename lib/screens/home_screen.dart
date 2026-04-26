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
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      final pp = context.read<ProductProvider>();
      if (pp.esPrimeraVez) {
        _mostrarTutorial(context);
      }
    });
  }

  void _mostrarTutorial(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Consumer<ProductProvider>(
          builder: (context, pp, child) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(pp.tr('welcome_title')),
              content: SizedBox(
                width: double.maxFinite,
                height: 350,
                child: Column(
                  children: [
                    Expanded(
                      child: PageView(
                        children: [
                          _step(Icons.qr_code_scanner, pp.tr('tut_name_1'), pp.tr('tut_step_1')),
                          _step(Icons.calculate, pp.tr('tut_name_2'), pp.tr('tut_step_2')),
                          _step(Icons.edit, pp.tr('tut_name_3'), pp.tr('tut_step_3')),
                        ],
                      ),
                    ),
                    const Divider(),
                    TextButton.icon(
                      icon: const Icon(Icons.language, color: Colors.orange),
                      label: Text(pp.idioma == 'en' ? "Español 🇪🇸" : "English 🇺🇸"),
                      onPressed: () => pp.toggleIdioma(),
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await pp.finalizarTutorial();
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: Text(pp.tr('welcome_understand'), 
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 18)),
                )
              ],
            );
          },
        );
      },
    );
  }

  Widget _step(IconData icon, String title, String desc) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 70, color: Colors.green),
        const SizedBox(height: 15),
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text(desc, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 16)),
        const SizedBox(height: 20),
        const Text("Swipe →", style: TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<ProductProvider>();
    final isSelected = pp.isSelectionMode;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isSelected ? "${pp.selectedIds.length} selected" : pp.tr('app_title')),
        backgroundColor: isSelected ? theme.colorScheme.primaryContainer : null,
        leading: isSelected ? IconButton(icon: const Icon(Icons.close), onPressed: () => pp.clearSelection()) : null,
        actions: [
          if (isSelected) ...[
            IconButton(icon: const Icon(Icons.select_all), onPressed: () => pp.selectAllFiltered()),
            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDeleteSelected(context)),
          ] else ...[
            PopupMenuButton(
              icon: const Icon(Icons.sort),
              onSelected: (val) => pp.sortByPrice(val == 'asc'),
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'asc', child: Text('Min -> Max')),
                const PopupMenuItem(value: 'desc', child: Text('Max -> Min')),
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
              hintText: pp.tr('search_hint'),
              leading: const Icon(Icons.search),
              trailing: [IconButton(icon: const Icon(Icons.qr_code_scanner, color: Colors.green), onPressed: () => _abrirEscanner(context))],
              onChanged: (val) => pp.search(val),
            ),
          ),
          Expanded(
            child: pp.isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: pp.items.length,
                  itemBuilder: (ctx, i) {
                    final p = pp.items[i];
                    final isItemSelection = pp.selectedIds.contains(p.id);
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      color: isItemSelection ? theme.colorScheme.secondaryContainer : null,
                      child: ListTile(
                        leading: pp.mostrarImagenes 
                          ? Container(
                              width: 60, height: 60,
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey[200]),
                              child: ClipRRect(borderRadius: BorderRadius.circular(8), child: p.imagenPath != null ? Image.file(File(p.imagenPath!), width: 60, height: 60, fit: BoxFit.cover) : const Icon(Icons.image_outlined)),
                            )
                          : isSelected ? Checkbox(value: isItemSelection, onChanged: (_) => pp.toggleSelection(p.id!)) : null,
                        title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(p.categoria),
                        trailing: Text(fCurrency.format(p.precio), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        onTap: () => isSelected ? pp.toggleSelection(p.id!) : Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditProductScreen(producto: p))),
                        onLongPress: () => pp.toggleSelection(p.id!),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
      floatingActionButton: isSelected ? null : FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditProductScreen())),
        label: Text(pp.tr('new')),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _abrirEscanner(BuildContext context) {
    final pp = context.read<ProductProvider>();
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: MobileScanner(
          onDetect: (capture) async {
            final barcodes = capture.barcodes;
            if (barcodes.isNotEmpty) {
              final code = barcodes.first.rawValue ?? "";
              Navigator.pop(ctx);
              final p = await DatabaseHelper.instance.getProductoByCodigo(code);
              if (mounted) {
                if (p != null) { Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditProductScreen(producto: p))); } 
                else { AwesomeDialog(context: context, dialogType: DialogType.question, title: pp.tr('not_found'), btnOkOnPress: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditProductScreen(nuevoCodigo: code)))).show(); }
              }
            }
          },
        ),
      ),
    );
  }

  void _confirmDeleteSelected(BuildContext context) {
    AwesomeDialog(context: context, dialogType: DialogType.question, title: 'Delete?', btnOkOnPress: () => context.read<ProductProvider>().deleteSelected()).show();
  }

  Widget _buildDrawer(BuildContext context) {
    final pp = context.watch<ProductProvider>();
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 110, decoration: const BoxDecoration(color: Colors.green), padding: const EdgeInsets.fromLTRB(16, 40, 16, 10),
            child: Row(children: [const Icon(Icons.store, color: Colors.white, size: 32), const SizedBox(width: 12), Text(pp.tr('app_title'), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))]),
          ),
          ListTile(leading: const Icon(Icons.calculate, color: Colors.blue), title: Text(pp.tr('drawer_pos')), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen())); }),
          ListTile(leading: const Icon(Icons.share), title: Text(pp.tr('drawer_export')), onTap: () async { Navigator.pop(context); String path = await pp.exportToCSV(); Share.shareXFiles([XFile(path)]); }),
          ListTile(leading: const Icon(Icons.file_upload), title: Text(pp.tr('drawer_import')), onTap: () async { Navigator.pop(context); await pp.importFromCSV(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pp.tr('import_ok')))); }),
          const Divider(),
          SwitchListTile(secondary: const Icon(Icons.image_outlined), title: Text(pp.tr('drawer_photos')), value: pp.mostrarImagenes, onChanged: (val) => pp.toggleMostrarImagenes(val)),
          ListTile(leading: const Icon(Icons.language, color: Colors.orange), title: Text(pp.tr('drawer_language')), trailing: Text(pp.idioma == 'en' ? "🇺🇸 EN" : "🇪🇸 ES"), onTap: () => pp.toggleIdioma()),
          const Divider(),
          ListTile(leading: const Icon(Icons.delete_sweep, color: Colors.red), title: Text(pp.tr('drawer_delete_all')), onTap: () { Navigator.pop(context); AwesomeDialog(context: context, title: pp.tr('delete_q'), btnOkOnPress: () => pp.clearAll()).show(); }),
        ],
      ),
    );
  }
}