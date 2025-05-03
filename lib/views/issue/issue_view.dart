import 'package:flutter/material.dart';
import 'package:wms/core/session/auth_storage.dart';
import 'package:wms/models/issue.dart';
import 'package:wms/presenters/issue_presenter.dart';
import 'package:wms/presenters/product_presenter.dart';
import 'package:wms/presenters/cell_presenter.dart';
import 'package:wms/presenters/warehouse_presenter.dart';
import 'package:wms/views/issue/issue_dialogs.dart';
import 'package:wms/views/issue/issue_cards.dart';
import 'package:wms/widgets/wms_drawer.dart';

class IssueView extends StatefulWidget {
  const IssueView({super.key});

  @override
  IssueViewState createState() => IssueViewState();
}

class IssueViewState extends State<IssueView> {
  final IssuePresenter _presenter = IssuePresenter();
  final ProductPresenter _productPresenter = ProductPresenter();
  final CellPresenter _cellPresenter = CellPresenter();
  final WarehousePresenter _warehousePresenter = WarehousePresenter();

  List<Issue> _issues = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String _searchQuery = '';
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadToken();
    _loadIssues();
  }

  Future<void> _loadToken() async {
    _token = await AuthStorage.getAccessToken();
    if (mounted) setState(() {});
  }

  Future<void> _loadIssues() async {
    setState(() => _isLoading = true);
    try {
      final issues = await _presenter.fetchAllIssue(); // исправлено
      if (!mounted) return;
      setState(() => _issues = issues);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Ошибка загрузки: $e"),
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /* ────────────────────────────────────────────────────────
   *  UI-построение
   * ──────────────────────────────────────────────────────── */

  Widget _buildBody(BuildContext context) {
    final displayed = _issues.where((i) {
      return _searchQuery.isEmpty ||
          i.product.productName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          i.product.productBarcode
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

    if (displayed.isEmpty) {
      if (_searchQuery.isNotEmpty) {
        return ListView(
          children: [
            const SizedBox(height: 400),
            Center(
              child: Text('Ничего не найдено!',
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        );
      }
      return Center(
        child: RefreshIndicator(
          onRefresh: _loadIssues,
          color: Theme.of(context).colorScheme.primary,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 80),
            children: [
              const SizedBox(height: 400),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Нет записей выдачи. Добавьте новую.',
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _showCreateIssueDialog,
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

    return RefreshIndicator(
      onRefresh: _loadIssues,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: displayed.length,
        itemBuilder: (context, idx) {
          final issue = displayed[idx];
          return IssueCard(
            issue: issue,
            token: _token,
            onTap: () {
              IssueDialogs.showIssueDetails(
                context: context,
                issue: issue,
                token: _token,
                onEdit: () {
                  Navigator.pop(context);
                  _showEditIssueDialog(issue);
                },
                onDelete: () {
                  Navigator.pop(context);
                  _confirmDeleteIssue(issue);
                },
              );
            },
          );
        },
      ),
    );
  }

  /* ────────────────────────────────────────────────────────
   *  Действия
   * ──────────────────────────────────────────────────────── */

  void _startSearch() => setState(() => _isSearching = true);

  void _stopSearch() => setState(() {
        _isSearching = false;
        _searchQuery = '';
      });

  Future<void> _showEditIssueDialog(Issue issue) async {
    await IssueDialogs.showEditIssueDialog(
      context: context,
      issue: issue,
      productPresenter: _productPresenter,
      cellPresenter: _cellPresenter,
      warehousePresenter: _warehousePresenter,
      token: _token,
      refreshIssues: _loadIssues,
    );
  }

  Future<void> _showCreateIssueDialog() async {
    await IssueDialogs.showCreateIssueDialog(
      context: context,
      presenter: _presenter,
      productPresenter: _productPresenter,
      cellPresenter: _cellPresenter,
      warehousePresenter: _warehousePresenter,
      token: _token,
      refreshIssues: _loadIssues,
    );
  }

  Future<void> _confirmDeleteIssue(Issue issue) async {
    await IssueDialogs.confirmDeleteIssue(
      context: context,
      issue: issue,
      presenter: _presenter,
      refreshIssues: _loadIssues,
    );
  }

  /* ────────────────────────────────────────────────────────
   *  build
   * ──────────────────────────────────────────────────────── */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: "Поиск по выдаче...",
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              )
            : const Text('Выдача', style: TextStyle(color: Colors.deepOrange)),
        actions: _isSearching
            ? [
                IconButton(
                    icon: const Icon(Icons.close, color: Colors.deepOrange),
                    onPressed: _stopSearch),
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
            child: _buildBody(context),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateIssueDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
