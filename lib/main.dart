import 'dart:json' as dart_json; // fallback for web-less editors
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const HandArtApp());

class HandArtApp extends StatelessWidget {
  const HandArtApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'HandArt Market',
    theme: ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF10B981), brightness: Brightness.dark),
      useMaterial3: true,
    ),
    home: const MarketHome(),
  );
}

class Item {
  final String id, name, price, category, imageUrl, phone, whatsapp, telegram;
  Item({required this.id, required this.name, required this.price, required this.category,
        required this.imageUrl, required this.phone, required this.whatsapp, required this.telegram});

  Map<String, dynamic> toJson() => {
    'id': id,'name': name,'price': price,'category': category,'imageUrl': imageUrl,
    'phone': phone,'whatsapp': whatsapp,'telegram': telegram
  };
  factory Item.fromJson(Map<String, dynamic> m) => Item(
    id: m['id'], name: m['name'], price: m['price'], category: m['category'],
    imageUrl: m['imageUrl'], phone: m['phone'], whatsapp: m['whatsapp'], telegram: m['telegram']);
}

final seedItems = <Item>[
  Item(
    id: '1', name: 'Beaded Necklace', price: '300 ETB', category: 'Jewelry',
    imageUrl: 'https://picsum.photos/seed/bead/600/400',
    phone: '+251900000001',
    whatsapp: 'https://wa.me/251900000001?text=Selam%20I%20saw%20your%20necklace%20on%20HandArt',
    telegram: 'https://t.me/your_artist1',
  ),
  Item(
    id: '2', name: 'Wood Carving Mask', price: '1200 ETB', category: 'Wood',
    imageUrl: 'https://picsum.photos/seed/wood/600/400',
    phone: '+251900000002',
    whatsapp: 'https://wa.me/251900000002?text=Selam%20I%20saw%20your%20wood%20art%20on%20HandArt',
    telegram: 'https://t.me/your_artist2',
  ),
  Item(
    id: '3', name: 'Shamma Scarf', price: '700 ETB', category: 'Textile',
    imageUrl: 'https://picsum.photos/seed/textile/600/400',
    phone: '+251900000003',
    whatsapp: 'https://wa.me/251900000003?text=Selam%20I%20saw%20your%20scarf%20on%20HandArt',
    telegram: 'https://t.me/your_artist3',
  ),
];

class MarketHome extends StatefulWidget {
  const MarketHome({super.key});
  @override State<MarketHome> createState() => _MarketHomeState();
}

class _MarketHomeState extends State<MarketHome> {
  List<Item> items = List.of(seedItems);
  Set<String> favs = {};
  String q = '';
  String category = 'All';
  final cats = const ['All', 'Jewelry', 'Wood', 'Textile'];

  @override void initState() { super.initState(); _loadFavs(); }

  Future<void> _loadFavs() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString('favs') ?? '[]';
    final List list = jsonDecode(raw);
    setState(() => favs = list.map((e) => e.toString()).toSet());
  }

  Future<void> _toggleFav(String id) async {
    final sp = await SharedPreferences.getInstance();
    setState(() => favs.contains(id) ? favs.remove(id) : favs.add(id));
    await sp.setString('favs', jsonEncode(favs.toList()));
  }

  Iterable<Item> get filtered => items.where((i) {
    final passCat = category == 'All' || i.category == category;
    final passQ = q.isEmpty || i.name.toLowerCase().contains(q.toLowerCase());
    return passCat && passQ;
  });

  Future<void> _open(String url) async {
    final uri = Uri.parse(url.startsWith('http') ? url : 'tel:$url');
    if (await canLaunchUrl(uri)) { await launchUrl(uri, mode: LaunchMode.externalApplication); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎨 HandArt Market'),
        actions: [
          IconButton(
            tooltip: 'Favorites',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => _FavsDialog(all: items, favs: favs, open: _open, toggle: _toggleFav),
            ),
            icon: const Icon(Icons.favorite),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search items…',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => q = v),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: category,
                  items: cats.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => category = v ?? 'All'),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, childAspectRatio: 0.72, crossAxisSpacing: 10, mainAxisSpacing: 10,
              ),
              itemCount: filtered.length,
              itemBuilder: (ctx, idx) {
                final i = filtered.elementAt(idx);
                final isFav = favs.contains(i.id);
                return Card(
                  clipBehavior: Clip.antiAlias, elevation: isFav ? 8 : 2,
                  child: InkWell(
                    onTap: () {},
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AspectRatio(aspectRatio: 3/2, child: Image.network(i.imageUrl, fit: BoxFit.cover)),
                        Padding(padding: const EdgeInsets.all(8.0),
                          child: Text(i.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))),
                        Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(i.price, style: const TextStyle(color: Colors.greenAccent))),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Wrap(spacing: 6, children: [
                            ElevatedButton.icon(onPressed: () => _open(i.whatsapp), icon: const Icon(Icons.chat), label: const Text('WhatsApp')),
                            ElevatedButton.icon(onPressed: () => _open(i.telegram), icon: const Icon(Icons.send), label: const Text('Telegram')),
                            ElevatedButton.icon(onPressed: () => _open(i.phone), icon: const Icon(Icons.call), label: const Text('Call')),
                            IconButton(tooltip: 'Save', onPressed: () => _toggleFav(i.id),
                              icon: Icon(isFav ? Icons.favorite : Icons.favorite_border)),
                          ]),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: TextButton.icon(
              onPressed: () => launchUrl(Uri.parse('https://t.me/<YOUR_TELEGRAM>'), mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.store),
              label: const Text('Add My Shop (message me)'),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Post Item (Coming Soon)'),
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const AlertDialog(
            title: Text('Coming Soon'),
            content: Text('Artist self-posting form will be added with admin approval.'),
          ),
        ),
      ),
    );
  }
}

class _FavsDialog extends StatelessWidget {
  final List<Item> all; final Set<String> favs;
  final Future<void> Function(String url) open;
  final Future<void> Function(String id) toggle;
  const _FavsDialog({required this.all, required this.favs, required this.open, required this.toggle});

  @override
  Widget build(BuildContext context) {
    final favItems = all.where((i) => favs.contains(i.id)).toList();
    return AlertDialog(
      title: const Text('❤️ Favorites'),
      content: SizedBox(
        width: 400,
        child: favItems.isEmpty
            ? const Text('No favorites yet.')
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: favItems.map((i) => ListTile(
                  title: Text(i.name), subtitle: Text(i.price),
                  trailing: Wrap(spacing: 8, children: [
                    IconButton(icon: const Icon(Icons.chat), onPressed: () => open(i.whatsapp)),
                    IconButton(icon: const Icon(Icons.send), onPressed: () => open(i.telegram)),
                    IconButton(icon: const Icon(Icons.call), onPressed: () => open(i.phone)),
                    IconButton(icon: const Icon(Icons.delete), onPressed: () => toggle(i.id)),
                  ]),
                )).toList(),
              ),
      ),
      actions: [ TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')) ],
    );
  }
}
