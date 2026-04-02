import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart'; // <--- LIBRERÍA DE AUDIO
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
  
  // Creamos el reproductor de audio
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Función para el PITIDO REAL y VIBRACIÓN FUERTE
  void _feedbackEscaneo() async {
    try {
      // 1. Sonido MP3 (Suena como supermercado)
      await _audioPlayer.play(AssetSource('sounds/beep.mp3'), volume: 1.0);
      
      // 2. Vibración pesada (Se siente más)
      await HapticFeedback.heavyImpact(); 
    } catch (e) {
      debugPrint("Error en sonido: $e");
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose(); // Limpiamos la memoria al cerrar
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Caja - Nueva Venta"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.red),
            onPressed: () => provider.limpiarCarrito(),
          )
        ],
      ),
      body: Column(
        children: [
          // ÁREA DE CÁMARA
          SizedBox(
            height: 180,
            child: MobileScanner(
              onDetect: (capture) async {
                final String code = capture.barcodes.first.rawValue ?? "";
                final ahora = DateTime.now();

                if (code == _ultimoCodigo && ahora.difference(_ultimaVezEscaneado).inSeconds < 2) {
                  return;
                }

                _ultimoCodigo = code;
                _ultimaVezEscaneado = ahora;

                final p = await DatabaseHelper.instance.getProductoByCodigo(code);
                if (p != null) {
                  provider.agregarAlCarrito(p);
                  _feedbackEscaneo(); // <--- AQUÍ SUENA EL MP3
                }
              },
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, 
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50)
              ),
              icon: const Icon(Icons.search),
              label: const Text("BUSCAR PRODUCTO MANUAL"),
              onPressed: () => _mostrarSelectorManual(context),
            ),
          ),

          Expanded(
            child: provider.carrito.isEmpty 
              ? const Center(child: Text("Escanea o busca productos"))
              : ListView.builder(
                  itemCount: provider.carrito.length,
                  itemBuilder: (ctx, i) {
                    final item = provider.carrito[i];
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
                            IconButton(icon: const Icon(Icons.remove_circle, color: Colors.orange), onPressed: () => provider.removerDelCarrito(i)),
                            IconButton(icon: const Icon(Icons.add_circle, color: Colors.green), onPressed: () => provider.agregarAlCarrito(item.producto)),
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
                const Text("TOTAL:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(fCurrency.format(provider.totalCarrito), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _mostrarSelectorManual(BuildContext context) {
    final allProducts = context.read<ProductProvider>().items;
    List<Producto> filteredList = List.from(allProducts);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.85,
            child: Column(
              children: [
                const SizedBox(height: 15),
                const Text("Buscar Producto", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: "Escriba el nombre...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: (value) {
                      setModalState(() {
                        filteredList = allProducts
                            .where((p) => p.nombre.toLowerCase().contains(value.toLowerCase()) || 
                                          p.categoria.toLowerCase().contains(value.toLowerCase()))
                            .toList();
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
                        title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(p.categoria),
                        trailing: Text(fCurrency.format(p.precio), style: const TextStyle(color: Colors.green)),
                        onTap: () {
                          context.read<ProductProvider>().agregarAlCarrito(p);
                          _feedbackEscaneo(); // También suena al buscar manual
                          Navigator.pop(ctx);
                        },
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