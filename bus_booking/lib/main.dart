import 'package:flutter/material.dart';

void main() => runApp(const BusApp());

class BusApp extends StatelessWidget {
  const BusApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Bus Booking',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.red, useMaterial3: true),
        home: const HomeScreen(),
      );
}

// ---------------- Models & data ----------------
const cities = [
  'Hyderabad',
  'Bengaluru',
  'Chennai',
  'Mumbai',
  'Pune',
  'Vijayawada',
  'Visakhapatnam',
  'Goa',
];

class Bus {
  final String id, operator, type, from, to, departs, arrives, duration;
  final int price;
  final double rating;
  final Set<int> baseBooked;
  Bus({
    required this.id,
    required this.operator,
    required this.type,
    required this.from,
    required this.to,
    required this.departs,
    required this.arrives,
    required this.duration,
    required this.price,
    required this.rating,
    required this.baseBooked,
  });
}

class Booking {
  final String id, name, phone;
  final Bus bus;
  final DateTime date;
  final List<int> seats;
  Booking({
    required this.id,
    required this.name,
    required this.phone,
    required this.bus,
    required this.date,
    required this.seats,
  });
  int get total => seats.length * bus.price;
}

final List<Booking> myBookings = [];

String fmtDate(DateTime d) {
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${d.day} ${m[d.month - 1]} ${d.year}';
}

int _seed(String s) => s.codeUnits.fold(0, (a, b) => a + b);

List<Bus> generateBuses(String from, String to, DateTime date) {
  final templates = [
    ['Orange Travels', 'AC Sleeper (2+1)', '21:30', '05:45', '8h 15m', 1250, 4.3],
    ['VRL Travels', 'Volvo AC Semi-Sleeper', '22:15', '06:30', '8h 15m', 980, 4.1],
    ['SRS Travels', 'Non-AC Seater', '19:00', '03:30', '8h 30m', 650, 3.8],
    ['KPN Travels', 'AC Sleeper', '23:00', '07:15', '8h 15m', 1100, 4.5],
    ['Kaveri Travels', 'Multi-Axle Volvo AC', '20:45', '05:00', '8h 15m', 1400, 4.6],
  ];
  final base = _seed(from + to) + date.day;
  return List.generate(templates.length, (i) {
    final t = templates[i];
    final taken = <int>{};
    for (var k = 0; k < 8 + (base + i) % 10; k++) {
      taken.add(1 + ((base * (k + 3) + i * 7 + k * 11) % 40));
    }
    return Bus(
      id: '$from-$to-$i',
      operator: t[0] as String,
      type: t[1] as String,
      from: from,
      to: to,
      departs: t[2] as String,
      arrives: t[3] as String,
      duration: t[4] as String,
      price: (t[5] as int) + (base % 5) * 20,
      rating: t[6] as double,
      baseBooked: taken,
    );
  });
}

Set<int> takenSeats(Bus bus, DateTime date) {
  final s = {...bus.baseBooked};
  for (final b in myBookings) {
    if (b.bus.id == bus.id &&
        b.date.year == date.year &&
        b.date.month == date.month &&
        b.date.day == date.day) {
      s.addAll(b.seats);
    }
  }
  return s;
}

// ---------------- Home ----------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _from = 'Hyderabad';
  String _to = 'Bengaluru';
  DateTime _date = DateTime.now().add(const Duration(days: 1));

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 90)),
    );
    if (d != null) setState(() => _date = d);
  }

  void _swap() => setState(() {
        final t = _from;
        _from = _to;
        _to = t;
      });

  void _search() {
    if (_from == _to) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('From and To cities must be different')));
      return;
    }
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                ResultsScreen(from: _from, to: _to, date: _date)));
  }

  Widget _cityDropdown(String label, String value, ValueChanged<String?> cb) =>
      DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.location_on_outlined),
          border: const OutlineInputBorder(),
        ),
        items: cities
            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
            .toList(),
        onChanged: cb,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🚌 Bus Booking'),
        actions: [
          IconButton(
            tooltip: 'My bookings',
            icon: const Icon(Icons.confirmation_number_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MyBookingsScreen())),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _cityDropdown('From', _from, (v) => setState(() => _from = v!)),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: _swap,
                      icon: const Icon(Icons.swap_vert_circle_outlined, size: 32),
                    ),
                  ),
                  _cityDropdown('To', _to, (v) => setState(() => _to = v!)),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date of journey',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(fmtDate(_date)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: _search,
                      icon: const Icon(Icons.search),
                      label: const Text('Search buses'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- Results ----------------
class ResultsScreen extends StatelessWidget {
  final String from, to;
  final DateTime date;
  const ResultsScreen(
      {super.key, required this.from, required this.to, required this.date});

  @override
  Widget build(BuildContext context) {
    final buses = generateBuses(from, to, date);
    return Scaffold(
      appBar: AppBar(
        title: Text('$from → $to'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('${fmtDate(date)} • ${buses.length} buses'),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: buses.length,
        itemBuilder: (_, i) {
          final b = buses[i];
          final free = 40 - takenSeats(b, date).length;
          return Card(
            child: InkWell(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => SeatScreen(bus: b, date: date))),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(b.operator,
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.bold)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(6)),
                          child: Text('★ ${b.rating}',
                              style: const TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                    Text(b.type, style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(b.departs,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600)),
                        Text(b.duration,
                            style: const TextStyle(color: Colors.grey)),
                        Text(b.arrives,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$free seats left'),
                        Text('₹${b.price}',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.red)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------- Seat selection ----------------
class SeatScreen extends StatefulWidget {
  final Bus bus;
  final DateTime date;
  const SeatScreen({super.key, required this.bus, required this.date});
  @override
  State<SeatScreen> createState() => _SeatScreenState();
}

class _SeatScreenState extends State<SeatScreen> {
  final Set<int> _selected = {};
  late final Set<int> _taken;

  @override
  void initState() {
    super.initState();
    _taken = takenSeats(widget.bus, widget.date);
  }

  void _toggle(int n) {
    if (_taken.contains(n)) return;
    setState(() {
      if (_selected.contains(n)) {
        _selected.remove(n);
      } else if (_selected.length < 6) {
        _selected.add(n);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You can select up to 6 seats')));
      }
    });
  }

  Widget _seat(int n) {
    final taken = _taken.contains(n);
    final sel = _selected.contains(n);
    return GestureDetector(
      onTap: () => _toggle(n),
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: taken
              ? Colors.grey.shade400
              : sel
                  ? Colors.green
                  : Colors.white,
          border: Border.all(color: sel ? Colors.green : Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text('$n',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: sel ? Colors.white : Colors.black87)),
      ),
    );
  }

  Widget _legend(Color c, String t) => Row(children: [
        Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
                color: c,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 4),
        Text(t),
      ]);

  @override
  Widget build(BuildContext context) {
    final sorted = _selected.toList()..sort();
    final total = sorted.length * widget.bus.price;
    return Scaffold(
      appBar: AppBar(title: Text(widget.bus.operator)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _legend(Colors.white, 'Available'),
                _legend(Colors.green, 'Selected'),
                _legend(Colors.grey.shade400, 'Booked'),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      const Align(
                          alignment: Alignment.centerRight,
                          child: Icon(Icons.airline_seat_recline_extra)),
                      const SizedBox(height: 8),
                      for (var r = 0; r < 10; r++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _seat(r * 4 + 1),
                              const SizedBox(width: 8),
                              _seat(r * 4 + 2),
                              const SizedBox(width: 40),
                              _seat(r * 4 + 3),
                              const SizedBox(width: 8),
                              _seat(r * 4 + 4),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)
              ]),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sorted.isEmpty
                            ? 'No seats selected'
                            : 'Seats: ${sorted.join(', ')}'),
                        Text('₹$total',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: sorted.isEmpty
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => PassengerScreen(
                                    bus: widget.bus,
                                    date: widget.date,
                                    seats: sorted))),
                    child: const Text('Continue'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- Passenger details ----------------
class PassengerScreen extends StatefulWidget {
  final Bus bus;
  final DateTime date;
  final List<int> seats;
  const PassengerScreen(
      {super.key, required this.bus, required this.date, required this.seats});
  @override
  State<PassengerScreen> createState() => _PassengerScreenState();
}

class _PassengerScreenState extends State<PassengerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;
    final id = 'BK${DateTime.now().millisecondsSinceEpoch % 1000000}';
    final booking = Booking(
      id: id,
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      bus: widget.bus,
      date: widget.date,
      seats: widget.seats,
    );
    myBookings.insert(0, booking);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => ConfirmationScreen(booking: booking)),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.seats.length * widget.bus.price;
    return Scaffold(
      appBar: AppBar(title: const Text('Passenger details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: Text('${widget.bus.from} → ${widget.bus.to}'),
              subtitle: Text(
                  '${fmtDate(widget.date)} • ${widget.bus.departs}\nSeats: ${widget.seats.join(', ')}'),
              isThreeLine: true,
              trailing: Text('₹$total',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                      labelText: 'Passenger name',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().length < 2)
                      ? 'Enter a valid name'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: 'Phone number',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder()),
                  validator: (v) =>
                      (v == null || !RegExp(r'^\d{10}$').hasMatch(v.trim()))
                          ? 'Enter a 10-digit number'
                          : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: _confirm,
              child: Text('Pay ₹$total & confirm'),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Demo app: no real payment is processed.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

// ---------------- Confirmation ----------------
class ConfirmationScreen extends StatelessWidget {
  final Booking booking;
  const ConfirmationScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final b = booking;
    return Scaffold(
      appBar: AppBar(
          title: const Text('Booking confirmed'),
          automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 90),
          const SizedBox(height: 8),
          const Text('Your ticket is booked!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          BookingCard(booking: b),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () =>
                Navigator.popUntil(context, (route) => route.isFirst),
            child: const Text('Back to home'),
          ),
        ],
      ),
    );
  }
}

class BookingCard extends StatelessWidget {
  final Booking booking;
  const BookingCard({super.key, required this.booking});

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: const TextStyle(color: Colors.grey)),
            Flexible(
                child: Text(v,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final b = booking;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _row('Booking ID', b.id),
            _row('Route', '${b.bus.from} → ${b.bus.to}'),
            _row('Date', fmtDate(b.date)),
            _row('Departure', b.bus.departs),
            _row('Bus', '${b.bus.operator}\n${b.bus.type}'),
            _row('Seats', b.seats.join(', ')),
            _row('Passenger', b.name),
            _row('Phone', b.phone),
            const Divider(),
            _row('Total paid', '₹${b.total}'),
          ],
        ),
      ),
    );
  }
}

// ---------------- My bookings ----------------
class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My bookings')),
      body: myBookings.isEmpty
          ? const Center(child: Text('No bookings yet'))
          : ListView(
              padding: const EdgeInsets.all(12),
              children:
                  myBookings.map((b) => BookingCard(booking: b)).toList(),
            ),
    );
  }
}
