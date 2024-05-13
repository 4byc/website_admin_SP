import 'package:flutter/material.dart';

class ParkingSlot {
  String id;
  String slotClass;
  bool isFilled;
  DateTime? startTime;
  DateTime? endTime;

  ParkingSlot({required this.id, required this.slotClass, this.isFilled = false, this.startTime, this.endTime});
}

class AnalyticsHistoryScreen extends StatefulWidget {
  const AnalyticsHistoryScreen({Key? key}) : super(key: key);

  @override
  _AnalyticsHistoryScreenState createState() => _AnalyticsHistoryScreenState();
}

class _AnalyticsHistoryScreenState extends State<AnalyticsHistoryScreen> {
  List<ParkingSlot> slots = List.generate(150, (index) {
    String classType = (index < 50) ? "A" : (index < 100) ? "B" : "C";
    return ParkingSlot(id: '${classType}-${index % 50 + 1}', slotClass: classType);
  });
  String selectedClass = 'A';  // Default class

  void toggleSlot(int index) {
    setState(() {
      var slot = slots[index];
      slot.isFilled = !slot.isFilled;
      if (slot.isFilled) {
        slot.startTime = DateTime.now();
      } else {
        slot.endTime = DateTime.now();
        calculateParkingDuration(slot.startTime!, slot.endTime!);
      }
    });
  }

  void calculateParkingDuration(DateTime start, DateTime end) {
    var duration = end.difference(start);
    print("Parked for: ${duration.inHours} hours and ${duration.inMinutes % 60} minutes");
  }

  @override
  Widget build(BuildContext context) {
    List<ParkingSlot> displayedSlots = slots.where((slot) => slot.slotClass == selectedClass).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics and History'),
        actions: <Widget>[
          DropdownButton<String>(
            value: selectedClass,
            icon: const Icon(Icons.arrow_downward),
            onChanged: (String? newValue) {
              setState(() {
                selectedClass = newValue!;
              });
            },
            items: <String>['A', 'B', 'C']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 10,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: displayedSlots.length,
        itemBuilder: (context, index) {
          var slot = displayedSlots[index];
          return Card(
            color: slot.isFilled ? Colors.red : Colors.green,
            child: InkWell(
              onTap: () => toggleSlot(slots.indexOf(slot)), // Use the original list to manage states
              child: Center(child: Text('${slot.slotClass}-${slot.id}', style: TextStyle(color: Colors.white))),
            ),
          );
        },
      ),
    );
  }
}
