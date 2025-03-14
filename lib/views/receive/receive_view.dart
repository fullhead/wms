import 'package:flutter/material.dart';
import 'package:wms/core/session/auth_storage.dart';
import 'package:wms/models/receive.dart';
import 'package:wms/presenters/receive_presenter.dart';
import 'package:wms/presenters/product_presenter.dart';
import 'package:wms/presenters/cell_presenter.dart';
import 'package:wms/views/receive/receive_dialogs.dart';
import 'package:wms/views/receive/receive_cards.dart';
import 'package:wms/widgets/wms_drawer.dart';

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
      final receives = await _presenter.fetchAllReceives();
      if (!mounted) return;
      setState(() {
        _receives = receives;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка загрузки: $e"), duration: const Duration(seconds: 2)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildBody(BuildContext context) {
    final displayedReceives = _receives.where((r) {
      return _searchQuery.isEmpty ||
          r.product.productName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.product.productBarcode.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: 10,
        itemBuilder: (context, index) => const SkeletonCard(),
      );
    }

    if (displayedReceives.isEmpty) {
      if (_searchQuery.isNotEmpty) {
        return ListView(
          children: [
            const SizedBox(height: 400),
            Center(child: Text('Нечего не найдено!', style: Theme.of(context).textTheme.bodyMedium)),
          ],
        );
      } else {
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Нет записей приёмки. Добавьте новую запись.', style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _showCreateReceiveDialog,
                        child: const Text('Добавить запись'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return RefreshIndicator(
      onRefresh: _loadReceives,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: displayedReceives.length,
        itemBuilder: (context, index) {
          final receive = displayedReceives[index];
          return ReceiveCard(
            receive: receive,
            token: _token,
            onTap: () {
              ReceiveDialogs.showReceiveDetails(
                context: context,
                receive: receive,
                token: _token,
                onEdit: () {
                  Navigator.of(context).pop();
                  _showEditReceiveDialog(receive);
                },
                onDelete: () {
                  Navigator.of(context).pop();
                  _confirmDeleteReceive(receive);
                },
              );
            },
          );
        },
      ),
    );
  }

  void _startSearch() {
    setState(() => _isSearching = true);
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
    });
  }

  Future<void> _showEditReceiveDialog(Receive receive) async {
    await ReceiveDialogs.showEditReceiveDialog(
      context: context,
      receive: receive,
      productPresenter: _productPresenter,
      cellPresenter: _cellPresenter,
      token: _token,
      refreshReceives: _loadReceives,
    );
  }

  Future<void> _showCreateReceiveDialog() async {
    await ReceiveDialogs.showCreateReceiveDialog(
      context: context,
      presenter: _presenter,
      productPresenter: _productPresenter,
      cellPresenter: _cellPresenter,
      token: _token,
      refreshReceives: _loadReceives,
    );
  }

  Future<void> _confirmDeleteReceive(Receive receive) async {
    await ReceiveDialogs.confirmDeleteReceive(
      context: context,
      receive: receive,
      presenter: _presenter,
      refreshReceives: _loadReceives,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Поиск по приёмке...",
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        )
            : const Text("Приемка", style: TextStyle(color: Colors.deepOrange)),
        actions: _isSearching
            ? [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.deepOrange),
            onPressed: _stopSearch,
          ),
        ]
            : [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.deepOrange),
            onPressed: _startSearch,
          ),
        ],
      ),
      drawer: const WmsDrawer(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: _buildBody(context),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateReceiveDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
