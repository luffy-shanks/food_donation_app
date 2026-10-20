import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GoodFoodApp());
}

class GoodFoodApp extends StatefulWidget {
  const GoodFoodApp({super.key});
  @override State<GoodFoodApp> createState() => _GoodFoodAppState();
}

class _GoodFoodAppState extends State<GoodFoodApp> {
  late final Future<void> _ready;

  @override
  void initState() {
    super.initState();
    _ready = store.load().timeout(
      const Duration(seconds: 3),
      onTimeout: store.skipSlowRestore,
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'GoodFood Network',
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(),
    home: FutureBuilder<void>(
      future: _ready,
      builder: (context, snapshot) => snapshot.connectionState == ConnectionState.done
          ? const WelcomePage()
          : const _StartupScreen(),
    ),
  );
}

class _StartupScreen extends StatelessWidget {
  const _StartupScreen();

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.eco, size: 48, color: green),
            SizedBox(height: 16),
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Loading GoodFood…', style: TextStyle(color: muted)),
          ],
        ),
      ),
    ),
  );
}

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});
  @override State<WelcomePage> createState() => _WelcomePageState();
}
class _WelcomePageState extends State<WelcomePage> {
  Role role = Role.donor;
  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 76,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE4F0E7),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(Icons.eco, size: 42, color: green),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'GoodFood Network',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: ink, fontSize: 28, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Rescue good food. Share it with your community.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: muted),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'How will you use GoodFood?',
                      style: TextStyle(color: ink, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 5),
                    const Text('Choose the option that fits you.',
                        style: TextStyle(color: muted, fontSize: 13)),
                    const SizedBox(height: 14),
                    ...(const [Role.donor, Role.ngo]).map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(15),
                            onTap: () => setState(() => role = r),
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: role == r ? green : const Color(0xFFE2E9E3),
                                  width: role == r ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(_roleIcon(r), color: green),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(_roleTitle(r),
                                            style: const TextStyle(
                                                color: ink, fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 3),
                                        Text(_roleDescription(r),
                                            style: const TextStyle(
                                                color: muted, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  if (role == r) const Icon(Icons.check_circle, color: green),
                                ],
                              ),
                            ),
                          ),
                        )),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => MainShell(role: role)),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: green,
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: Text('Continue as ${_roleName(role)}'),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Demo access · no account needed',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MainShell(role: Role.admin),
                          ),
                        );
                      },
                      child: const Text('Admin login'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
String _roleName(Role r) => switch (r) {Role.donor => 'Donor', Role.ngo => 'NGO', Role.admin => 'Admin'};
IconData _roleIcon(Role r) => switch (r) {Role.donor => Icons.storefront_outlined, Role.ngo => Icons.volunteer_activism_outlined, Role.admin => Icons.admin_panel_settings_outlined};
String _roleTitle(Role r) => switch (r) {
      Role.donor => 'Donate food',
      Role.ngo => 'Find food for my NGO',
      Role.admin => 'Manage the platform',
    };
String _roleDescription(Role r) => switch (r) {
      Role.donor => 'I have surplus food to share.',
      Role.ngo => 'Request food and confirm deliveries.',
      Role.admin => 'For staff who review NGOs and activity.',
    };

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.role}); final Role role;
  @override State<MainShell> createState() => _MainShellState();
}
class _MainShellState extends State<MainShell> {
  int tab = 0;
  late final Timer _pickupTimer;
  @override
  void initState() {
    super.initState();
    store.checkPickupTimes();
    _pickupTimer = Timer.periodic(const Duration(minutes: 1), (_) => store.checkPickupTimes());
  }
  @override
  void dispose() { _pickupTimer.cancel(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final pages = switch (widget.role) {
      Role.donor => <Widget>[DonorHome(onCreate: create), const DonorListings(), const DonorRequests(), const ProfilePage(isNgo: false)],
      Role.ngo => <Widget>[const ExplorePage(), const NgoPickups(), const ProfilePage(isNgo: true)],
      Role.admin => <Widget>[const AdminOverview(), const VerificationPage(), const ReportsPage()],
    };
    return Scaffold(
      appBar: AppBar(title: const Row(children: [Icon(Icons.eco, color: green), SizedBox(width: 9), Text('GoodFood', style: TextStyle(fontWeight: FontWeight.w800)), Spacer()]), actions: [Padding(padding: const EdgeInsets.only(right: 12), child: Center(child: Text(_roleName(widget.role).toUpperCase(), style: const TextStyle(color: muted, fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.w700))))], leading: IconButton(tooltip: 'Switch role', icon: const Icon(Icons.swap_horiz), onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const WelcomePage()), (_) => false))),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: store,
          builder: (context, _) => IndexedStack(index: tab, children: pages),
        ),
      ),
      floatingActionButton: widget.role == Role.donor && tab < 2 ? FloatingActionButton.extended(onPressed: create, backgroundColor: green, foregroundColor: Colors.white, icon: const Icon(Icons.add), label: const Text('Donate food')) : null,
      bottomNavigationBar: AnimatedBuilder(animation: store, builder: (context, _) {
        final donorUnread = store.activityFor(Role.donor).where((a) => !a.read).length;
        final ngoUnread = store.activityFor(Role.ngo).where((a) => !a.read).length;
        final tabs = switch (widget.role) {
          Role.donor => <NavigationDestination>[
            const NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
            const NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'My food'),
            NavigationDestination(icon: Badge(isLabelVisible: donorUnread > 0, label: Text('$donorUnread'), child: const Icon(Icons.notifications_outlined)), label: 'Requests'),
            const NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
          Role.ngo => <NavigationDestination>[
            const NavigationDestination(icon: Icon(Icons.explore_outlined), label: 'Explore'),
            NavigationDestination(icon: Badge(isLabelVisible: ngoUnread > 0, label: Text('$ngoUnread'), child: const Icon(Icons.local_shipping_outlined)), label: 'My pickups'),
            const NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
          Role.admin => const [NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Overview'), NavigationDestination(icon: Icon(Icons.verified_user_outlined), label: 'NGO review'), NavigationDestination(icon: Icon(Icons.report_outlined), label: 'Reports')],
        };
        return NavigationBar(selectedIndex: tab, onDestinationSelected: (v) {
          setState(() => tab = v);
          if (widget.role == Role.donor && v == 2) store.markActivitiesRead(Role.donor);
          if (widget.role == Role.ngo && v == 1) store.markActivitiesRead(Role.ngo);
        }, destinations: tabs);
      }),
    );
  }
  Future<void> create() async { final d = await Navigator.push<Donation>(context, MaterialPageRoute(builder: (_) => const CreateDonationPage())); if (d != null) store.add(d); }
}

// App theme
const green = Color(0xFF247A55);
const ink = Color(0xFF20342A);
const muted = Color(0xFF77847D);
const canvas = Color(0xFFF5F7F4);

ThemeData buildAppTheme() => ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: canvas,
  colorScheme: ColorScheme.fromSeed(seedColor: green),
  appBarTheme: const AppBarTheme(backgroundColor: canvas, foregroundColor: ink, elevation: 0),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true, fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
  ),
);

// In-memory demo data and workflow state
String _displayTime(DateTime value) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(value.year, value.month, value.day);
  final day = date == today ? 'Today' : date == today.add(const Duration(days: 1)) ? 'Tomorrow' : '${value.month}/${value.day}';
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day, $hour:$minute ${value.hour < 12 ? 'AM' : 'PM'}';
}

enum Role { donor, ngo, admin }
enum Stage { pending, approved, rejected, cancelled, missed, collected, delivered }

class Donation {
  Donation(this.id, this.name, this.donor, this.qty, this.unit, this.category,
      this.foodType, this.address, this.ready, this.deadline, this.notes,
      {this.readyAt, this.deadlineAt, this.photoUrl = '', this.latitude, this.longitude, this.kgPerUnit = 0, this.preparation = '', this.storage = '', this.allergens = '', this.donorDelivers = false});
  final int id;
  final String name, donor, unit, category, foodType, address, ready, deadline, notes;
  final DateTime? readyAt, deadlineAt;
  final String photoUrl;
  final double? latitude, longitude;
  final double kgPerUnit;
  final String preparation, storage, allergens;
  final bool donorDelivers;
  int qty;

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'donor': donor, 'qty': qty, 'unit': unit,
    'category': category, 'foodType': foodType, 'address': address,
    'ready': ready, 'deadline': deadline, 'notes': notes,
    'readyAt': readyAt?.toIso8601String(), 'deadlineAt': deadlineAt?.toIso8601String(),
    'photoUrl': photoUrl, 'latitude': latitude, 'longitude': longitude,
    'kgPerUnit': kgPerUnit, 'preparation': preparation, 'storage': storage,
    'allergens': allergens, 'donorDelivers': donorDelivers,
  };

  factory Donation.fromJson(Map<String, dynamic> json) => Donation(
    json['id'] as int, json['name'] as String, json['donor'] as String,
    json['qty'] as int, json['unit'] as String, json['category'] as String,
    json['foodType'] as String, json['address'] as String, json['ready'] as String,
    json['deadline'] as String, json['notes'] as String,
    readyAt: json['readyAt'] == null ? null : DateTime.parse(json['readyAt'] as String),
    deadlineAt: json['deadlineAt'] == null ? null : DateTime.parse(json['deadlineAt'] as String),
    photoUrl: json['photoUrl'] as String? ?? '',
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    kgPerUnit: (json['kgPerUnit'] as num?)?.toDouble() ?? 0,
    preparation: json['preparation'] as String? ?? '',
    storage: json['storage'] as String? ?? '',
    allergens: json['allergens'] as String? ?? '',
    donorDelivers: json['donorDelivers'] as bool? ?? false,
  );
}

class PickupRequest {
  PickupRequest(this.id, this.donationId, this.ngo, this.qty, this.pickupAt, this.ngoLocation);
  final int id, donationId, qty;
  final String ngo;
  final DateTime pickupAt;
  final String ngoLocation;
  Stage stage = Stage.pending;
  String? pickupCode;
  String? cancelReason, missedReason;
  DateTime? collectedAt, deliveredAt;
  bool dueNoticeSent = false;

  Map<String, dynamic> toJson() => {
    'id': id, 'donationId': donationId, 'ngo': ngo, 'qty': qty,
    'pickupAt': pickupAt.toIso8601String(), 'ngoLocation': ngoLocation,
    'stage': stage.name, 'pickupCode': pickupCode, 'cancelReason': cancelReason,
    'missedReason': missedReason, 'collectedAt': collectedAt?.toIso8601String(),
    'deliveredAt': deliveredAt?.toIso8601String(), 'dueNoticeSent': dueNoticeSent,
  };

  factory PickupRequest.fromJson(Map<String, dynamic> json) {
    final request = PickupRequest(
      json['id'] as int, json['donationId'] as int, json['ngo'] as String,
      json['qty'] as int, DateTime.parse(json['pickupAt'] as String),
      json['ngoLocation'] as String? ?? '',
    );
    request.stage = Stage.values.firstWhere(
      (value) => value.name == json['stage'], orElse: () => Stage.pending,
    );
    request.pickupCode = json['pickupCode'] as String?;
    request.cancelReason = json['cancelReason'] as String?;
    request.missedReason = json['missedReason'] as String?;
    request.collectedAt = json['collectedAt'] == null ? null : DateTime.parse(json['collectedAt'] as String);
    request.deliveredAt = json['deliveredAt'] == null ? null : DateTime.parse(json['deliveredAt'] as String);
    request.dueNoticeSent = json['dueNoticeSent'] as bool? ?? false;
    return request;
  }
}

class ActivityEvent {
  ActivityEvent(this.role, this.ngo, this.title, this.message,
      {this.donor = '', DateTime? createdAt})
      : createdAt = createdAt ?? DateTime.now();
  final Role role;
  final String ngo, title, message, donor;
  final DateTime createdAt;
  bool read = false;

  Map<String, dynamic> toJson() => {
    'role': role.name, 'ngo': ngo, 'title': title, 'message': message,
    'donor': donor, 'createdAt': createdAt.toIso8601String(), 'read': read,
  };

  factory ActivityEvent.fromJson(Map<String, dynamic> json) {
    final event = ActivityEvent(
      Role.values.firstWhere((value) => value.name == json['role'], orElse: () => Role.donor),
      json['ngo'] as String? ?? '', json['title'] as String? ?? '',
      json['message'] as String? ?? '', donor: json['donor'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
    event.read = json['read'] as bool? ?? false;
    return event;
  }
}

class Store extends ChangeNotifier {
  int _donationId = 4, _requestId = 1;
  bool _restoreAllowed = true;
  String currentNgo = 'Hope Shelter';
  String currentDonor = 'Green Basket Market';
  double ngoLatitude = 12.9750, ngoLongitude = 77.6050;
  final donations = <Donation>[
    Donation(1, 'Fresh vegetable boxes', 'Green Basket Market', 12, 'boxes', 'Produce', 'Vegetarian', '12 Lake Road, Green Park', _displayTime(_nextAt(14, 30)), _displayTime(_afterReady(_nextAt(14, 30), 17)), 'Keep cool; packed in reusable crates.', readyAt: _nextAt(14, 30), deadlineAt: _afterReady(_nextAt(14, 30), 17), latitude: 12.9780, longitude: 77.6000, kgPerUnit: 3.5, preparation: 'Fresh produce; rinse before serving.', storage: 'Keep cool in reusable crates.', allergens: 'None declared.'),
    Donation(2, 'Prepared lunch meals', 'Sunrise Community Kitchen', 25, 'meals', 'Meals', 'Vegetarian', '8 Market Street', _displayTime(_nextAt(15)), _displayTime(_afterReady(_nextAt(15), 16, 30)), 'Contains dairy. Keep sealed.', readyAt: _nextAt(15), deadlineAt: _afterReady(_nextAt(15), 16, 30), latitude: 12.9690, longitude: 77.5900, kgPerUnit: 0.45, preparation: 'Prepared today and packed as individual meals.', storage: 'Keep chilled and sealed.', allergens: 'Contains dairy.'),
    Donation(3, 'Bakery bread & rolls', 'Cornerstone Bakery', 18, 'packs', 'Bakery', 'Vegetarian', '44 Central Avenue', _displayTime(_nextAt(16, 15)), _displayTime(_afterReady(_nextAt(16, 15), 19)), 'Packed this morning.', readyAt: _nextAt(16, 15), deadlineAt: _afterReady(_nextAt(16, 15), 19), latitude: 12.9870, longitude: 77.6150, kgPerUnit: 0.3, preparation: 'Baked this morning and packed.', storage: 'Keep dry and sealed.', allergens: 'Contains wheat (gluten).'),
  ];
  final requests = <PickupRequest>[];
  final activities = <ActivityEvent>[];
  final ngos = <String, bool>{'Hope Shelter': true, 'Sunrise Community Kitchen': true, 'New Dawn Outreach': false};
  static const demoDonors = ['Green Basket Market', 'Sunrise Community Kitchen', 'Cornerstone Bakery', 'Community donor'];
  List<Donation> get donorDonations => donations.where((d) => d.donor == currentDonor).toList();
  List<PickupRequest> get donorRequests => requests.where((r) => find(r.donationId)?.donor == currentDonor).toList();

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!_restoreAllowed) return;
      final saved = prefs.getString('goodfood_demo_state_v1');
      if (saved == null) return;
      final data = jsonDecode(saved) as Map<String, dynamic>;
      final savedDonations = data['donations'] as List<dynamic>?;
      final savedRequests = data['requests'] as List<dynamic>?;
      final savedActivities = data['activities'] as List<dynamic>?;
      if (savedDonations != null) donations
        ..clear()
        ..addAll(savedDonations.map((value) => Donation.fromJson(Map<String, dynamic>.from(value as Map))));
      if (savedRequests != null) requests
        ..clear()
        ..addAll(savedRequests.map((value) => PickupRequest.fromJson(Map<String, dynamic>.from(value as Map))));
      if (savedActivities != null) activities
        ..clear()
        ..addAll(savedActivities.map((value) => ActivityEvent.fromJson(Map<String, dynamic>.from(value as Map))));
      _donationId = data['donationId'] as int? ?? (donations.isEmpty ? 1 : donations.map((d) => d.id).fold<int>(0, (maxId, id) => id > maxId ? id : maxId) + 1);
      _requestId = data['requestId'] as int? ?? (requests.isEmpty ? 1 : requests.map((r) => r.id).fold<int>(0, (maxId, id) => id > maxId ? id : maxId) + 1);
      currentNgo = data['currentNgo'] as String? ?? currentNgo;
      currentDonor = data['currentDonor'] as String? ?? currentDonor;
      ngoLatitude = (data['ngoLatitude'] as num?)?.toDouble() ?? ngoLatitude;
      ngoLongitude = (data['ngoLongitude'] as num?)?.toDouble() ?? ngoLongitude;
      final savedNgos = data['ngos'];
      if (savedNgos is Map) ngos
        ..clear()
        ..addAll(savedNgos.map((key, value) => MapEntry(key.toString(), value == true)));
    } catch (_) {
      // Keep built-in sample data if saved demo data is incomplete or unreadable.
    }
  }

  void skipSlowRestore() => _restoreAllowed = false;

  void _save() {
    unawaited(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('goodfood_demo_state_v1', jsonEncode({
          'donationId': _donationId, 'requestId': _requestId,
          'currentNgo': currentNgo, 'currentDonor': currentDonor,
          'ngoLatitude': ngoLatitude, 'ngoLongitude': ngoLongitude, 'ngos': ngos,
          'donations': donations.map((d) => d.toJson()).toList(),
          'requests': requests.map((r) => r.toJson()).toList(),
          'activities': activities.take(100).map((event) => event.toJson()).toList(),
        }));
      } catch (_) {
        // The app remains usable if device storage is unavailable.
      }
    }());
  }
  static DateTime _nextAt(int hour, [int minute = 0]) {
    final now = DateTime.now();
    var value = DateTime(now.year, now.month, now.day, hour, minute);
    if (value.isBefore(now)) value = value.add(const Duration(days: 1));
    return value;
  }
  static DateTime _afterReady(DateTime ready, int hour, [int minute = 0]) {
    var deadline = DateTime(ready.year, ready.month, ready.day, hour, minute);
    if (!deadline.isAfter(ready)) deadline = deadline.add(const Duration(days: 1));
    return deadline;
  }
  Donation? find(int id) { for (final d in donations) { if (d.id == id) return d; } return null; }
  bool pendingFor(int id, String ngo) => requests.any((r) => r.donationId == id && r.ngo == ngo && r.stage == Stage.pending);
  void _notify(Role role, String ngo, String title, String message, {String donor = ''}) => activities.insert(0, ActivityEvent(role, ngo, title, message, donor: donor));
  void add(Donation d) { donations.insert(0, d); _save(); notifyListeners(); }
  Donation createDonation(String name, int quantity, String unit, String category,
      String foodType, String address, String ready, String deadline,
      String notes, DateTime readyAt, DateTime deadlineAt, String photoUrl,
      double? latitude, double? longitude, double kgPerUnit,
      String preparation, String storage, String allergens, bool donorDelivers) => Donation(_donationId++, name,
          currentDonor, quantity, unit, category, foodType, address,
          ready, deadline, notes, readyAt: readyAt, deadlineAt: deadlineAt,
          photoUrl: photoUrl, latitude: latitude, longitude: longitude, kgPerUnit: kgPerUnit,
          preparation: preparation, storage: storage, allergens: allergens, donorDelivers: donorDelivers);
  bool request(Donation d, String ngo, int qty, DateTime pickupAt, String ngoLocation) {
    if (ngos[ngo] != true || qty < 1 || qty > d.qty || pendingFor(d.id, ngo) || (d.donorDelivers && ngoLocation.trim().isEmpty) || !pickupAt.isAfter(DateTime.now()) || (d.readyAt != null && pickupAt.isBefore(d.readyAt!)) || (d.deadlineAt != null && pickupAt.isAfter(d.deadlineAt!))) return false;
    final request = PickupRequest(_requestId++, d.id, ngo, qty, pickupAt, ngoLocation.trim());
    requests.insert(0, request);
    _notify(Role.donor, ngo, 'New food request', '$ngo requested $qty ${d.unit} of ${d.name}; ${d.donorDelivers ? 'donor delivery' : 'NGO pickup'} planned for ${_displayTime(pickupAt)}.', donor: d.donor);
    _save();
    notifyListeners(); return true;
  }
  bool decide(PickupRequest r, bool accept) {
    final d = find(r.donationId);
    if (r.stage != Stage.pending || (accept && (!r.pickupAt.isAfter(DateTime.now()) || d == null || r.qty > d.qty || (d.readyAt != null && r.pickupAt.isBefore(d.readyAt!)) || (d.deadlineAt != null && r.pickupAt.isAfter(d.deadlineAt!))))) return false;
    r.stage = accept ? Stage.approved : Stage.rejected;
    if (accept) { d!.qty -= r.qty; r.pickupCode = ((r.id * 7919 + r.donationId * 1049) % 9000 + 1000).toString(); }
    final handoff = d?.donorDelivers == true ? 'delivery' : 'pickup';
    _notify(Role.ngo, r.ngo, accept ? 'Request approved' : 'Request declined', accept ? 'Your $handoff for ${d!.name} is approved for ${_displayTime(r.pickupAt)}.' : 'Your request for ${d?.name ?? 'food'} was declined.');
    _notify(Role.donor, r.ngo, accept ? '$handoff accepted' : 'Request declined', accept ? 'You accepted ${r.ngo}\'s request for ${d!.name}.' : 'You declined ${r.ngo}\'s request for ${d?.name ?? 'food'}.', donor: d?.donor ?? '');
    _save();
    notifyListeners(); return true;
  }
  bool cancel(PickupRequest r, String reason, {required Role cancelledBy}) {
    if (r.stage != Stage.pending && r.stage != Stage.approved) return false;
    if (r.stage == Stage.approved) {
      final d = find(r.donationId);
      if (d != null && (d.deadlineAt == null || d.deadlineAt!.isAfter(DateTime.now()))) d.qty += r.qty;
    }
    r.stage = Stage.cancelled; r.cancelReason = reason;
    final recipient = cancelledBy == Role.ngo ? Role.donor : Role.ngo;
    final d = find(r.donationId);
    final handoff = d?.donorDelivers == true ? 'delivery' : 'pickup';
    _notify(recipient, r.ngo, '$handoff cancelled', '${r.ngo} cancelled ${d?.name ?? 'a handoff'}: $reason', donor: recipient == Role.donor ? d?.donor ?? '' : '');
    _save();
    notifyListeners(); return true;
  }
  bool confirmCollection(PickupRequest r, String code) {
    if (r.stage != Stage.approved || r.pickupCode != code.trim()) return false;
    final d = find(r.donationId);
    r.collectedAt = DateTime.now();
    if (d?.donorDelivers == true) {
      r.stage = Stage.delivered;
      r.deliveredAt = r.collectedAt;
    } else {
      r.stage = Stage.collected;
    }
    final deliveryComplete = d?.donorDelivers == true;
    _notify(Role.donor, r.ngo, deliveryComplete ? 'Delivery completed' : 'Food collected', deliveryComplete ? '${r.ngo} confirmed receipt of ${d?.name ?? 'your donation'}. This handoff is complete.' : '${r.ngo} confirmed collection of ${d?.name ?? 'your donation'}.', donor: d?.donor ?? '');
    _save();
    notifyListeners(); return true;
  }
  void advance(PickupRequest r) { if (r.stage == Stage.collected) { r.stage = Stage.delivered; r.deliveredAt = DateTime.now(); final d = find(r.donationId); _notify(Role.donor, r.ngo, 'Delivery confirmed', '${r.ngo} confirmed distribution of ${d?.name ?? 'the donation'}.', donor: d?.donor ?? ''); _save(); notifyListeners(); } }
  void checkPickupTimes() {
    final now = DateTime.now();
    var changed = false;
    for (final r in requests.where((r) => r.stage == Stage.approved)) {
      final d = find(r.donationId);
      if (!r.dueNoticeSent && r.pickupAt.isAfter(now) && r.pickupAt.difference(now) <= const Duration(minutes: 30)) {
        r.dueNoticeSent = true;
        final handoff = d?.donorDelivers == true ? 'delivery' : 'pickup';
        _notify(Role.ngo, r.ngo, '$handoff due soon', '${handoff[0].toUpperCase()}${handoff.substring(1)} for ${d?.name ?? 'your donation'} is planned for ${_displayTime(r.pickupAt)}.');
        _notify(Role.donor, r.ngo, '$handoff due soon', d?.donorDelivers == true ? 'You are expected to deliver ${d?.name ?? 'your donation'} to ${r.ngo} at ${_displayTime(r.pickupAt)}.' : '${r.ngo} is expected to collect ${d?.name ?? 'your donation'} at ${_displayTime(r.pickupAt)}.', donor: d?.donor ?? '');
        changed = true;
      } else if (!r.pickupAt.isAfter(now)) {
        r.stage = Stage.missed;
        r.missedReason = d?.donorDelivers == true ? 'Delivery time passed without receipt confirmation.' : 'Pickup time passed without collection confirmation.';
        if (d != null && (d.deadlineAt == null || d.deadlineAt!.isAfter(now))) d.qty += r.qty;
        _notify(Role.ngo, r.ngo, 'Handoff missed', r.missedReason!);
        _notify(Role.donor, r.ngo, 'Handoff missed', d?.donorDelivers == true ? '${r.ngo} did not confirm receipt of ${d?.name ?? 'your donation'}.' : '${r.ngo} did not confirm pickup of ${d?.name ?? 'your donation'}.', donor: d?.donor ?? '');
        changed = true;
      }
    }
    if (changed) { _save(); notifyListeners(); }
  }
  bool _belongsToRole(ActivityEvent event, Role role) => event.role == role &&
      (role != Role.ngo || event.ngo == currentNgo) &&
      (role != Role.donor || event.donor.isEmpty || event.donor == currentDonor);
  void markActivitiesRead(Role role) { var changed = false; for (final a in activities.where((a) => _belongsToRole(a, role))) { if (!a.read) { a.read = true; changed = true; } } if (changed) { _save(); notifyListeners(); } }
  List<ActivityEvent> activityFor(Role role) => activities.where((a) => _belongsToRole(a, role)).toList();
  double? distanceKm(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return null;
    const radius = 6371.0;
    final lat1 = ngoLatitude * math.pi / 180, lat2 = latitude * math.pi / 180;
    final deltaLat = (latitude - ngoLatitude) * math.pi / 180;
    final deltaLon = (longitude - ngoLongitude) * math.pi / 180;
    final a = math.pow(math.sin(deltaLat / 2), 2) + math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(deltaLon / 2), 2);
    return radius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }
  void setNgoLocation(double latitude, double longitude) { ngoLatitude = latitude; ngoLongitude = longitude; _save(); notifyListeners(); }
  void verify(String name, bool value) { ngos[name] = value; _save(); notifyListeners(); }
  void selectNgo(String name) { if (ngos.containsKey(name)) { currentNgo = name; _save(); notifyListeners(); } }
  void selectDonor(String name) { if (demoDonors.contains(name)) { currentDonor = name; _save(); notifyListeners(); } }
  int get deliveredItems => requests.where((r) => r.stage == Stage.delivered).fold(0, (sum, r) => sum + r.qty);
  int get deliveredMeals => requests.where((r) => r.stage == Stage.delivered && (find(r.donationId)?.unit.toLowerCase().contains('meal') ?? false)).fold(0, (sum, r) => sum + r.qty);
  int get completedPickups => requests.where((r) => r.stage == Stage.delivered).length;
  int get completedDonations => requests.where((r) => r.stage == Stage.delivered).map((r) => r.donationId).toSet().length;
  double get rescuedKg => requests.where((r) => r.stage == Stage.delivered).fold(0.0, (sum, r) => sum + r.qty * (find(r.donationId)?.kgPerUnit ?? 0));
  List<int> get weeklyDelivered => List<int>.generate(7, (index) {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - index));
    return requests.where((r) => r.stage == Stage.delivered && r.deliveredAt != null && r.deliveredAt!.year == day.year && r.deliveredAt!.month == day.month && r.deliveredAt!.day == day.day).fold(0, (sum, r) => sum + r.qty);
  });
  bool isAvailable(Donation d) => d.qty > 0 && (d.deadlineAt == null || d.deadlineAt!.isAfter(DateTime.now()));
}

final store = Store();

class ImpactPanel extends StatelessWidget {
  const ImpactPanel({super.key});
  @override
  Widget build(BuildContext context) {
    final week = store.weeklyDelivered;
    final maxValue = week.fold<int>(0, (max, value) => value > max ? value : max);
    return Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: green, borderRadius: BorderRadius.circular(22)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Confirmed community impact', style: TextStyle(color: Colors.white70)),
      const SizedBox(height: 5), Text('${store.deliveredMeals} meals delivered', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 23)),
      const SizedBox(height: 5),
      const Text('SDG 2 · Zero Hunger   |   SDG 12 · Responsible Consumption', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11)),
      const SizedBox(height: 12),
      Wrap(spacing: 18, runSpacing: 8, children: [
        _metric('${store.completedDonations}', 'donations completed'),
        _metric('${store.deliveredItems}', 'items delivered'),
        _metric('${store.rescuedKg.toStringAsFixed(1)} kg', 'food rescued'),
      ]),
      const SizedBox(height: 14), const Text('Items delivered · last 7 days', style: TextStyle(color: Colors.white70, fontSize: 11)),
      const SizedBox(height: 7), SizedBox(height: 62, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: List.generate(7, (index) {
        final now = DateTime.now();
        final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - index));
        final height = maxValue == 0 ? 4.0 : (week[index] / maxValue * 42).clamp(4.0, 42.0).toDouble();
        return Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
          Container(height: height, width: 12, decoration: BoxDecoration(color: Colors.white.withValues(alpha: week[index] == 0 ? .25 : .9), borderRadius: BorderRadius.circular(6))),
          const SizedBox(height: 4), Text(['M','T','W','T','F','S','S'][day.weekday - 1], style: const TextStyle(color: Colors.white70, fontSize: 9)),
        ]));
      }))),
      const SizedBox(height: 6),
      const Text('Rescued weight is estimated from the donor-entered weight per item.', style: TextStyle(color: Colors.white70, fontSize: 10)),
    ]));
  }
  Widget _metric(String value, String label) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)), Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10))]);
}

class ActivityFeed extends StatelessWidget {
  const ActivityFeed({super.key, required this.role});
  final Role role;
  @override
  Widget build(BuildContext context) {
    final events = store.activityFor(role);
    final unread = events.where((event) => !event.read).length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Text('Notifications', style: TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 17)), const SizedBox(width: 8), if (unread > 0) statusChip('$unread new')]),
      const SizedBox(height: 8),
      if (events.isEmpty) const Padding(padding: EdgeInsets.only(bottom: 14), child: Text('Updates about requests and pickup times will appear here.', style: TextStyle(color: muted, fontSize: 12))),
      ...events.take(8).map((event) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(event.read ? Icons.notifications_none : Icons.notifications_active_outlined, color: green, size: 19), const SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(event.title, style: const TextStyle(color: ink, fontWeight: FontWeight.w700, fontSize: 13)), const SizedBox(height: 2), Text(event.message, style: const TextStyle(color: muted, fontSize: 12)), const SizedBox(height: 3), Text(_displayTime(event.createdAt), style: const TextStyle(color: muted, fontSize: 10))]))]))),
      const SizedBox(height: 12),
    ]);
  }
}

// Donor and NGO screens
class DonorHome extends StatelessWidget {
  const DonorHome({super.key, required this.onCreate}); final VoidCallback onCreate;
  @override Widget build(BuildContext context) {
    final available = store.donorDonations.where(store.isAvailable).take(3).toList();
    return ListView(padding: const EdgeInsets.fromLTRB(20, 18, 20, 100), children: [
      const Text('Good afternoon 👋', style: TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 24)), const SizedBox(height: 5), const Text('Every donation helps feed a neighbor.', style: TextStyle(color: muted)), const SizedBox(height: 18),
      ImpactPanel(), const SizedBox(height: 22),
      const Text('Available listings', style: TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 18)), const SizedBox(height: 10),
      if (available.isEmpty) const Text('No food is currently available. Post a donation or check My food for accepted handoffs.', style: TextStyle(color: muted, fontSize: 12)),
      ...available.map((d) => DonationCard(item: d, role: Role.donor)),
      OutlinedButton.icon(onPressed: onCreate, icon: const Icon(Icons.add), label: const Text('Post surplus food')),
    ]);
  }
}

class DonorListings extends StatelessWidget {
  const DonorListings({super.key});
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [const Text('My food listings', style: TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 23)), const SizedBox(height: 6), const Text('Manage your food and view accepted handoff details.', style: TextStyle(color: muted)), const SizedBox(height: 16), if (store.donorDonations.isEmpty) const Text('You have no listings yet. Post surplus food to get started.', style: TextStyle(color: muted)), ...store.donorDonations.map((d) => DonationCard(item: d, role: Role.donor))]);
}

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key}); @override State<ExplorePage> createState() => _ExplorePageState();
}
class _ExplorePageState extends State<ExplorePage> {
  String filter = 'All', query = '';
  double radiusKm = 25;
  @override Widget build(BuildContext context) {
    final visible = store.donations.where((d) {
      final distance = store.distanceKm(d.latitude, d.longitude);
      return store.isAvailable(d) && (filter == 'All' || d.category == filter) && '${d.name} ${d.donor} ${d.address}'.toLowerCase().contains(query.toLowerCase()) && (distance == null || distance <= radiusKm);
    }).toList()..sort((a, b) => (store.distanceKm(a.latitude, a.longitude) ?? double.infinity).compareTo(store.distanceKm(b.latitude, b.longitude) ?? double.infinity));
    return ListView(padding: const EdgeInsets.fromLTRB(20, 18, 20, 100), children: [const Text('Food near you', style: TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 23)), const SizedBox(height: 5), const Text('Find food your organization can pick up or receive.', style: TextStyle(color: muted)), const SizedBox(height: 16), TextField(onChanged: (v) => setState(() => query = v), decoration: const InputDecoration(hintText: 'Search food, donor, or area', prefixIcon: Icon(Icons.search))), const SizedBox(height: 10), Text('Within ${radiusKm.round()} km', style: const TextStyle(color: ink, fontWeight: FontWeight.w600)), Slider(value: radiusKm, min: 1, max: 50, divisions: 49, label: '${radiusKm.round()} km', onChanged: (v) => setState(() => radiusKm = v)), Wrap(spacing: 7, children: ['All', 'Produce', 'Meals', 'Bakery', 'Other'].map((v) => ChoiceChip(label: Text(v), selected: filter == v, onSelected: (_) => setState(() => filter = v))).toList()), const SizedBox(height: 12), ...visible.map((d) => DonationCard(item: d, role: Role.ngo)), if (visible.isEmpty) const Text('No matching donations available in this distance.', textAlign: TextAlign.center, style: TextStyle(color: muted))]);
  }
}

class DonationCard extends StatelessWidget {
  const DonationCard({super.key, required this.item, required this.role});
  final Donation item;
  final Role role;

  @override
  Widget build(BuildContext context) {
    final hasPending = role == Role.donor
        ? store.requests.any((r) => r.donationId == item.id && r.stage == Stage.pending)
        : store.pendingFor(item.id, store.currentNgo);
    final acceptedHandoffs = role == Role.donor
        ? store.requests.where((r) => r.donationId == item.id && r.stage == Stage.approved && r.pickupCode != null).toList()
        : const <PickupRequest>[];
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: role == Role.donor ? () => _showDonationStatus(context) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE7ECE7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2E8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_foodIcon(item.category), color: green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: const TextStyle(color: ink, fontWeight: FontWeight.w800)),
                      Text(item.donor,
                          style: const TextStyle(color: muted, fontSize: 12)),
                      Text('${item.qty} ${item.unit} available · ${item.foodType}',
                          style: const TextStyle(
                              color: ink, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                if (role == Role.donor) const Icon(Icons.chevron_right, color: muted),
              ],
            ),
            if (item.photoUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(item.photoUrl, height: 150, width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(height: 90, color: canvas, alignment: Alignment.center, child: const Text('Food photo could not be loaded', style: TextStyle(color: muted, fontSize: 12))))),
            ],
            const Divider(height: 20),
            if (item.address.isNotEmpty)
              _detail(Icons.location_on_outlined, item.address),
            _detail(Icons.local_shipping_outlined, item.donorDelivers ? 'Donor will deliver' : 'NGO pickup required'),
            if (role == Role.ngo && store.distanceKm(item.latitude, item.longitude) != null)
              _detail(Icons.near_me_outlined, '${store.distanceKm(item.latitude, item.longitude)!.toStringAsFixed(1)} km from your service location'),
            const SizedBox(height: 4),
            _detail(Icons.schedule, 'Ready ${item.ready} · handoff by ${item.deadline}'),
            if (item.preparation.isNotEmpty) ...[
              const SizedBox(height: 4),
              _detail(Icons.restaurant_menu, 'Preparation: ${item.preparation}'),
            ],
            if (item.storage.isNotEmpty) ...[
              const SizedBox(height: 4),
              _detail(Icons.ac_unit_outlined, 'Storage: ${item.storage}'),
            ],
            if (item.allergens.isNotEmpty || (item.preparation.isEmpty && item.storage.isEmpty && item.notes.isNotEmpty)) ...[
              const SizedBox(height: 4),
              _detail(Icons.info_outline, 'Allergens / notes: ${item.allergens.isEmpty ? item.notes : item.allergens}'),
            ],
            if (acceptedHandoffs.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...acceptedHandoffs.map((request) => _acceptedHandoff(context, request)),
            ],
            if (role == Role.donor)
              Padding(
                padding: const EdgeInsets.only(top: 9),
                child: Text(
                  hasPending ? 'Tap to review an NGO request' : 'Tap to view request and handoff status',
                  style: const TextStyle(color: green, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            if (role == Role.ngo && store.ngos[store.currentNgo] != true)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text('NGO verification is required before requesting food.',
                    style: TextStyle(color: muted, fontSize: 12)),
              ),
            if (role == Role.ngo && store.ngos[store.currentNgo] == true && hasPending)
              Align(
                alignment: Alignment.centerRight,
                child: statusChip('Request sent · awaiting decision'),
              ),
            if (role == Role.ngo && store.ngos[store.currentNgo] == true && !hasPending)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _request(context),
                  child: const Text('Request food'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _acceptedHandoff(BuildContext context, PickupRequest request) {
    final handoffDate = MaterialLocalizations.of(context).formatMediumDate(request.pickupAt);
    final handoffTime = TimeOfDay.fromDateTime(request.pickupAt).format(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFEAF2E8), borderRadius: BorderRadius.circular(13)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Accepted by ${request.ngo}', style: const TextStyle(color: ink, fontWeight: FontWeight.w700, fontSize: 12)),
        const SizedBox(height: 4),
        Row(children: [const Icon(Icons.key_outlined, color: green, size: 17), const SizedBox(width: 6), Text('Handoff code: ${request.pickupCode}', style: const TextStyle(color: green, fontWeight: FontWeight.w800, fontSize: 16))]),
        const SizedBox(height: 3),
        Text('${item.donorDelivers ? 'Deliver to NGO' : 'NGO pickup'} · $handoffDate at $handoffTime', style: const TextStyle(color: ink, fontSize: 11)),
        Text(item.donorDelivers ? 'Destination: ${request.ngoLocation}' : 'Pickup: ${item.address}', style: const TextStyle(color: muted, fontSize: 11)),
      ]),
    );
  }

  Future<void> _showDonationStatus(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name,
                  style: const TextStyle(color: ink, fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('${item.qty} ${item.unit} still available',
                  style: const TextStyle(color: muted)),
              const SizedBox(height: 16),
              ...store.requests
                  .where((request) => request.donationId == item.id)
                  .map((request) => _pickupStatus(context, request)),
              if (store.requests.every((request) => request.donationId != item.id))
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text('No NGO has requested this donation yet.',
                      style: TextStyle(color: muted)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pickupStatus(BuildContext context, PickupRequest request) {
    final pickupTime = TimeOfDay.fromDateTime(request.pickupAt).format(context);
    final pickupDate = MaterialLocalizations.of(context).formatMediumDate(request.pickupAt);
    final status = switch (request.stage) {
      Stage.pending => 'Waiting for your approval',
      Stage.approved => item.donorDelivers ? 'Accepted · delivery planned' : 'Accepted · pickup confirmed',
      Stage.rejected => 'Request declined',
      Stage.cancelled => 'Request cancelled',
      Stage.missed => 'Missed handoff · ${request.missedReason ?? 'Handoff was not confirmed in time'}',
      Stage.collected => item.donorDelivers ? 'Received by ${request.ngo}' : 'Collected by ${request.ngo}',
      Stage.delivered => 'Delivered by ${request.ngo}',
    };
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8F4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$status · ${request.qty} ${item.unit}',
              style: const TextStyle(color: ink, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('${item.donorDelivers ? 'Expected delivery' : 'Expected pickup'}: $pickupDate at $pickupTime',
              style: const TextStyle(color: muted, fontSize: 12)),
          if (request.stage == Stage.approved && request.pickupCode != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Handoff code: ${request.pickupCode}', style: const TextStyle(color: green, fontWeight: FontWeight.w800)),
            ),
          if (item.donorDelivers && request.pickupCode != null)
            Text('Donor delivery to NGO: ${request.ngoLocation}', style: const TextStyle(color: muted, fontSize: 12)),
          if (item.donorDelivers && request.stage == Stage.pending && request.pickupCode == null)
            const Text('The NGO address will be shown after you accept the request.', style: TextStyle(color: muted, fontSize: 12)),
          if (!item.donorDelivers) ...[
            Text('Food pickup address: ${item.address}', style: const TextStyle(color: muted, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Future<void> _request(BuildContext context) async {
    final draft = await showDialog<RequestDraft>(
      context: context,
      builder: (_) => RequestDonationDialog(item: item),
    );
    if (draft == null || !context.mounted) return;

    final sent = store.request(item, store.currentNgo, draft.quantity, draft.pickupAt, draft.ngoLocation);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(sent ? 'Donation request sent to the donor.' : 'This request could not be sent. Check the quantity and handoff time.')),
    );
  }
}

class RequestDraft {
  const RequestDraft(this.quantity, this.pickupAt, this.ngoLocation);
  final int quantity;
  final DateTime pickupAt;
  final String ngoLocation;
}

class RequestDonationDialog extends StatefulWidget {
  const RequestDonationDialog({super.key, required this.item});
  final Donation item;

  @override
  State<RequestDonationDialog> createState() => _RequestDonationDialogState();
}

class _RequestDonationDialogState extends State<RequestDonationDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantity;
  final _ngoLocation = TextEditingController();
  DateTime? _pickupAt;

  @override
  void initState() {
    super.initState();
    _quantity = TextEditingController(text: '${widget.item.qty}');
  }

  @override
  void dispose() {
    _quantity.dispose();
    _ngoLocation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Request this donation'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Up to ${widget.item.qty} ${widget.item.unit} available.'),
              const SizedBox(height: 8),
              Text(widget.item.donorDelivers ? 'Delivery method: donor will deliver' : 'Delivery method: NGO pickup', style: const TextStyle(color: green, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              if (widget.item.donorDelivers)
                TextFormField(
                  controller: _ngoLocation,
                  decoration: const InputDecoration(
                    labelText: 'NGO receiving address',
                    hintText: 'Where should the donor deliver the food?',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter the NGO receiving address'
                      : null,
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantity,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Quantity (${widget.item.unit})'),
                validator: (value) {
                  final quantity = int.tryParse(value ?? '');
                  return quantity == null || quantity < 1 || quantity > widget.item.qty
                      ? 'Enter 1 to ${widget.item.qty}'
                      : null;
                },
              ),
              const SizedBox(height: 14),
              Text(widget.item.donorDelivers ? 'When should the donor deliver it?' : 'When will you pick it up?',
                  style: TextStyle(color: ink, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: _choosePickupTime,
                icon: const Icon(Icons.event_available),
                label: Text(_pickupAt == null
                    ? (widget.item.donorDelivers ? 'Choose delivery date and time' : 'Choose pickup date and time')
                    : '${MaterialLocalizations.of(context).formatMediumDate(_pickupAt!)} · ${TimeOfDay.fromDateTime(_pickupAt!).format(context)}'),
              ),
              if (_pickupAt == null)
                Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(widget.item.donorDelivers ? 'Select when the donor expects to arrive at your NGO.' : 'Select when your driver expects to arrive at the donor.',
                      style: const TextStyle(color: muted, fontSize: 11)),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: _submit, child: const Text('Send request')),
        ],
      );

  Future<void> _choosePickupTime() async {
    final now = DateTime.now();
    final deadline = widget.item.deadlineAt;
    final ready = widget.item.readyAt;
    final earliest = ready != null && ready.isAfter(now) ? ready : now;
    final lastDay = deadline == null ? now.add(const Duration(days: 180)) :
        DateTime(deadline.year, deadline.month, deadline.day);
    if (lastDay.isBefore(DateTime(now.year, now.month, now.day))) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This donation has passed its safe handoff deadline.')));
      return;
    }
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _pickupAt != null && _pickupAt!.isAfter(earliest) ? _pickupAt! : earliest,
      firstDate: DateTime(earliest.year, earliest.month, earliest.day),
      lastDate: lastDay,
    );
    if (selectedDate == null || !mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: _pickupAt != null && _pickupAt!.isAfter(now)
          ? TimeOfDay.fromDateTime(_pickupAt!)
          : TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );
    if (selectedTime == null || !mounted) return;

    setState(() {
      _pickupAt = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    });
    if ((ready != null && _pickupAt!.isBefore(ready)) || (deadline != null && _pickupAt!.isAfter(deadline))) {
      setState(() => _pickupAt = null);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose a handoff time after food is ready and before its safe deadline.')));
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_pickupAt == null || !_pickupAt!.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a future pickup date and time.')),
      );
      return;
    }
    Navigator.pop(
      context,
      RequestDraft(int.parse(_quantity.text), _pickupAt!, _ngoLocation.text.trim()),
    );
  }
}
IconData _foodIcon(String c) => switch (c) {'Produce' => Icons.eco_outlined, 'Meals' => Icons.restaurant_outlined, 'Bakery' => Icons.bakery_dining_outlined, _ => Icons.volunteer_activism_outlined};
Widget _detail(IconData i, String text) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(i, size: 15, color: muted), const SizedBox(width: 6), Expanded(child: Text(text, style: const TextStyle(color: muted, fontSize: 11)))]);
Widget statusChip(String s) => Container(margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: const Color(0xFFEAF2E8), borderRadius: BorderRadius.circular(20)), child: Text(s, style: const TextStyle(color: green, fontSize: 10, fontWeight: FontWeight.w700)));

class DonorRequests extends StatelessWidget {
  const DonorRequests({super.key});
  @override Widget build(BuildContext context) { final requests = store.donorRequests; return ListView(padding: const EdgeInsets.all(20), children: [const Text('Donation requests', style: TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 23)), const SizedBox(height: 6), const Text('Review requests and see pickup updates.', style: TextStyle(color: muted)), const SizedBox(height: 16), const ActivityFeed(role: Role.donor), const Text('Requests', style: TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 17)), const SizedBox(height: 8), if (requests.isEmpty) const Text('New requests for your listings will appear here.', style: TextStyle(color: muted)), ...requests.map((r) => RequestCard(request: r, donor: true))]); }
}
class NgoPickups extends StatelessWidget {
  const NgoPickups({super.key});
  @override Widget build(BuildContext context) { final mine = store.requests.where((r) => r.ngo == store.currentNgo); return ListView(padding: const EdgeInsets.all(20), children: [Text('My pickups · ${store.currentNgo}', style: const TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 23)), const SizedBox(height: 6), const Text('Requests and delivery progress for your organization.', style: TextStyle(color: muted)), const SizedBox(height: 16), const ActivityFeed(role: Role.ngo), const Text('Pickup history', style: TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 17)), const SizedBox(height: 8), if (mine.isEmpty) const Text('You have not requested a donation yet.', style: TextStyle(color: muted)), ...mine.map((r) => RequestCard(request: r, donor: false))]); }
}
class RequestCard extends StatelessWidget {
  const RequestCard({super.key, required this.request, required this.donor, this.admin = false}); final PickupRequest request; final bool donor, admin;
  @override
  Widget build(BuildContext context) {
    final donation = store.find(request.donationId);
    final label = switch (request.stage) {
      Stage.pending => 'Awaiting approval',
      Stage.approved => 'Approved',
      Stage.rejected => 'Declined',
      Stage.cancelled => 'Cancelled',
      Stage.missed => donation?.donorDelivers == true ? 'Missed delivery' : 'Missed pickup',
      Stage.collected => donation?.donorDelivers == true ? 'Received' : 'Collected',
      Stage.delivered => 'Delivered',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  donation?.name ?? 'Food donation',
                  style: const TextStyle(color: ink, fontWeight: FontWeight.w800),
                ),
              ),
              statusChip(label),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${request.ngo} requested ${request.qty} ${donation?.unit ?? 'items'}',
            style: const TextStyle(color: muted, fontSize: 13),
          ),
          Text(
            '${donation?.donorDelivers == true ? 'Planned delivery' : 'Planned pickup'}: ${_pickupLabel(context, request.pickupAt)}',
            style: const TextStyle(color: muted, fontSize: 12),
          ),
          if (donor && request.stage == Stage.approved && request.pickupCode != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Handoff code: ${request.pickupCode} · also shown on My food',
                  style: const TextStyle(color: green, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          if (donation != null && donation.donorDelivers && (!donor || request.pickupCode != null))
            Text('Deliver to NGO: ${request.ngoLocation}', style: const TextStyle(color: muted, fontSize: 12)),
          if (donor && donation?.donorDelivers == true && request.pickupCode == null && request.stage == Stage.pending)
            const Text('The NGO address will appear here after you accept the request.', style: TextStyle(color: muted, fontSize: 12)),
          if (donation != null && !donation.donorDelivers)
            Text('NGO pickup address: ${donation.address}', style: const TextStyle(color: muted, fontSize: 12)),
          if (request.cancelReason != null)
            Text('Cancellation reason: ${request.cancelReason}', style: const TextStyle(color: muted, fontSize: 12)),
          if (request.missedReason != null)
            Text('${donation?.donorDelivers == true ? 'Missed delivery' : 'Missed pickup'}: ${request.missedReason}', style: const TextStyle(color: muted, fontSize: 12)),
          if (donor && request.stage == Stage.pending) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => store.decide(request, false),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final enough = donation != null && request.qty <= donation.qty;
                      final pickupStillValid = request.pickupAt.isAfter(DateTime.now()) &&
                          (donation?.readyAt == null || !request.pickupAt.isBefore(donation!.readyAt!)) &&
                          (donation?.deadlineAt == null || !request.pickupAt.isAfter(donation!.deadlineAt!));
                      final remaining = enough ? donation!.qty - request.qty : 0;
                      final approved = store.decide(request, true);
                      final message = approved
                          ? (remaining > 0
                              ? 'Approved. $remaining ${donation!.unit} remain available. Handoff code: ${request.pickupCode}'
                              : 'Approved; all food is reserved. Handoff code: ${request.pickupCode}')
                          : !pickupStillValid ? 'The planned handoff is outside the safe collection window. Ask the NGO to choose a new time.' : !enough ? 'Not enough food remains for this request.' : 'This request could not be approved. Refresh and try again.';
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(message)),
                        );
                      });
                    },
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
          if (!donor && !admin && request.stage == Stage.approved)
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                onPressed: () => _confirmPickup(context),
                child: Text(donation?.donorDelivers == true ? 'Confirm delivery with code' : 'Enter pickup code'),
              ),
            ),
          if (!donor && !admin && request.stage == Stage.collected)
            Align(alignment: Alignment.centerRight, child: FilledButton.tonal(
              onPressed: () => store.advance(request),
              child: const Text('Confirm delivery'),
            )),
          if (!donor && !admin && (request.stage == Stage.pending || request.stage == Stage.approved))
            Align(alignment: Alignment.centerRight, child: TextButton.icon(
              onPressed: () => _cancelRequest(context),
              icon: const Icon(Icons.close), label: const Text('Cancel request'),
            )),
        ],
      ),
    );
  }

  Future<void> _confirmPickup(BuildContext context) async {
    final controller = TextEditingController();
    final code = await showDialog<String>(context: context, builder: (context) => AlertDialog(
      title: Text(store.find(request.donationId)?.donorDelivers == true ? 'Confirm donation receipt' : 'Confirm food pickup'),
      content: TextField(controller: controller, keyboardType: TextInputType.number, maxLength: 4,
        decoration: const InputDecoration(labelText: '4 digit handoff code from donor')),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Confirm'))],
    ));
    controller.dispose();
    if (code == null || !context.mounted) return;
    final confirmed = store.confirmCollection(request, code);
    final donorDelivers = store.find(request.donationId)?.donorDelivers == true;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(confirmed ? (donorDelivers ? 'Delivery received and completed.' : 'Pickup confirmed. The NGO can confirm distribution next.') : 'That handoff code is incorrect.')));
  }

  Future<void> _cancelRequest(BuildContext context) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(context: context, builder: (context) => AlertDialog(
      title: const Text('Cancel pickup request'),
      content: TextField(controller: controller, maxLines: 2, decoration: const InputDecoration(labelText: 'Reason for cancellation', hintText: 'Schedule change, transport issue…')),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Keep request')),
        FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Cancel pickup'))],
    ));
    controller.dispose();
    if (reason == null || !context.mounted) return;
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a cancellation reason.')));
      return;
    }
    final cancelled = store.cancel(request, reason, cancelledBy: Role.ngo);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(cancelled ? 'Pickup cancelled. Reserved food was returned when still safe.' : 'This pickup can no longer be cancelled.')));
  }
}

String _pickupLabel(BuildContext context, DateTime pickupAt) =>
    '${MaterialLocalizations.of(context).formatMediumDate(pickupAt)} at ${TimeOfDay.fromDateTime(pickupAt).format(context)}';

class CreateDonationPage extends StatefulWidget {
  const CreateDonationPage({super.key}); @override State<CreateDonationPage> createState() => _CreateDonationState();
}
class _CreateDonationState extends State<CreateDonationPage> {
  final key = GlobalKey<FormState>();
  final name = TextEditingController(), qty = TextEditingController(), unit = TextEditingController(text: 'meals'), address = TextEditingController();
  final photoUrl = TextEditingController(), latitude = TextEditingController(), longitude = TextEditingController(), kgPerUnit = TextEditingController();
  final preparation = TextEditingController(), storage = TextEditingController(), allergens = TextEditingController();
  String category = 'Meals', foodType = 'Vegetarian'; TimeOfDay? ready, deadline; bool donorDelivers = false;
  @override void dispose() { name.dispose(); qty.dispose(); unit.dispose(); address.dispose(); photoUrl.dispose(); latitude.dispose(); longitude.dispose(); kgPerUnit.dispose(); preparation.dispose(); storage.dispose(); allergens.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Share surplus food', style: TextStyle(fontWeight: FontWeight.w800))), body: Form(key: key, child: ListView(padding: const EdgeInsets.all(20), children: [
    const Text('Share surplus food and choose how it will reach the NGO.', style: TextStyle(color: muted, height: 1.4)), const SizedBox(height: 16),
    TextFormField(controller: photoUrl, keyboardType: TextInputType.url, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Food photo URL (optional)', hintText: 'https://example.com/food.jpg', prefixIcon: Icon(Icons.image_outlined)), validator: (v) { final value = (v ?? '').trim(); return value.isNotEmpty && !value.startsWith('https://') && !value.startsWith('http://') ? 'Use a valid http or https image URL' : null; }),
    if (photoUrl.text.startsWith('http')) ...[const SizedBox(height: 8), ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(photoUrl.text, height: 130, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(height: 40, child: Text('Image preview unavailable', style: TextStyle(color: muted, fontSize: 12)))))],
    const SizedBox(height: 12),
    _label('Food name'), TextFormField(controller: name, decoration: const InputDecoration(hintText: 'e.g. Fresh vegetable boxes'), validator: required), const SizedBox(height: 12),
    _label('Category'), DropdownButtonFormField(value: category, items: ['Produce', 'Meals', 'Bakery', 'Other'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => category = v ?? 'Other')), const SizedBox(height: 12),
    _label('Food type'), DropdownButtonFormField(value: foodType, items: ['Vegetarian', 'Non-vegetarian', 'Vegan', 'Other'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => foodType = v ?? 'Other')), const SizedBox(height: 12),
    _label('Quantity and unit'), Row(children: [Expanded(flex: 2, child: TextFormField(controller: qty, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '20'), validator: (v) { final n = int.tryParse(v ?? ''); return n == null || n < 1 ? 'Enter a valid quantity' : null; })), const SizedBox(width: 9), Expanded(child: TextFormField(controller: unit, decoration: const InputDecoration(hintText: 'meals'), validator: required))]), const SizedBox(height: 12),
    DropdownButtonFormField<bool>(
      value: donorDelivers,
      decoration: const InputDecoration(labelText: 'Delivery arrangement'),
      items: const [
        DropdownMenuItem<bool>(value: false, child: Text('NGO picks up from me')),
        DropdownMenuItem<bool>(value: true, child: Text('I deliver to the NGO')),
      ],
      onChanged: (value) => setState(() => donorDelivers = value ?? false),
    ),
    const SizedBox(height: 12),
    if (!donorDelivers) ...[
      _label('NGO pickup address'),
      TextFormField(controller: address, decoration: const InputDecoration(hintText: 'Street, area, city'), validator: required),
    ] else
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFEAF2E8), borderRadius: BorderRadius.circular(12)),
        child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline, color: green, size: 18),
          SizedBox(width: 8),
          Expanded(child: Text('After you accept an NGO request, its receiving address will appear in the request details.', style: TextStyle(color: ink, fontSize: 12))),
        ]),
      ),
    const SizedBox(height: 12),
    _label('Map location for distance'), Row(children: [Expanded(child: TextFormField(controller: latitude, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: const InputDecoration(labelText: 'Latitude', hintText: '12.9716'), validator: (v) => _coordinateError(v, -90, 90))), const SizedBox(width: 8), Expanded(child: TextFormField(controller: longitude, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: const InputDecoration(labelText: 'Longitude', hintText: '77.5946'), validator: (v) => _coordinateError(v, -180, 180)))]), const SizedBox(height: 4), const Text('Enter both coordinates to show approximate distance to NGOs.', style: TextStyle(color: muted, fontSize: 11)), const SizedBox(height: 12),
    _label('Approximate weight per unit (kg)'), TextFormField(controller: kgPerUnit, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(hintText: 'e.g. 0.5'), validator: (v) { final value = (v ?? '').trim(); if (value.isEmpty) return null; final n = double.tryParse(value); return n == null || n < 0 ? 'Enter a valid weight' : null; }), const SizedBox(height: 12),
    _label('Prepared / ready time'), _time('Set food ready time', ready, (v) => setState(() => ready = v)), const SizedBox(height: 8), _label('Safe handoff deadline'), _time('Set latest pickup or delivery time', deadline, (v) => setState(() => deadline = v)), const SizedBox(height: 12),
    _label('Preparation details'), TextFormField(controller: preparation, maxLines: 2, decoration: const InputDecoration(hintText: 'Cooked today, individually packed, ready to serve…')), const SizedBox(height: 10),
    _label('Storage instructions'), TextFormField(controller: storage, maxLines: 2, decoration: const InputDecoration(hintText: 'Keep refrigerated, store in a cool place…')), const SizedBox(height: 10),
    _label('Allergens'), TextFormField(controller: allergens, decoration: const InputDecoration(hintText: 'Milk, nuts, gluten, or “none known”')), const SizedBox(height: 10),
    const Text('Only list food that is safe to distribute. This app does not certify food safety.', style: TextStyle(color: muted, fontSize: 11)), const SizedBox(height: 20), FilledButton(onPressed: publish, style: FilledButton.styleFrom(backgroundColor: green, minimumSize: const Size.fromHeight(50)), child: const Text('Publish donation')),
  ])));
  String? required(String? v) => v == null || v.trim().isEmpty ? 'Complete this field' : null;
  String? _coordinateError(String? value, double min, double max) { final text = (value ?? '').trim(); if (text.isEmpty) return null; final n = double.tryParse(text); return n == null || n < min || n > max ? 'Enter a value from $min to $max' : null; }
  Widget _label(String s) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(s, style: const TextStyle(color: ink, fontWeight: FontWeight.w700, fontSize: 13)));
  Widget _time(String title, TimeOfDay? value, ValueChanged<TimeOfDay?> set) => ListTile(tileColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), title: Text(value == null ? title : '$title: ${value.format(context)}', style: const TextStyle(fontSize: 13)), trailing: const Icon(Icons.schedule, color: green), onTap: () async { final v = await showTimePicker(context: context, initialTime: value ?? TimeOfDay.now()); if (v != null) set(v); });
  void publish() {
    if (!key.currentState!.validate()) return;
    if (ready == null || deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Set both the ready time and safe collection deadline.')));
      return;
    }
    final now = DateTime.now();
    DateTime at(TimeOfDay value) => DateTime(now.year, now.month, now.day, value.hour, value.minute);
    var readyAt = at(ready!);
    var deadlineAt = at(deadline!);
    if (readyAt.isBefore(now)) readyAt = readyAt.add(const Duration(days: 1));
    if (deadlineAt.isBefore(readyAt)) deadlineAt = deadlineAt.add(const Duration(days: 1));
    if (!deadlineAt.isAfter(readyAt)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deadline must be after the ready time.')));
      return;
    }
    String time(TimeOfDay v) => v.format(context);
    if (latitude.text.trim().isEmpty != longitude.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter both map coordinates, or leave both empty.')));
      return;
    }
    final lat = latitude.text.trim().isEmpty ? null : double.parse(latitude.text.trim());
    final lon = longitude.text.trim().isEmpty ? null : double.parse(longitude.text.trim());
    final weight = double.tryParse(kgPerUnit.text.trim()) ?? 0;
    final details = [preparation.text.trim(), storage.text.trim(), allergens.text.trim()].where((v) => v.isNotEmpty).join(' · ');
    Navigator.pop(context, store.createDonation(name.text.trim(), int.parse(qty.text), unit.text.trim(), category, foodType, address.text.trim(), time(ready!), time(deadline!), details, readyAt, deadlineAt, photoUrl.text.trim(), lat, lon, weight, preparation.text.trim(), storage.text.trim(), allergens.text.trim(), donorDelivers));
  }
}

// Admin screens
class AdminOverview extends StatelessWidget {
  const AdminOverview({super.key});
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [const Text('Platform overview', style: TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 23)), const SizedBox(height: 5), const Text('Community activity at a glance.', style: TextStyle(color: muted)), const SizedBox(height: 18), Wrap(spacing: 10, runSpacing: 10, children: [_stat('Available listings', '${store.donations.where(store.isAvailable).length}', Icons.restaurant), _stat('Verified NGOs', '${store.ngos.values.where((v) => v).length}', Icons.verified_user), _stat('Completed donations', '${store.completedDonations}', Icons.volunteer_activism), _stat('Food rescued', '${store.rescuedKg.toStringAsFixed(1)} kg', Icons.scale_outlined)]), const SizedBox(height: 18), const ImpactPanel(), const SizedBox(height: 20), const Text('Recent listings', style: TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 17)), const SizedBox(height: 10), ...store.donations.take(4).map((d) => DonationCard(item: d, role: Role.admin))]);
  Widget _stat(String title, String value, IconData icon) => Container(width: 155, padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: green), const SizedBox(height: 12), Text(value, style: const TextStyle(color: ink, fontSize: 22, fontWeight: FontWeight.w800)), Text(title, style: const TextStyle(color: muted, fontSize: 11))]));
}
class VerificationPage extends StatelessWidget {
  const VerificationPage({super.key});
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [const Text('NGO verification', style: TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 23)), const SizedBox(height: 6), const Text('Review organizations before they collect food.', style: TextStyle(color: muted)), const SizedBox(height: 16), ...store.ngos.entries.map((e) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Icon(Icons.apartment, color: green), const SizedBox(width: 10), Expanded(child: Text(e.key, style: const TextStyle(color: ink, fontWeight: FontWeight.w800))), statusChip(e.value ? 'Verified' : 'Needs review')]), const SizedBox(height: 8), const Text('Registration and contact details · distribution area', style: TextStyle(color: muted, fontSize: 11)), Align(alignment: Alignment.centerRight, child: e.value ? TextButton(onPressed: () => store.verify(e.key, false), child: const Text('Revoke')) : FilledButton.tonal(onPressed: () => store.verify(e.key, true), child: const Text('Mark verified')))])))]);
}
class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [const Text('Impact & history', style: TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 23)), const SizedBox(height: 6), const Text('Meals, rescued food, and completed pickups.', style: TextStyle(color: muted)), const SizedBox(height: 16), const ImpactPanel(), const SizedBox(height: 20), const Text('Request history', style: TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 17)), const SizedBox(height: 8), if (store.requests.isEmpty) const Text('No activity in this demo yet.', style: TextStyle(color: muted)), ...store.requests.map((r) => RequestCard(request: r, donor: false, admin: true))]);
}
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.isNgo});
  final bool isNgo;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, _) {
      final name = isNgo ? store.currentNgo : store.currentDonor;
      final verified = isNgo && store.ngos[name] == true;
      return ListView(padding: const EdgeInsets.all(20), children: [
        const Text('Profile', style: TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 23)),
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)), child: Row(children: [
          const CircleAvatar(backgroundColor: Color(0xFFEAF2E8), child: Icon(Icons.person, color: green)), const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(color: ink, fontWeight: FontWeight.w800)), Text(isNgo ? 'Community organization' : 'Food donor', style: const TextStyle(color: muted, fontSize: 12))])),
          if (isNgo) Icon(verified ? Icons.verified : Icons.info_outline, color: verified ? green : muted),
        ])),
        if (isNgo) ...[
          const SizedBox(height: 18),
          const Text('Demo organization', style: TextStyle(color: ink, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(value: store.currentNgo, decoration: const InputDecoration(labelText: 'Choose organization'),
            items: store.ngos.keys.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
            onChanged: (n) { if (n != null) store.selectNgo(n); }),
          const SizedBox(height: 8),
          Text('Service location: ${store.ngoLatitude.toStringAsFixed(4)}, ${store.ngoLongitude.toStringAsFixed(4)}', style: const TextStyle(color: muted, fontSize: 12)),
          Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () => _editNgoLocation(context), icon: const Icon(Icons.place_outlined), label: const Text('Set service coordinates'))),
          const SizedBox(height: 8),
          Text(verified ? 'Verified for this demo.' : 'This organization must be verified before requesting food.', style: const TextStyle(color: muted, fontSize: 12)),
        ],
        if (!isNgo) ...[
          const SizedBox(height: 18),
          const Text('Demo donor profile', style: TextStyle(color: ink, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: store.currentDonor,
            decoration: const InputDecoration(labelText: 'Choose donor'),
            items: Store.demoDonors.map((donor) => DropdownMenuItem(value: donor, child: Text(donor))).toList(),
            onChanged: (donor) { if (donor != null) store.selectDonor(donor); },
          ),
          const SizedBox(height: 6),
          const Text('Demo profiles keep sample donations and requests separate on this device.', style: TextStyle(color: muted, fontSize: 12)),
        ],
        const SizedBox(height: 16),
        const ListTile(leading: Icon(Icons.health_and_safety_outlined, color: green), title: Text('Food handling guidance'), subtitle: Text('Keep food sealed and follow safe storage instructions.')),
        const SizedBox(height: 12),
        const Text('Demo profile and activity reset when the app restarts.', textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 11)),
      ]);
    },
  );

  Future<void> _editNgoLocation(BuildContext context) async {
    final lat = TextEditingController(text: store.ngoLatitude.toString());
    final lon = TextEditingController(text: store.ngoLongitude.toString());
    final result = await showDialog<List<double>>(context: context, builder: (context) => AlertDialog(
      title: const Text('Set NGO service location'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Use map coordinates to estimate distance. This demo does not read GPS.', style: TextStyle(color: muted, fontSize: 12)),
        const SizedBox(height: 10),
        TextField(controller: lat, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: const InputDecoration(labelText: 'Latitude')),
        const SizedBox(height: 8),
        TextField(controller: lon, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: const InputDecoration(labelText: 'Longitude')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () { final a = double.tryParse(lat.text.trim()), b = double.tryParse(lon.text.trim()); if (a != null && b != null && a >= -90 && a <= 90 && b >= -180 && b <= 180) Navigator.pop(context, [a, b]); }, child: const Text('Save'))],
    ));
    lat.dispose(); lon.dispose();
    if (result != null) store.setNgoLocation(result[0], result[1]);
  }
}
