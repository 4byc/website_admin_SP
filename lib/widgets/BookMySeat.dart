import 'package:flutter/material.dart';

class BookMySeat extends StatefulWidget {
  final int totalSeats;
  final int seatsInRow;
  final List<int> bookedSeats;
  final Function(List<int>) onSeatSelected;

  const BookMySeat({
    required this.totalSeats,
    required this.seatsInRow,
    required this.bookedSeats,
    required this.onSeatSelected,
    Key? key,
    required List spotClasses,
  }) : super(key: key);

  @override
  _BookMySeatState createState() => _BookMySeatState();
}

class _BookMySeatState extends State<BookMySeat> {
  List<int> _selectedSeats = [];

  bool _isSeatBooked(int seatNumber) {
    return widget.bookedSeats.contains(seatNumber);
  }

  void _toggleSeat(int seatNumber) {
    setState(() {
      if (_selectedSeats.contains(seatNumber)) {
        _selectedSeats.remove(seatNumber);
      } else {
        _selectedSeats.add(seatNumber);
      }
      widget.onSeatSelected(_selectedSeats);
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> rows = [];
    int remainingSeats = widget.totalSeats;
    for (int i = 0; i < widget.totalSeats; i += widget.seatsInRow) {
      int seatsInThisRow = widget.seatsInRow;
      if (remainingSeats < widget.seatsInRow) {
        seatsInThisRow = remainingSeats;
      }
      List<Widget> rowSeats = [];
      for (int j = i; j < i + seatsInThisRow; j++) {
        int seatNumber = j + 1;
        rowSeats.add(
          InkWell(
            onTap: () {
              if (!_isSeatBooked(seatNumber)) {
                _toggleSeat(seatNumber);
              }
            },
            child: Container(
              margin: const EdgeInsets.all(4),
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _isSeatBooked(seatNumber) ? Colors.grey : Colors.green,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                seatNumber.toString(),
                style: TextStyle(
                  color:
                      _isSeatBooked(seatNumber) ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
        );
      }
      rows.add(Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: rowSeats,
      ));
      remainingSeats -= seatsInThisRow;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: rows,
    );
  }
}
