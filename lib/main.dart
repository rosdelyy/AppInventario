import 'package:flutter/material.dart';

import 'screens/historial_screen.dart';
import 'screens/inventario_screen.dart';
import 'screens/nueva_venta_screen.dart';
import 'screens/registrar_producto_screen.dart';
import 'state/inventory_store.dart';
import 'theme/app_theme.dart';
import 'widgets/retail_app_bar.dart';
import 'widgets/retail_bottom_nav.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MiTiendaApp());
}

class MiTiendaApp extends StatefulWidget {
  const MiTiendaApp({super.key});

  @override
  State<MiTiendaApp> createState() => _MiTiendaAppState();
}

class _MiTiendaAppState extends State<MiTiendaApp> {
  final InventoryStore _store = InventoryStore();

  @override
  void initState() {
    super.initState();
    _store.cargarTodo();
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi Tienda POS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: MainShell(store: _store),
    );
  }
}

class MainShell extends StatefulWidget {
  final InventoryStore store;

  const MainShell({super.key, required this.store});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const List<String> _titles = [
    'Inventario',
    'Nueva Venta',
    'Registrar Producto',
    'Historial de Movimientos',
  ];

  void _navigateTo(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.surface,
          body: Column(
            children: [
              RetailAppBar(
                title: _titles[_currentIndex],
                store: widget.store,
              ),
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: [
                    InventarioScreen(
                      store: widget.store,
                      onGoToRegister: () => _navigateTo(2),
                    ),
                    NuevaVentaScreen(store: widget.store),
                    RegistrarProductoScreen(
                      store: widget.store,
                      onSavedGoInventory: () => _navigateTo(0),
                    ),
                    HistorialScreen(store: widget.store),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: RetailBottomNav(
            currentIndex: _currentIndex,
            onTap: _navigateTo,
          ),
        );
      },
    );
  }
}
