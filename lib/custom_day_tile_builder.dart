import 'package:calendarro/calendarro.dart';
import 'package:calendarro/date_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomDayTileBuilder extends DayTileBuilder {
  @override
  Widget build(BuildContext context, DateTime date, DateTimeCallback onTap) {
    return _CustomDayTile(date, Calendarro.of(context), onTap);
  }
}

class _CustomDayTile extends StatefulWidget {
  final DateTime date;
  final DateTimeCallback onTap;
  final CalendarroState calendarroState;

  _CustomDayTile(this.date, this.calendarroState, this.onTap);

  @override
  State<StatefulWidget> createState() => _DayTileState(calendarroState);
}

class _DayTileState extends State<_CustomDayTile> {
  CalendarroState calendarroState;

  _DayTileState(this.calendarroState);

  double _height = 0.0;
  double _borderWidth = 0.0;
  Curve curve = Curves.easeOutQuart;

  @override
  Widget build(BuildContext context) {
    calendarroState = Calendarro.of(context);

    bool selected = calendarroState.isDateSelected(widget.date);
    _height = selected ? 40.0 : 0.0;
    _borderWidth = selected ? 1.0 : 0.0;

    BoxDecoration boxDecoration = BoxDecoration(
      color: Theme.of(context).primaryColor,
      shape: BoxShape.circle,
      border: Border.all(
        color: _borderWidth > 0 ? Color(0xFFEEEEEE) : Color(0x00000000),
        width: _borderWidth,
      ),
    );

    return Expanded(
      child: GestureDetector(
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            SizedBox(
              height: 40,
              width: 40,
            ),
            AnimatedContainer(
              duration: Duration(milliseconds: 150),
              curve: curve,
              height: _height,
              width: _height,
              decoration: boxDecoration,
            ),
            Center(
                child: Text(
              "${widget.date.day}",
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFEEEEEE)),
            ))
          ],
        ),
        onTap: handleTap,
        behavior: HitTestBehavior.translucent,
      ),
    );
  }

  void handleTap() {
    setState(() {
      if (calendarroState.isDateSelected(widget.date)) {
        _height = 0.0;
        _borderWidth = 0.0;
        curve = Curves.easeInQuart;
      } else {
        _height = 40.0;
        _borderWidth = 1.0;
        curve = Curves.easeOutQuart;
      }
    });

    if (widget.onTap != null) {
      widget.onTap(widget.date);
    }

    calendarroState.setSelectedDate(widget.date);
    calendarroState.setCurrentDate(widget.date);
  }
}
