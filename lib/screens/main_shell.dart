import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/ui.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_footer.dart';
import '../widgets/app_header.dart';
import 'alerts_screen.dart';
import 'home_screen.dart';
import 'insurance_form_screen.dart';
import 'invite_member_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'reminder_form_screen.dart';
import 'search_screen.dart';
import 'upload_document_screen.dart';
import 'vehicle_form_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _navKey = GlobalKey<NavigatorState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _observer = _ShellObserver();

  int _index = 0;
  int _unread = 0;
  bool _canPop = false;
  Map<String, dynamic>? _user;
  List<dynamic> _families = [];

  @override
  void initState() {
    super.initState();
    _observer.onChange = () {
      final canPop = _navKey.currentState?.canPop() ?? false;
      if (canPop != _canPop && mounted) {
        setState(() => _canPop = canPop);
      }
    };
    _loadChrome();
  }

  Future<void> _loadChrome() async {
    try {
      final api = ApiService.instance;
      final results = await Future.wait([
        api.getDashboard(familyRef: api.session.familyReferenceNumber),
        api.getUserDetails(),
        api.listMyFamilies().catchError((_) => {'families': []}),
      ]);
      if (!mounted) return;
      setState(() {
        _unread = (results[0]['notifications_unread'] as num?)?.toInt() ?? 0;
        _user = results[1];
        _families = (results[2]['families'] as List?) ?? [];
      });
    } catch (_) {}
  }

  void _goTab(int index) {
    _navKey.currentState?.popUntil((route) => route.isFirst);
    setState(() {
      _index = index;
      _canPop = false;
    });
  }

  void _onLeading() {
    if (_canPop) {
      _navKey.currentState?.maybePop();
      return;
    }
    _scaffoldKey.currentState?.openDrawer();
  }

  void _openBell() {
    _navKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    ).then((_) => _loadChrome());
  }

  Future<void> _openAdd() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Add to your vault', style: headingStyle(size: 20)),
                const SizedBox(height: 12),
                _sheetTile(Icons.upload_file, 'Upload document', 'document'),
                _sheetTile(Icons.person_add_alt, 'Invite family member', 'member'),
                _sheetTile(Icons.alarm_add, 'Add reminder', 'reminder'),
                _sheetTile(Icons.health_and_safety_outlined, 'Add insurance', 'insurance'),
                _sheetTile(Icons.directions_car_outlined, 'Add vehicle', 'vehicle'),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || action == null) return;
    final familyRef = ApiService.instance.session.familyReferenceNumber;
    Widget? dest;
    switch (action) {
      case 'document':
        dest = const UploadDocumentScreen();
        break;
      case 'member':
        if (familyRef != null) {
          dest = InviteMemberScreen(familyRef: familyRef);
        }
        break;
      case 'reminder':
        dest = const ReminderFormScreen();
        break;
      case 'insurance':
        dest = const InsuranceFormScreen();
        break;
      case 'vehicle':
        dest = const VehicleFormScreen();
        break;
    }
    if (dest == null) return;
    await _navKey.currentState?.push(MaterialPageRoute(builder: (_) => dest!));
    await _loadChrome();
  }

  Widget _sheetTile(IconData icon, String title, String value) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.bannerBlue,
        child: Icon(icon, color: AppColors.sky),
      ),
      title: Text(title, style: bodyStyle(weight: FontWeight.w600)),
      onTap: () => Navigator.pop(context, value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppChromeScope(
      unread: _unread,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: AppColors.white,
        ),
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            if (_navKey.currentState?.canPop() == true) {
              _navKey.currentState?.pop();
              return;
            }
            if (_index != 0) {
              _goTab(0);
            }
          },
          child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.white,
          extendBody: true,
          drawer: AppDrawer(
            user: _user,
            families: _families,
            navigatorKey: _navKey,
            onHome: () {
              Navigator.pop(context);
              _goTab(0);
            },
            onFamilyChanged: (ref) async {
              await ApiService.instance.session.saveFamily(ref);
              await _loadChrome();
              _goTab(0);
            },
          ),
          appBar: AppHeader(
            unread: _unread,
            showBack: _canPop,
            onLeading: _onLeading,
            onBell: _openBell,
          ),
          body: Navigator(
            key: _navKey,
            observers: [_observer],
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (_) {
                  final familyKey = ApiService.instance.session.familyReferenceNumber ?? 'none';
                  return IndexedStack(
                    index: _index,
                    children: [
                      HomeScreen(key: ValueKey('home-$familyKey')),
                      SearchScreen(key: ValueKey('search-$familyKey')),
                      AlertsScreen(key: ValueKey('alerts-$familyKey')),
                      ProfileScreen(key: ValueKey('profile-$familyKey')),
                    ],
                  );
                },
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _openAdd,
            backgroundColor: AppColors.navy,
            elevation: 4,
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: AppFooter(
            currentIndex: _index,
            unread: _unread,
            onTap: _goTab,
          ),
        ),
        ),
      ),
    );
  }
}

class _ShellObserver extends NavigatorObserver {
  VoidCallback? onChange;

  void _notify() => onChange?.call();

  @override
  void didPush(Route route, Route? previousRoute) => _notify();

  @override
  void didPop(Route route, Route? previousRoute) => _notify();

  @override
  void didRemove(Route route, Route? previousRoute) => _notify();

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) => _notify();
}
