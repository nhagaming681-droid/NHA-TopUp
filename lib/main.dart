import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const NhaTopUpApp());
}

class NhaTopUpApp extends StatelessWidget {
  const NhaTopUpApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'NHA TopUp',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
        home: const HomePage(),
      );
}

class CustomerId {
  static Future<String> get() async {
    final p = await SharedPreferences.getInstance();
    var id = p.getString('customer_id');
    if (id == null) {
      id = 'c_${DateTime.now().millisecondsSinceEpoch}';
      await p.setString('customer_id', id);
    }
    return id;
  }
}

class OrderService {
  static final orders = FirebaseFirestore.instance.collection('orders');

  static Future<String> create({
    required String game,
    required String playerId,
    required String zoneId,
    required String amount,
    required String price,
    required String paymentMethod,
    required String transactionId,
    required String note,
  }) async {
    final customerId = await CustomerId.get();
    final ref = orders.doc();
    await ref.set({
      'orderId': ref.id,
      'customerId': customerId,
      'game': game,
      'playerId': playerId,
      'zoneId': zoneId,
      'amount': amount,
      'price': price,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'note': note,
      'status': 'Pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> myOrders() async* {
    final id = await CustomerId.get();
    yield* orders.where('customerId', isEqualTo: id).snapshots();
  }
}


class AdminService {
  static final auth = FirebaseAuth.instance;
  static final admins = FirebaseFirestore.instance.collection('admins');

  static Future<bool> isAdmin(User user) async {
    final doc = await admins.doc(user.uid).get();
    return doc.exists && (doc.data()?['enabled'] ?? true) == true;
  }

  static Future<void> updateStatus(String orderId, String status) async {
    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});
  @override State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;

  @override
  void dispose() { email.dispose(); password.dispose(); super.dispose(); }

  Future<void> login() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) return;
    setState(() => loading = true);
    try {
      final cred = await AdminService.auth.signInWithEmailAndPassword(
        email: email.text.trim(), password: password.text,
      );
      final user = cred.user!;
      if (!await AdminService.isAdmin(user)) {
        await AdminService.auth.signOut();
        throw Exception('ဒီ Account ကို Admin အဖြစ်ခွင့်မပြုထားပါ');
      }
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminPanelPage()));
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Login မအောင်မြင်ပါ')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('NHA TopUp Admin')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const Icon(Icons.admin_panel_settings, size: 80),
      const SizedBox(height: 12),
      const Text('Admin Login', textAlign: TextAlign.center, style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
      const SizedBox(height: 24),
      TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Admin Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email))),
      const SizedBox(height: 12),
      TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock))),
      const SizedBox(height: 18),
      FilledButton.icon(onPressed: loading ? null : login, icon: const Icon(Icons.login), label: Padding(padding: const EdgeInsets.all(12), child: Text(loading ? 'ဝင်နေသည်...' : 'Login'))),
    ]),
  );
}

class AdminPanelPage extends StatelessWidget {
  const AdminPanelPage({super.key});

  Future<void> changeStatus(BuildContext context, String id, String status) async {
    try {
      await AdminService.updateStatus(id, status);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status → $status')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status ပြောင်းမရပါ: $e')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Admin Orders'),
      actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () async { await AdminService.auth.signOut(); if (context.mounted) Navigator.pop(context); })],
    ),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('Orders မဖတ်နိုင်ပါ:\n${snapshot.error}', textAlign: TextAlign.center)));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('Order မရှိသေးပါ'));
        return ListView.builder(
          padding: const EdgeInsets.all(12), itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i].data();
            final status = (d['status'] ?? 'Pending').toString();
            return Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${d['game'] ?? ''} • ${d['amount'] ?? ''}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text('Order: ${d['orderId'] ?? docs[i].id}'),
              Text('ID: ${d['playerId'] ?? ''}${(d['zoneId'] ?? '').toString().isNotEmpty ? ' / ${d['zoneId']}' : ''}'),
              Text('${d['paymentMethod'] ?? ''} • ${d['price'] ?? ''}'),
              Text('Transaction: ${d['transactionId'] ?? ''}'),
              if ((d['note'] ?? '').toString().isNotEmpty) Text('Note: ${d['note']}'),
              const SizedBox(height: 10),
              Row(children: [const Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold)), DropdownButton<String>(value: ['Pending','Confirmed','Completed','Cancelled'].contains(status) ? status : 'Pending', items: const ['Pending','Confirmed','Completed','Cancelled'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) { if (v != null) changeStatus(context, docs[i].id, v); })]),
            ])));
          },
        );
      },
    ),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    const pages = [StorePage(), OrdersPage(), AccountPage()];
    return Scaffold(
      appBar: AppBar(title: const Text('NHA TopUp'), centerTitle: true),
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.storefront_outlined), label: 'Store'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Account'),
        ],
      ),
    );
  }
}

class StorePage extends StatelessWidget {
  const StorePage({super.key});
  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(child: const Padding(padding: EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('NHA TopUp', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)), SizedBox(height: 6), Text('Fast & easy game top-up')] ))),
          const SizedBox(height: 16),
          const Text('Games', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListTile(cardColor: Theme.of(context).colorScheme.surfaceContainerHighest, leading: const Icon(Icons.diamond), title: const Text('Mobile Legends'), subtitle: const Text('Diamond Top Up'), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductPage(game: 'MLBB', unit: 'Diamond')))),
          const SizedBox(height: 8),
          ListTile(cardColor: Theme.of(context).colorScheme.surfaceContainerHighest, leading: const Icon(Icons.sports_esports), title: const Text('PUBG MOBILE'), subtitle: const Text('UC Top Up'), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductPage(game: 'PUBG', unit: 'UC')))),
        ],
      );
}

class ProductPage extends StatefulWidget {
  final String game, unit;
  const ProductPage({super.key, required this.game, required this.unit});
  @override State<ProductPage> createState() => _ProductPageState();
}
class _ProductPageState extends State<ProductPage> {
  final id = TextEditingController();
  final zone = TextEditingController();
  int selected = 0;
  late final packages = widget.game == 'MLBB'
      ? const [
          {'amount': '86 Diamond', 'price': '2,500 Ks'},
          {'amount': '172 Diamond', 'price': '4,800 Ks'},
          {'amount': '257 Diamond', 'price': '7,000 Ks'},
          {'amount': '344 Diamond', 'price': '9,200 Ks'},
        ]
      : const [
          {'amount': '60 UC', 'price': '3,000 Ks'},
          {'amount': '325 UC', 'price': '14,000 Ks'},
          {'amount': '660 UC', 'price': '27,000 Ks'},
          {'amount': '1800 UC', 'price': '70,000 Ks'},
        ];
  @override void dispose() { id.dispose(); zone.dispose(); super.dispose(); }
  void next() {
    if (id.text.trim().isEmpty || (widget.game == 'MLBB' && zone.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.game == 'MLBB' ? 'Game ID နဲ့ Zone ID ထည့်ပါ' : 'Game ID ထည့်ပါ')));
      return;
    }
    final p = packages[selected];
    Navigator.push(context, MaterialPageRoute(builder: (_) => OrderPage(game: widget.game, playerId: id.text.trim(), zoneId: zone.text.trim(), amount: p['amount']!, price: p['price']!)));
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('${widget.game} ${widget.unit}')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      TextField(controller: id, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Game ID / Player ID', border: OutlineInputBorder())),
      if (widget.game == 'MLBB') ...[const SizedBox(height: 12), TextField(controller: zone, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Zone ID', border: OutlineInputBorder()))],
      const SizedBox(height: 18), const Text('Package ရွေးပါ', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
      ...List.generate(packages.length, (i) => RadioListTile<int>(value: i, groupValue: selected, onChanged: (v) => setState(() => selected = v ?? 0), title: Text(packages[i]['amount']!, style: const TextStyle(fontWeight: FontWeight.bold)), secondary: Text(packages[i]['price']!))),
      FilledButton(onPressed: next, child: const Padding(padding: EdgeInsets.all(12), child: Text('ဝယ်မည်'))),
    ]),
  );
}

class OrderPage extends StatelessWidget {
  final String game, playerId, zoneId, amount, price;
  const OrderPage({super.key, required this.game, required this.playerId, required this.zoneId, required this.amount, required this.price});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Order Summary')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Game: $game'), Text('ID: $playerId'), if (zoneId.isNotEmpty) Text('Zone ID: $zoneId'), const Divider(), Text(amount, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), Text('Price: $price', style: const TextStyle(fontSize: 18))]))),
      const SizedBox(height: 12),
      _pay(context, 'KPay', Icons.account_balance_wallet),
      _pay(context, 'WavePay', Icons.phone_android),
    ]),
  );
  Widget _pay(BuildContext context, String method, IconData icon) => Card(child: ListTile(leading: Icon(icon), title: Text(method), subtitle: const Text('ငွေလွှဲပြီး Order တင်မည်'), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentPage(game: game, playerId: playerId, zoneId: zoneId, amount: amount, price: price, method: method)))));
}

class PaymentPage extends StatefulWidget {
  final String game, playerId, zoneId, amount, price, method;
  const PaymentPage({super.key, required this.game, required this.playerId, required this.zoneId, required this.amount, required this.price, required this.method});
  @override State<PaymentPage> createState() => _PaymentPageState();
}
class _PaymentPageState extends State<PaymentPage> {
  final tx = TextEditingController();
  final note = TextEditingController();
  static const receiver = '09449269794';
  @override void dispose() { tx.dispose(); note.dispose(); super.dispose(); }
  Future<void> submit() async {
    if (tx.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction ID / Reference ထည့်ပါ'))); return; }
    try {
      final orderId = await OrderService.create(game: widget.game, playerId: widget.playerId, zoneId: widget.zoneId, amount: widget.amount, price: widget.price, paymentMethod: widget.method, transactionId: tx.text.trim(), note: note.text.trim());
      if (!mounted) return;
      await showDialog(context: context, builder: (_) => AlertDialog(title: const Text('အော်ဒါတင်ပြီးပါပြီ'), content: Text('Order ID: $orderId\nStatus: Pending'), actions: [TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text('OK'))]));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order မတင်နိုင်ပါ: $e'))); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('${widget.method} Payment')), body: ListView(padding: const EdgeInsets.all(16), children: [
    Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.method, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 10), const Text('ငွေလက်ခံမည့်နံပါတ်'), SelectableText(receiver, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), const Divider(), Text('Amount: ${widget.amount}'), Text('Total: ${widget.price}')]))),
    const SizedBox(height: 14), TextField(controller: tx, decoration: const InputDecoration(labelText: 'Transaction ID / Reference', border: OutlineInputBorder())),
    const SizedBox(height: 12), TextField(controller: note, maxLines: 3, decoration: const InputDecoration(labelText: 'မှတ်ချက် (ရွေးချယ်နိုင်)', border: OutlineInputBorder())),
    const SizedBox(height: 18), FilledButton.icon(onPressed: submit, icon: const Icon(Icons.cloud_upload), label: const Padding(padding: EdgeInsets.all(12), child: Text('အော်ဒါတင်မည်'))),
  ]));
}

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});
  String label(String s) => {'Pending':'စစ်ဆေးနေဆဲ','Confirmed':'အတည်ပြုပြီး','Completed':'TopUp ပြီး','Cancelled':'ပယ်ဖျက်ပြီး'}[s] ?? s;
  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream: OrderService.myOrders(), builder: (context, snap) {
    if (snap.hasError) return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('Firestore မဖတ်နိုင်ပါ:\n${snap.error}', textAlign: TextAlign.center)));
    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
    final docs = [...snap.data!.docs]..sort((a,b) { final at=a.data()['createdAt']; final bt=b.data()['createdAt']; if (at is Timestamp && bt is Timestamp) return bt.compareTo(at); return 0; });
    if (docs.isEmpty) return const Center(child: Text('Order မရှိသေးပါ'));
    return ListView.builder(padding: const EdgeInsets.all(12), itemCount: docs.length, itemBuilder: (_, i) { final d=docs[i].data(); final s=(d['status']??'Pending').toString(); return Card(child: ListTile(leading: CircleAvatar(child: Icon(s=='Completed'?Icons.check:Icons.receipt_long)), title: Text('${d['game']} • ${d['amount']}'), subtitle: Text('ID: ${d['playerId']}\n${d['paymentMethod']} • ${d['price']}\n${label(s)}')); }); });
  });
}
class AccountPage extends StatelessWidget { const AccountPage({super.key}); @override Widget build(BuildContext context) => const Center(child: Text('NHA TopUp Account')); }
