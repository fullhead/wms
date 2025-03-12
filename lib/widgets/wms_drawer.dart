import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:wms/core/constants.dart';
import 'package:wms/core/routes.dart';
import 'package:wms/models/user.dart';
import 'package:wms/presenters/personalization/personalization_presenter.dart';
import 'package:wms/core/session/auth_storage.dart';

class WmsDrawer extends StatefulWidget {
  const WmsDrawer({super.key});

  @override
  WmsDrawerState createState() => WmsDrawerState();
}

class WmsDrawerState extends State<WmsDrawer> {
  String? _activeRoute;
  String? _token;
  final _personalizationPresenter = PersonalizationPresenter();
  late Future<User?> _currentUserFuture;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadToken();
    _currentUserFuture = _personalizationPresenter.getCurrentUser();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _activeRoute = ModalRoute.of(context)?.settings.name;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadToken() async {
    _token = await AuthStorage.getAccessToken();
    if (mounted) setState(() {});
  }

  void _handleNavigation(String route) {
    if (_activeRoute == route) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, route);
    }
  }

  Future<void> _logout() async {
    await AuthStorage.clearSession();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.authorization);
  }

  // Стилизация пунктов меню:
  TextStyle _menuItemStyle(String route) {
    final isActive = _activeRoute == route;
    return TextStyle(
      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
      color: isActive ? Theme.of(context).colorScheme.primary : Colors.black87,
      fontSize: 16,
    );
  }

  TextStyle _subItemStyle(String route) {
    final isActive = _activeRoute == route;
    return TextStyle(
      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
      color: isActive ? Theme.of(context).colorScheme.primary : Colors.black87,
      fontSize: 14,
    );
  }

  Widget _buildAvatar(User user) {
    final userAvatar = user.userAvatar.isNotEmpty
        ? user.userAvatar
        : '/assets/user/no_image_user.png';
    final avatarUrl = '${AppConstants.apiBaseUrl}$userAvatar';
    return CircleAvatar(
      radius: 35,
      backgroundImage: CachedNetworkImageProvider(
        avatarUrl,
        headers: _token != null ? {"Authorization": "Bearer $_token"} : null,
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      color: Theme.of(context).primaryColor,
      height: 172,
      width: 304,
      padding: const EdgeInsets.all(12),
      child: FutureBuilder<User?>(
        future: _currentUserFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildHeaderSkeleton();
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'Администратор',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: Colors.white),
              ),
            );
          }
          final user = snapshot.data!;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Администратор',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildAvatar(user),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      user.userFullname,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderSkeleton() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 150,
          height: 20,
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ],
    );
  }

  Widget _buildDrawerFooter() {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        String versionInfo = 'Версия: -';
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          final packageInfo = snapshot.data!;
          versionInfo = 'Версия: ${packageInfo.version}+${packageInfo.buildNumber}';
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Transform.translate(
                  offset: const Offset(-5, 0),
                  child: Image.asset(
                    'lib/assets/logo.png',
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: const [
                  Text(
                    'Разработчик: ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    'Shakhzodbek Inomjonov',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text(
                    'Сайт: ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      final url = Uri.parse("https://shax.dev");
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: const Text(
                      'shax.dev',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text(
                    'Email: ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      final emailUri = Uri(
                        scheme: 'mailto',
                        path: 'shax29@ya.ru',
                      );
                      if (await canLaunchUrl(emailUri)) {
                        await launchUrl(emailUri);
                      }
                    },
                    child: const Text(
                      'shax29@ya.ru',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Лицензия: MIT License',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    versionInfo,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          _buildDrawerHeader(),
          Expanded(
            child: Column(
              children: [
                Flexible(
                  child: Scrollbar(
                    thumbVisibility: true,
                    controller: _scrollController,
                    child: ListView(
                      controller: _scrollController,
                      padding: EdgeInsets.zero,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.dashboard),
                          title: Text(
                            'Панель управления',
                            style: _menuItemStyle(AppRoutes.dashboard),
                          ),
                          selected: _activeRoute == AppRoutes.dashboard,
                          onTap: () => _handleNavigation(AppRoutes.dashboard),
                        ),
                        ExpansionTile(
                          leading: const Icon(Icons.people_outline),
                          title: const Text(
                            'Все пользователи',
                            style: TextStyle(fontSize: 16),
                          ),
                          initiallyExpanded: _activeRoute == AppRoutes.users ||
                              _activeRoute == AppRoutes.groups,
                          childrenPadding: const EdgeInsets.only(left: 24.0),
                          children: [
                            ListTile(
                              leading: const Icon(Icons.person),
                              title: Text(
                                'Пользователи',
                                style: _subItemStyle(AppRoutes.users),
                              ),
                              selected: _activeRoute == AppRoutes.users,
                              onTap: () => _handleNavigation(AppRoutes.users),
                            ),
                            ListTile(
                              leading: const Icon(Icons.group),
                              title: Text(
                                'Группы',
                                style: _subItemStyle(AppRoutes.groups),
                              ),
                              selected: _activeRoute == AppRoutes.groups,
                              onTap: () => _handleNavigation(AppRoutes.groups),
                            ),
                          ],
                        ),
                        ExpansionTile(
                          leading: const Icon(Icons.inventory),
                          title: const Text(
                            'База продукции',
                            style: TextStyle(fontSize: 16),
                          ),
                          initiallyExpanded: _activeRoute == AppRoutes.products ||
                              _activeRoute == AppRoutes.categories,
                          childrenPadding: const EdgeInsets.only(left: 24.0),
                          children: [
                            ListTile(
                              leading: const Icon(Icons.production_quantity_limits),
                              title: Text(
                                'Все продукции',
                                style: _subItemStyle(AppRoutes.products),
                              ),
                              selected: _activeRoute == AppRoutes.products,
                              onTap: () => _handleNavigation(AppRoutes.products),
                            ),
                            ListTile(
                              leading: const Icon(Icons.category),
                              title: Text(
                                'Категории',
                                style: _subItemStyle(AppRoutes.categories),
                              ),
                              selected: _activeRoute == AppRoutes.categories,
                              onTap: () => _handleNavigation(AppRoutes.categories),
                            ),
                          ],
                        ),
                        ExpansionTile(
                          leading: const Icon(Icons.settings),
                          title: const Text(
                            'Управление запасами',
                            style: TextStyle(fontSize: 16),
                          ),
                          initiallyExpanded: _activeRoute == AppRoutes.receives ||
                              _activeRoute == AppRoutes.issues,
                          childrenPadding: const EdgeInsets.only(left: 24.0),
                          children: [
                            ListTile(
                              leading: const Icon(Icons.call_received),
                              title: Text(
                                'Приемка',
                                style: _subItemStyle(AppRoutes.receives),
                              ),
                              selected: _activeRoute == AppRoutes.receives,
                              onTap: () => _handleNavigation(AppRoutes.receives),
                            ),
                            ListTile(
                              leading: const Icon(Icons.call_made),
                              title: Text(
                                'Выдача',
                                style: _subItemStyle(AppRoutes.issues),
                              ),
                              selected: _activeRoute == AppRoutes.issues,
                              onTap: () => _handleNavigation(AppRoutes.issues),
                            ),
                          ],
                        ),
                        ExpansionTile(
                          leading: const Icon(Icons.account_balance),
                          title: const Text(
                            'Учет запасов',
                            style: TextStyle(fontSize: 16),
                          ),
                          initiallyExpanded: _activeRoute == AppRoutes.warehouse ||
                              _activeRoute == AppRoutes.cells,
                          childrenPadding: const EdgeInsets.only(left: 24.0),
                          children: [
                            ListTile(
                              leading: const Icon(Icons.warehouse),
                              title: Text(
                                'Склад',
                                style: _subItemStyle(AppRoutes.warehouse),
                              ),
                              selected: _activeRoute == AppRoutes.warehouse,
                              onTap: () => _handleNavigation(AppRoutes.warehouse),
                            ),
                            ListTile(
                              leading: const Icon(Icons.view_list),
                              title: Text(
                                'Ячейки',
                                style: _subItemStyle(AppRoutes.cells),
                              ),
                              selected: _activeRoute == AppRoutes.cells,
                              onTap: () => _handleNavigation(AppRoutes.cells),
                            ),
                          ],
                        ),
                        ExpansionTile(
                          leading: const Icon(Icons.insert_chart),
                          title: const Text(
                            'Отчеты',
                            style: TextStyle(fontSize: 16),
                          ),
                          initiallyExpanded: _activeRoute == AppRoutes.receiptReports ||
                              _activeRoute == AppRoutes.issueReports,
                          childrenPadding: const EdgeInsets.only(left: 24.0),
                          children: [
                            ListTile(
                              leading: const Icon(Icons.arrow_downward),
                              title: Text(
                                'Отчеты по приемкам',
                                style: _subItemStyle(AppRoutes.receiptReports),
                              ),
                              selected: _activeRoute == AppRoutes.receiptReports,
                              onTap: () => _handleNavigation(AppRoutes.receiptReports),
                            ),
                            ListTile(
                              leading: const Icon(Icons.arrow_upward),
                              title: Text(
                                'Отчеты по выдачам',
                                style: _subItemStyle(AppRoutes.issueReports),
                              ),
                              selected: _activeRoute == AppRoutes.issueReports,
                              onTap: () => _handleNavigation(AppRoutes.issueReports),
                            ),
                          ],
                        ),
                        ListTile(
                          leading: const Icon(Icons.person_pin),
                          title: Text(
                            'Персонализация',
                            style: _menuItemStyle(AppRoutes.personalization),
                          ),
                          selected: _activeRoute == AppRoutes.personalization,
                          onTap: () => _handleNavigation(AppRoutes.personalization),
                        ),
                        ListTile(
                          leading: const Icon(Icons.exit_to_app),
                          title: const Text(
                            'Выйти',
                            style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black),
                          ),
                          onTap: _logout,
                        ),
                      ],
                    ),
                  ),
                ),

              ],
            ),
          ),
          _buildDrawerFooter(),
        ],
      ),
    );
  }
}
