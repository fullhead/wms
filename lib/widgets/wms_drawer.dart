import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:wms/core/constants.dart';
import 'package:wms/models/user.dart';
import 'package:wms/presenters/personalization/personalization_presenter.dart';
import 'package:wms/services/auth_storage.dart';
import 'package:wms/core/routes.dart';

class WmsDrawer extends StatefulWidget {
  const WmsDrawer({super.key});

  @override
  WmsDrawerState createState() => WmsDrawerState();
}

class WmsDrawerState extends State<WmsDrawer> {
  String? activeRoute;
  final PersonalizationPresenter _personalizationPresenter =
      PersonalizationPresenter();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    activeRoute = ModalRoute.of(context)?.settings.name;
  }

  TextStyle _menuItemStyle(String route) {
    final isActive = activeRoute == route;
    return TextStyle(
      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
      color: isActive ? Colors.blue : Colors.black,
      fontSize: 16,
    );
  }

  TextStyle _subItemStyle(String route) {
    final isActive = activeRoute == route;
    return TextStyle(
      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
      color: isActive ? Colors.blue : Colors.black,
      fontSize: 14,
    );
  }

  void _handleNavigation(String route) {
    if (activeRoute == route) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, route);
    }
  }

  Future<void> _logout() async {
    await AuthStorage.deleteToken();
    await AuthStorage.deleteUserID();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.authorization);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            color: Colors.blue,
            height: 172,
            padding: const EdgeInsets.all(12),
            child: FutureBuilder<User>(
              future: _personalizationPresenter.getCurrentUser(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return const Align(
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      'Администратор',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  );
                } else if (snapshot.hasData) {
                  final user = snapshot.data!;
                  final avatarUrl = user.userAvatar.isNotEmpty
                      ? '${AppConstants.apiBaseUrl}${user.userAvatar}'
                      : '${AppConstants.apiBaseUrl}/assets/user/no_image_user.png';
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Администратор',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 35,
                            backgroundImage:
                                CachedNetworkImageProvider(avatarUrl),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              user.userFullname,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 18),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: Text('Панель управления',
                style: _menuItemStyle(AppRoutes.dashboard)),
            selected: activeRoute == AppRoutes.dashboard,
            onTap: () => _handleNavigation(AppRoutes.dashboard),
          ),
          ExpansionTile(
            leading: const Icon(Icons.people_outline),
            title:
                const Text('Все пользователи', style: TextStyle(fontSize: 16)),
            initiallyExpanded: activeRoute == AppRoutes.users ||
                activeRoute == AppRoutes.groups,
            childrenPadding: const EdgeInsets.only(left: 24.0),
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title:
                    Text('Пользователи', style: _subItemStyle(AppRoutes.users)),
                selected: activeRoute == AppRoutes.users,
                onTap: () => _handleNavigation(AppRoutes.users),
              ),
              ListTile(
                leading: const Icon(Icons.group),
                title: Text('Группы', style: _subItemStyle(AppRoutes.groups)),
                selected: activeRoute == AppRoutes.groups,
                onTap: () => _handleNavigation(AppRoutes.groups),
              ),
            ],
          ),
          ExpansionTile(
            leading: const Icon(Icons.inventory),
            title: const Text('База продукции', style: TextStyle(fontSize: 16)),
            initiallyExpanded: activeRoute == AppRoutes.products ||
                activeRoute == AppRoutes.categories,
            childrenPadding: const EdgeInsets.only(left: 24.0),
            children: [
              ListTile(
                leading: const Icon(Icons.production_quantity_limits),
                title: Text('Все продукции',
                    style: _subItemStyle(AppRoutes.products)),
                selected: activeRoute == AppRoutes.products,
                onTap: () => _handleNavigation(AppRoutes.products),
              ),
              ListTile(
                leading: const Icon(Icons.category),
                title: Text('Категории',
                    style: _subItemStyle(AppRoutes.categories)),
                selected: activeRoute == AppRoutes.categories,
                onTap: () => _handleNavigation(AppRoutes.categories),
              ),
            ],
          ),
          ExpansionTile(
            leading: const Icon(Icons.settings),
            title: const Text('Управление запасами',
                style: TextStyle(fontSize: 16)),
            initiallyExpanded: activeRoute == AppRoutes.receipts ||
                activeRoute == AppRoutes.issues,
            childrenPadding: const EdgeInsets.only(left: 24.0),
            children: [
              ListTile(
                leading: const Icon(Icons.call_received),
                title:
                    Text('Приемка', style: _subItemStyle(AppRoutes.receipts)),
                selected: activeRoute == AppRoutes.receipts,
                onTap: () => _handleNavigation(AppRoutes.receipts),
              ),
              ListTile(
                leading: const Icon(Icons.call_made),
                title: Text('Выдача', style: _subItemStyle(AppRoutes.issues)),
                selected: activeRoute == AppRoutes.issues,
                onTap: () => _handleNavigation(AppRoutes.issues),
              ),
            ],
          ),
          ExpansionTile(
            leading: const Icon(Icons.account_balance),
            title: const Text('Учет запасов', style: TextStyle(fontSize: 16)),
            initiallyExpanded: activeRoute == AppRoutes.warehouse ||
                activeRoute == AppRoutes.cells,
            childrenPadding: const EdgeInsets.only(left: 24.0),
            children: [
              ListTile(
                leading: const Icon(Icons.warehouse),
                title: Text('Склад', style: _subItemStyle(AppRoutes.warehouse)),
                selected: activeRoute == AppRoutes.warehouse,
                onTap: () => _handleNavigation(AppRoutes.warehouse),
              ),
              ListTile(
                leading: const Icon(Icons.view_list),
                title: Text('Ячейки', style: _subItemStyle(AppRoutes.cells)),
                selected: activeRoute == AppRoutes.cells,
                onTap: () => _handleNavigation(AppRoutes.cells),
              ),
            ],
          ),
          ExpansionTile(
            leading: const Icon(Icons.insert_chart),
            title: const Text('Отчеты', style: TextStyle(fontSize: 16)),
            initiallyExpanded: activeRoute == AppRoutes.receiptReports ||
                activeRoute == AppRoutes.issueReports,
            childrenPadding: const EdgeInsets.only(left: 24.0),
            children: [
              ListTile(
                leading: const Icon(Icons.arrow_downward),
                title: Text('Отчеты по приемкам',
                    style: _subItemStyle(AppRoutes.receiptReports)),
                selected: activeRoute == AppRoutes.receiptReports,
                onTap: () => _handleNavigation(AppRoutes.receiptReports),
              ),
              ListTile(
                leading: const Icon(Icons.arrow_upward),
                title: Text('Отчеты по выдачам',
                    style: _subItemStyle(AppRoutes.issueReports)),
                selected: activeRoute == AppRoutes.issueReports,
                onTap: () => _handleNavigation(AppRoutes.issueReports),
              ),
            ],
          ),
          ListTile(
            leading: const Icon(Icons.person_pin),
            title: Text('Персонализация',
                style: _menuItemStyle(AppRoutes.personalization)),
            selected: activeRoute == AppRoutes.personalization,
            onTap: () => _handleNavigation(AppRoutes.personalization),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text(
              'Выйти',
              style:
                  TextStyle(fontWeight: FontWeight.normal, color: Colors.black),
            ),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}
