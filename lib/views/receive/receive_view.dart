import 'package:flutter/material.dart';
import 'package:wms/core/session/auth_storage.dart';
import 'package:wms/models/receive.dart';
import 'package:wms/presenters/receive_presenter.dart';
import 'package:wms/presenters/product_presenter.dart';
import 'package:wms/presenters/cell_presenter.dart';
import 'package:wms/views/receive/receive_dialogs.dart';
import 'package:wms/views/receive/receive_cards.dart';
import 'package:wms/widgets/wms_drawer.dart';

/// Экран «Приёмка».
class ReceiveView extends StatefulWidget {
  const ReceiveView({super.key});

  @override
  ReceiveViewState createState() => ReceiveViewState();
}

class ReceiveViewState extends State<ReceiveView> {
  final ReceivePresenter _presenter = ReceivePresenter();
  final ProductPresenter _productPresenter = ProductPresenter();
  final CellPresenter _cellPresenter = CellPresenter();

  List<Receive> _receives = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String _searchQuery = '';
  String? _token;

  /* ──────────────────────────────────────────────────────────
   *  Жизненный цикл
   * ────────────────────────────────────────────────────────── */
  @override
  void initState() {
    super.initState();
    _loadToken();
    _loadReceives();
  }

  Future<void> _loadToken() async {
    _token = await AuthStorage.getAccessToken();
    if (mounted) setState(() {});
  }

  Future<void> _loadReceives() async {
    setState(() => _isLoading = true);
    try {
      final list = await _presenter.fetchAllReceives();
      if (!mounted) return;
      setState(() => _receives = list);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Ошибка загрузки: $e'),
            duration: const Duration(seconds: 2)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /* ──────────────────────────────────────────────────────────
   *  UI-helpers
   * ────────────────────────────────────────────────────────── */

  Widget _body(BuildContext context) {
    final filtered = _receives.where((r) {
      return _searchQuery.isEmpty ||
          r.product.productName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          r.product.productBarcode
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
    }).toList();

    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: 10,
        itemBuilder: (_, __) => const SkeletonCard(),
      );
    }

    if (filtered.isEmpty) {
      if (_searchQuery.isNotEmpty) {
        return ListView(
          children: [
            const SizedBox(height: 400),
            Center(
                child: Text('Нечего не найдено!',
                    style: Theme.of(context).textTheme.bodyMedium)),
          ],
        );
      }
      return Center(
        child: RefreshIndicator(
          onRefresh: _loadReceives,
          color: Theme.of(context).colorScheme.primary,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 80),
            children: [
              const SizedBox(height: 400),
              Center(
                child: Column(
                  children: [
                    Text('Нет записей приёмки. Добавьте новую запись.',
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 16),
                    ElevatedButton(
                        onPressed: _showCreateDialog,
                        child: const Text('Добавить запись')),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReceives,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: filtered.length,
        itemBuilder: (_, i) {
          final rec = filtered[i];
          return ReceiveCard(
            receive: rec,
            token: _token,
            onTap: () {
              ReceiveDialogs.showReceiveDetails(
                context: context,
                receive: rec,
                token: _token,
                onEdit: () {
                  Navigator.pop(context);
                  _showEditDialog(rec);
                },
                onDelete: () {
                  Navigator.pop(context);
                  _confirmDelete(rec);
                },
              );
            },
          );
        },
      ),
    );
  }

  void _startSearch() => setState(() => _isSearching = true);

  void _stopSearch() => setState(() {
        _isSearching = false;
        _searchQuery = '';
      });

  /* ──────────────────────────────────────────────────────────
   *  Диалоги
   * ────────────────────────────────────────────────────────── */

  Future<void> _showEditDialog(Receive r) async {
    await ReceiveDialogs.showEditReceiveDialog(
      context: context,
      receive: r,
      productPresenter: _productPresenter,
      cellPresenter: _cellPresenter,
      token: _token,
      refreshReceives: _loadReceives,
    );
  }

  Future<void> _showCreateDialog() async {
    await ReceiveDialogs.showCreateReceiveDialog(
      context: context,
      presenter: _presenter,
      productPresenter: _productPresenter,
      cellPresenter: _cellPresenter,
      token: _token,
      refreshReceives: _loadReceives,
    );
  }

  Future<void> _confirmDelete(Receive r) async {
    await ReceiveDialogs.confirmDeleteReceive(
      context: context,
      receive: r,
      presenter: _presenter,
      refreshReceives: _loadReceives,
    );
  }

  /* ──────────────────────────────────────────────────────────
   *  Build
   * ────────────────────────────────────────────────────────── */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                    hintText: 'Поиск по приёмке...', border: InputBorder.none),
                onChanged: (v) => setState(() => _searchQuery = v),
              )
            : const Text('Приёмка', style: TextStyle(color: Colors.deepOrange)),
        actions: _isSearching
            ? [
                IconButton(
                    icon: const Icon(Icons.close, color: Colors.deepOrange),
                    onPressed: _stopSearch)
              ]
            : [
                IconButton(
                    icon: const Icon(Icons.search, color: Colors.deepOrange),
                    onPressed: _startSearch),
              ],
      ),
      drawer: const WmsDrawer(),
      body: LayoutBuilder(
        builder: (_, __) => Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: _body(context)),
        ),
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: _showCreateDialog, child: const Icon(Icons.add)),
    );
  }
}
