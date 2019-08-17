import 'package:calendarro/calendarro.dart';
import 'package:calendarro/date_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ConfiguringDayTileBuilder extends DayTileBuilder {
  final List<DateTime> _originalDates;

  ConfiguringDayTileBuilder(this._originalDates);

  @override
  Widget build(BuildContext context, DateTime date, DateTimeCallback onTap) {
    return _ConfiguringDayTile(date, _originalDates, Calendarro.of(context), onTap);
  }
}

class _ConfiguringDayTile extends StatefulWidget {
  final DateTime date;
  final DateTimeCallback onTap;
  final CalendarroState calendarroState;
  final List<DateTime> _originalDates;

  _ConfiguringDayTile(
      this.date, this._originalDates, this.calendarroState, this.onTap);

  @override
  State<StatefulWidget> createState() => _ConfiguringDayTileState(calendarroState);
}

class _ConfiguringDayTileState extends State<_ConfiguringDayTile> {
  CalendarroState calendarroState;

  _ConfiguringDayTileState(this.calendarroState);

  double _height = 0.0;
  double _borderWidth = 0.0;
  Curve curve = Curves.easeOutQuart;

  @override
  Widget build(BuildContext context) {
    calendarroState = Calendarro.of(context);

    bool selected = calendarroState.isDateSelected(widget.date);
    _height = selected ? 40.0 : 0.0;
    _borderWidth = selected ? 1.0 : 0.0;

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
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _borderWidth > 0 ? Color(0xFFEEEEEE) : Color(0x00000000),
                  width: _borderWidth,
                ),
              ),
            ),
            Center(
                child: Text(
              "${widget.date.day}",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color:
                      isAnOriginalDate() ? Color(0xFFEEEEEE) : Color(0xFF545454)),
            ))
          ],
        ),
        onTap: isAnOriginalDate() ? handleTap : null,
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

    calendarroState.setSelectedDate(widget.date);
    calendarroState.setCurrentDate(widget.date);

    if (widget.onTap != null) {
      widget.onTap(widget.date);
    }
  }

  bool isAnOriginalDate() {
    for (DateTime dt in widget._originalDates) {
      if (dt.day == widget.date.day) {
        return true;
      }
    }
    return false;
  }
}
