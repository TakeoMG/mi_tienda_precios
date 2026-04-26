import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import '../providers/product_provider.dart';
import '../database/database_helper.dart';
import '../models/producto.dart';
import '../models/carrito_item.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _ultimoCodigo = "";
  DateTime _ultimaVezEscaneado = DateTime.now();
  final fCurrency = NumberFormat.currency(locale: 'es_CO', symbol: '\$ ', decimalDigits: 0);
  final AudioPlayer _audioPlayer = AudioPlayer();

  void _feedbackEscaneo() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/beep.mp3'), volume: 1.0);
      await HapticFeedback.heavyImpact(); 
    } catch (e) { debugPrint("Error: $e"); }
  }

  @override
  void dispose() { _audioPlayer.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<ProductProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(pp.tr('checkout_title')),
        actions: [
          IconButton(icon: const Icon(Icons.delete_sweep, color: Colors.red), 
          onPressed: () => pp.limpiarCarrito())
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 180,
            child: MobileScanner(
              onDetect: (capture) async {
                final String code = capture.barcodes.first.rawValue ?? "";
                final ahora = DateTime.now();
                if (code == _ultimoCodigo && ahora.difference(_ultimaVezEscaneado).inSeconds < 2) return;
                _ultimoCodigo = code;
                _ultimaVezEscaneado = ahora;
                final p = await DatabaseHelper.instance.getProductoByCodigo(code);
                if (p != null) {
                  pp.agregarAlCarrito(p);
                  _feedbackEscaneo();
                }
              },
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
              icon: const Icon(Icons.search),
              label: Text(pp.tr('manual_search')),
              onPressed: () => _mostrarSelectorManual(context),
            ),
          ),

          Expanded(
            child: pp.carrito.isEmpty 
              ? Center(child: Text(pp.tr('empty_cart')))
              : ListView.builder(
                  itemCount: pp.carrito.length,
                  itemBuilder: (ctx, i) {
                    final item = pp.carrito[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(8)),
                          child: Text("x${item.cantidad}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
                        ),
                        title: Text(item.producto.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(fCurrency.format(item.producto.precio)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(fCurrency.format(item.subtotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(icon: const Icon(Icons.remove_circle, color: Colors.orange), onPressed: () => pp.removerDelCarrito(i)),
                            IconButton(icon: const Icon(Icons.add_circle, color: Colors.green), onPressed: () => pp.agregarAlCarrito(item.producto)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),

          Container(
            padding: const EdgeInsets.all(20),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(pp.tr('total'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(fCurrency.format(pp.totalCarrito), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _mostrarSelectorManual(BuildContext context) {
    final pp = context.read<ProductProvider>();
    final allProducts = pp.items;
    List<Producto> filteredList = List.from(allProducts);
    
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.85,
            child: Column(
              children: [
                const SizedBox(height: 15),
                Text(pp.tr('select_product'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    autofocus: true,
                    decoration: InputDecoration(hintText: pp.tr('search_hint'), prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                    onChanged: (value) {
                      setModalState(() {
                        filteredList = allProducts.where((p) => p.nombre.toLowerCase().contains(value.toLowerCase())).toList();
                      });
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredList.length,
                    itemBuilder: (ctx, i) {
                      final p = filteredList[i];
                      return ListTile(
                        title: Text(p.nombre),
                        trailing: Text(fCurrency.format(p.precio)),
                        onTap: () { pp.agregarAlCarrito(p); _feedbackEscaneo(); Navigator.pop(ctx); },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}