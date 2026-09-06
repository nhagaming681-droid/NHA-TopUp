import 'package:flutter/material.dart';

void main() => runApp(const NhaTopUpApp());

class NhaTopUpApp extends StatelessWidget {
  const NhaTopUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NHA TopUp',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xfff6f7fb),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const StorePage(),
      const OrdersPage(),
      const AccountPage(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('NHA TopUp', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: pages[tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Store'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }
}

class StorePage extends StatelessWidget {
  const StorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(colors: [Color(0xff3949ab), Color(0xff5c6bc0)]),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('NHA TopUp', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
              SizedBox(height: 6),
              Text('Fast & easy game top-up', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text('Games', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        GameCard(
          title: 'Mobile Legends',
          subtitle: 'Diamond Top Up',
          icon: Icons.diamond,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductPage(game: 'MLBB', unit: 'Diamond'))),
        ),
        GameCard(
          title: 'PUBG MOBILE',
          subtitle: 'UC Top Up',
          icon: Icons.sports_esports,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductPage(game: 'PUBG', unit: 'UC'))),
        ),
      ],
    );
  }
}

class GameCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final VoidCallback onTap;
  const GameCard({super.key, required this.title, required this.subtitle, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      contentPadding: const EdgeInsets.all(14),
      leading: CircleAvatar(radius: 28, child: Icon(icon, size: 28)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}

class ProductPage extends StatefulWidget {
  final String game, unit;
  const ProductPage({super.key, required this.game, required this.unit});
  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final idController = TextEditingController();
  final zoneController = TextEditingController();
  int selected = 0;

  late final List<Map<String, String>> packages = widget.game == 'MLBB'
      ? [
          {'amount': '86 Diamond', 'price': '2,500 Ks'},
          {'amount': '172 Diamond', 'price': '4,800 Ks'},
          {'amount': '257 Diamond', 'price': '7,000 Ks'},
          {'amount': '344 Diamond', 'price': '9,200 Ks'},
        ]
      : [
          {'amount': '60 UC', 'price': '3,000 Ks'},
          {'amount': '325 UC', 'price': '14,000 Ks'},
          {'amount': '660 UC', 'price': '27,000 Ks'},
          {'amount': '1800 UC', 'price': '70,000 Ks'},
        ];

  @override
  void dispose() {
    idController.dispose();
    zoneController.dispose();
    super.dispose();
  }

  void order() {
    if (idController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Game ID ထည့်ပါ')));
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => OrderPage(
      game: widget.game,
      playerId: idController.text.trim(),
      zoneId: zoneController.text.trim(),
      amount: packages[selected]['amount']!,
      price: packages[selected]['price']!,
    )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.game} ${widget.unit}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: idController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Game ID / Player ID', border: OutlineInputBorder())),
          if (widget.game == 'MLBB') ...[
            const SizedBox(height: 12),
            TextField(controller: zoneController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Zone ID', border: OutlineInputBorder())),
          ],
          const SizedBox(height: 18),
          const Text('Package ရွေးပါ', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...List.generate(packages.length, (i) => Card(
            child: RadioListTile<int>(
              value: i,
              groupValue: selected,
              onChanged: (v) => setState(() => selected = v!),
              title: Text(packages[i]['amount']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              secondary: Text(packages[i]['price']!),
            ),
          )),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: order, icon: const Icon(Icons.shopping_cart), label: const Padding(padding: EdgeInsets.all(12), child: Text('ဝယ်မည်'))),
        ],
      ),
    );
  }
}

class OrderPage extends StatelessWidget {
  final String game, playerId, zoneId, amount, price;
  const OrderPage({super.key, required this.game, required this.playerId, required this.zoneId, required this.amount, required this.price});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Summary')),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Game: $game'),
            Text('ID: $playerId'),
            if (zoneId.isNotEmpty) Text('Zone ID: $zoneId'),
            const Divider(),
            Text(amount, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('Price: $price', style: const TextStyle(fontSize: 18)),
          ]))),
          const SizedBox(height: 14),
          const Text('ငွေပေးချေမှုနည်းလမ်း', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          PaymentOption(
            title: 'KPay',
            subtitle: 'KPay နံပါတ်ကို နောက်မှထည့်နိုင်သည်',
            icon: Icons.account_balance_wallet,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentPage(
              game: game, playerId: playerId, zoneId: zoneId, amount: amount, price: price, method: 'KPay',
            ))),
          ),
          PaymentOption(
            title: 'WavePay',
            subtitle: 'WavePay နံပါတ်ကို နောက်မှထည့်နိုင်သည်',
            icon: Icons.phone_android,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentPage(
              game: game, playerId: playerId, zoneId: zoneId, amount: amount, price: price, method: 'WavePay',
            ))),
          ),
          const Spacer(),
          const Text('⚠️ Demo: Payment account နံပါတ်နှင့် top-up API မချိတ်ရသေးပါ။', textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}


class PaymentOption extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final VoidCallback onTap;
  const PaymentOption({super.key, required this.title, required this.subtitle, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: CircleAvatar(child: Icon(icon)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}

class PaymentPage extends StatefulWidget {
  final String game, playerId, zoneId, amount, price, method;
  const PaymentPage({super.key, required this.game, required this.playerId, required this.zoneId, required this.amount, required this.price, required this.method});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final noteController = TextEditingController();

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.method} Payment')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.method, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text('ငွေလက်ခံမည့်နံပါတ်'),
                const SizedBox(height: 6),
                const Text('နောက်မှ ထည့်မည်', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text('Amount: ${widget.amount}'),
                Text('Total: ${widget.price}'),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          const Text('Payment ပြီးပါက မှတ်ချက်ထည့်နိုင်သည်'),
          const SizedBox(height: 8),
          TextField(
            controller: noteController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'ဥပမာ - ငွေလွှဲပြီးပါပြီ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Demo order — Payment verification/API မချိတ်ရသေးပါ')),
            ),
            icon: const Icon(Icons.receipt_long),
            label: const Padding(padding: EdgeInsets.all(12), child: Text('အော်ဒါတင်မည်')),
          ),
        ],
      ),
    );
  }
}

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.receipt_long, size: 64),
      SizedBox(height: 10),
      Text('Order History'),
      SizedBox(height: 5),
      Text('အခု Demo version မှာ order history မသိမ်းရသေးပါ။'),
    ]),
  );
}

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      CircleAvatar(radius: 34, child: Icon(Icons.person, size: 38)),
      SizedBox(height: 12),
      Text('NHA TopUp Account', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
      SizedBox(height: 6),
      Text('Admin / Login system ကို နောက်အဆင့်မှာ ထည့်နိုင်ပါတယ်။'),
    ]),
  );
}
