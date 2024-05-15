import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AnalyticsHistoryScreen extends StatefulWidget {
  const AnalyticsHistoryScreen({Key? key}) : super(key: key);

  @override
  _AnalyticsHistoryScreenState createState() => _AnalyticsHistoryScreenState();
}

class _AnalyticsHistoryScreenState extends State<AnalyticsHistoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String selectedClass = 'A';
  List<Map<String, dynamic>> history = [];
  List<Map<String, dynamic>> exits = [];
  List<Map<String, dynamic>> parkingStatus = [];
  bool showHistory = true;
  bool showExitedVehicles = false;
  bool isLoading = true;
  bool sortByNewest = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() {
      isLoading = true;
    });
    await _fetchAnalyticsData();
    await _fetchParkingStatus();
    await _fetchExitData();
    await _assignVehiclesToSlots();
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _fetchAnalyticsData() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('detections')
          .where('class', isEqualTo: selectedClass)
          .get();

      List<Map<String, dynamic>> fetchedHistory = snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'class': data['class'],
          'time': DateTime.fromMillisecondsSinceEpoch(
              (data['time'] * 1000).toInt()),
          'vehicleId': data['vehicleId'] ?? 'N/A',
        };
      }).toList();

      setState(() {
        history = fetchedHistory;
      });
    } catch (e) {
      print("Error fetching analytics data: $e");
    }
  }

  Future<void> _fetchExitData() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('exits')
          .where('class', isEqualTo: selectedClass)
          .get();

      List<Map<String, dynamic>> fetchedExits = snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return {
          'id': data['id'],
          'class': data['class'],
          'exitTime': DateTime.fromMillisecondsSinceEpoch(
              (data['exitTime'] * 1000).toInt()),
          'parkingDuration': data['parkingDuration'],
          'parkingFee': data['parkingFee'],
          'vehicleId': data['vehicleId'],
        };
      }).toList();

      setState(() {
        exits = fetchedExits;
      });
    } catch (e) {
      print("Error fetching exit data: $e");
    }
  }

  Future<void> _fetchParkingStatus() async {
    try {
      DocumentSnapshot snapshot =
          await _firestore.collection('parkingSlots').doc(selectedClass).get();

      if (snapshot.exists) {
        var data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          parkingStatus = List<Map<String, dynamic>>.from(data['slots'] ?? []);
        });
      } else {
        setState(() {
          parkingStatus = [];
        });
      }
    } catch (e) {
      print("Error fetching parking status: $e");
    }
  }

  Future<void> _assignVehiclesToSlots() async {
    try {
      for (var vehicle in history) {
        var vehicleId = vehicle['vehicleId'];
        var vehicleClass = vehicle['class'];

        bool vehicleExists =
            parkingStatus.any((slot) => slot['vehicleId'] == vehicleId);
        if (vehicleExists) {
          continue;
        }

        var availableSlot = parkingStatus.firstWhere(
          (slot) =>
              slot['slotClass'] == vehicleClass && slot['isFilled'] == false,
          orElse: () => <String, dynamic>{},
        );

        if (availableSlot.isNotEmpty) {
          availableSlot['isFilled'] = true;
          availableSlot['vehicleId'] = vehicleId;
          availableSlot['entryTime'] =
              (DateTime.now().millisecondsSinceEpoch / 1000).toDouble();

          var doc = await _firestore
              .collection('parkingSlots')
              .doc(vehicleClass)
              .get();
          var data = doc.data() as Map<String, dynamic>;
          var slots = List<Map<String, dynamic>>.from(data['slots'] ?? []);

          var updatedSlots = slots.map((slot) {
            if (slot['id'] == availableSlot['id']) {
              return availableSlot;
            }
            return slot;
          }).toList();

          await _firestore
              .collection('parkingSlots')
              .doc(vehicleClass)
              .update({'slots': updatedSlots});

          await _fetchParkingStatus();
        }
      }
    } catch (e) {
      print("Error assigning vehicles to slots: $e");
    }
  }

  Future<void> _markAsExited(String slotId, String slotClass) async {
    try {
      var slot = parkingStatus.firstWhere((slot) => slot['id'] == slotId);
      if (slot == null) return;

      double entryTime = slot['entryTime'];
      int exitTime = (DateTime.now().millisecondsSinceEpoch / 1000).toInt();
      int parkingDuration = exitTime - entryTime.toInt();
      double parkingFee = _calculateParkingFee(parkingDuration);

      bool confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Confirm Exit'),
          content: Text(
            'Vehicle ID: ${slot['vehicleId']}\n'
            'Parking Duration: ${_formatDuration(parkingDuration)}\n'
            'Parking Fee: \$${parkingFee.toStringAsFixed(2)}\n'
            'Do you confirm payment and exit?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Confirm'),
            ),
          ],
        ),
      );

      if (!confirm) return;

      var doc =
          await _firestore.collection('parkingSlots').doc(slotClass).get();
      var data = doc.data() as Map<String, dynamic>;
      var slots = List<Map<String, dynamic>>.from(data['slots'] ?? []);

      var updatedSlots = slots.map((slot) {
        if (slot['id'] == slotId) {
          slot['isFilled'] = false;
          slot['vehicleId'] = null;
          slot.remove('entryTime');
        }
        return slot;
      }).toList();

      await _firestore
          .collection('parkingSlots')
          .doc(slotClass)
          .update({'slots': updatedSlots});

      await _firestore.collection('exits').add({
        'id': slotId,
        'class': slotClass,
        'exitTime': exitTime,
        'parkingDuration': parkingDuration,
        'parkingFee': parkingFee,
        'vehicleId': slot['vehicleId'],
      });

      await _fetchParkingStatus();
      await _fetchAnalyticsData();
      await _fetchExitData();
    } catch (e) {
      print("Error marking as exited: $e");
    }
  }

  double _calculateParkingFee(int durationInSeconds) {
    double ratePerHour = 2.0;
    int hoursParked = (durationInSeconds / 3600).ceil();
    return ratePerHour * hoursParked;
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy/MM/dd HH:mm:ss').format(dateTime);
  }

  String _formatDuration(int durationInSeconds) {
    int days = durationInSeconds ~/ (24 * 3600);
    int hours = (durationInSeconds % (24 * 3600)) ~/ 3600;
    int minutes = (durationInSeconds % 3600) ~/ 60;
    int seconds = durationInSeconds % 60;
    return '${days}d ${hours}h ${minutes}m ${seconds}s';
  }

  void _selectClass(String vehicleClass) {
    setState(() {
      selectedClass = vehicleClass;
      _initializeData();
    });
  }

  void _showExitConfirmationDialog(
      String slotId, String vehicleId, double entryTime) {
    int exitTime = (DateTime.now().millisecondsSinceEpoch / 1000).toInt();
    int parkingDuration = exitTime - entryTime.toInt();
    double parkingFee = _calculateParkingFee(parkingDuration);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Exit'),
        content: Text(
          'Vehicle ID: $vehicleId\n'
          'Parking Duration: ${_formatDuration(parkingDuration)}\n'
          'Parking Fee: \$${parkingFee.toStringAsFixed(2)}\n'
          'Do you confirm payment and exit?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(true);
              await _markAsExited(slotId, selectedClass);
            },
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _toggleShowExitedVehicles() {
    setState(() {
      showExitedVehicles = !showExitedVehicles;
    });
  }

  void _toggleSortOrder() {
    setState(() {
      sortByNewest = !sortByNewest;
      if (sortByNewest) {
        history.sort((a, b) => b['time'].compareTo(a['time']));
        exits.sort((a, b) => b['exitTime'].compareTo(a['exitTime']));
      } else {
        history.sort((a, b) => a['time'].compareTo(b['time']));
        exits.sort((a, b) => a['exitTime'].compareTo(b['exitTime']));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> displayedData =
        showExitedVehicles ? exits : history;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics and History'),
        backgroundColor: Colors.blue,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Text(
                        'Total Vehicles Exited: ${exits.length}',
                        style: TextStyle(fontSize: 16),
                      ),
                      Spacer(),
                      IconButton(
                        icon: Icon(Icons.sort),
                        onPressed: _toggleSortOrder,
                      ),
                      ElevatedButton(
                        onPressed: _toggleShowExitedVehicles,
                        child: Text(showExitedVehicles
                            ? 'Show Parked Vehicles'
                            : 'Show Exited Vehicles'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            showHistory = !showHistory;
                          });
                        },
                        child: Text(showHistory
                            ? 'Show Parking Status'
                            : 'Show History'),
                      ),
                      DropdownButton<String>(
                        value: selectedClass,
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            _selectClass(newValue);
                          }
                        },
                        items: <String>['A', 'B', 'C']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text('Class $value'),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: showHistory
                      ? ListView.builder(
                          itemCount: displayedData.length,
                          itemBuilder: (context, index) {
                            var item = displayedData[index];
                            var isExitedVehicle = exits.contains(item);
                            return Card(
                              color: isExitedVehicle
                                  ? Colors.green[100]
                                  : Colors.white,
                              child: ListTile(
                                title: Text('Detection ID: ${item['id']}'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Class: ${item['class']}'),
                                    if (isExitedVehicle) ...[
                                      Text(
                                          'Exit Date: ${DateFormat('yyyy/MM/dd').format(item['exitTime'])}'),
                                      Text(
                                          'Exit Time: ${DateFormat('HH:mm:ss').format(item['exitTime'])}'),
                                      Text(
                                          'Parking Fee: \$${item['parkingFee']}'),
                                      Text('Vehicle ID: ${item['vehicleId']}'),
                                    ] else ...[
                                      Text(
                                          'Date: ${DateFormat('yyyy/MM/dd').format(item['time'])}'),
                                      Text(
                                          'Time: ${DateFormat('HH:mm:ss').format(item['time'])}'),
                                      Text('Vehicle ID: ${item['vehicleId']}'),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(8),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            childAspectRatio: 1,
                          ),
                          itemCount: parkingStatus.length,
                          itemBuilder: (context, index) {
                            var slot = parkingStatus[index];
                            return GestureDetector(
                              onTap: slot['isFilled']
                                  ? () {
                                      _showExitConfirmationDialog(
                                        slot['id'],
                                        slot['vehicleId'],
                                        slot['entryTime'],
                                      );
                                    }
                                  : null,
                              child: Card(
                                color: slot['isFilled']
                                    ? Colors.red
                                    : Colors.green,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Slot ID: ${slot['id']}'),
                                      Text('Class: ${slot['slotClass']}'),
                                      Text(
                                          'Status: ${slot['isFilled'] ? 'Filled' : 'Empty'}'),
                                      if (slot['isFilled'])
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                'Vehicle ID: ${slot['vehicleId']}'),
                                            Text(
                                                'Entry Time: ${DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.fromMillisecondsSinceEpoch((slot['entryTime'] * 1000).toInt()))}'),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
