import 'package:calendarro/calendarro.dart';
import 'package:calendarro/date_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:date_range_picker/date_range_picker.dart';
import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart';
import 'package:intl/intl.dart';
import 'package:md2_tab_indicator/md2_tab_indicator.dart';
import 'package:meeting_maker/share_id_page.dart';
import 'package:quiver/collection.dart';
import 'package:random_string/random_string.dart';
import 'dart:convert';

import 'configuring_day_tile.dart';
import 'custom_day_tile_builder.dart';

class ConfigureMeeting extends StatefulWidget {
  final FirebaseUser _currentUser;
  final String _id;
  final String _ownerName;
  final String _title;
  final List<DateTime> _originalDates;

  ConfigureMeeting(this._currentUser, this._id, this._originalDates, this._title, this._ownerName);

  @override
  State<StatefulWidget> createState() => _ConfigureMeetingState();
}

class _ConfigureMeetingState extends State<ConfigureMeeting> with TickerProviderStateMixin {
  Calendarro calender;

  TabController _tabController;

  bool _disableCreateButton = false;
  bool creating = false;

  double _animatingHeight = 0;

  static const int maxListSize = 6;

  Multimap<DateTime, TimeOfDay> _whitelists = ListMultimap();
  Multimap<DateTime, TimeOfDay> _blacklists = ListMultimap();

  @override
  void initState() {
    calender = Calendarro(
        startDate: DateTime.now(),
        endDate: DateTime.now().add(Duration(days: 30)),
        displayMode: DisplayMode.MONTHS,
        selectionMode: SelectionMode.MULTI,
        dayTileBuilder: ConfiguringDayTileBuilder(widget._originalDates),
        onTap: (date) {
          setState(() {
            _tabController = TabController(length: calender.selectedDates.length, vsync: this);

            if (calender.selectedDates.isNotEmpty)
              _animatingHeight = 430;
            else
              _animatingHeight = 0;
          });
        });

    _tabController = TabController(length: calender.selectedDates.length, vsync: this);

    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Center(
        child: ListView(
          children: <Widget>[
            SizedBox(height: 35),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text("JOIN",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 30, fontFamily: "Lobster")),
                Text(
                  "a meeting",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFeeeeee), fontSize: 15, fontFamily: "Pacifico"),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.only(left: 40, right: 40, top: 35, bottom: 35),
              child: Text("Pick which days you can attend the meeting in:"),
            ),
            AbsorbPointer(
              absorbing: creating,
              child: calender,
            ),
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOutQuart,
              height: _animatingHeight,
              child: ListView(
                physics: NeverScrollableScrollPhysics(),
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(left: 40, right: 40, bottom: 15),
                    child: Text("Pick the times for each day you can attend the meeting in:"),
                  ),
                  Align(
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Theme.of(context).primaryColor,
                      unselectedLabelColor: Color(0xFFEEEEEE),
                      isScrollable: true,
                      indicator: MD2Indicator(
                          indicatorHeight: 3,
                          indicatorColor: Theme.of(context).primaryColor,
                          indicatorSize: MD2IndicatorSize.normal),
                      tabs: calender.selectedDates
                          .map((date) => Tab(
                                  child: Text(
                                "${DateFormat('MMM').format(date)}-${DateFormat('E').format(date)}\n${date.day}",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14, fontFamily: "RobotoMono"),
                              )))
                          .toList(),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Container(
                      color: Color(0x60393e46),
                      height: 300,
                      child: LayoutBuilder(
                        builder: (BuildContext context, BoxConstraints constraints) {
                          return TabBarView(
                            controller: _tabController,
                            children: calender.selectedDates.isEmpty
                                ? <Widget>[]
                                : calender.selectedDates
                                    .map(
                                      (date) => Column(
                                        children: <Widget>[
                                          Padding(
                                            padding: EdgeInsets.only(top: 10),
                                          ),
                                          if (!_whitelists.containsKey(date) && !_blacklists.containsKey(date))
                                            Text(
                                              "Can attend during any time of this day.",
                                              style: TextStyle(color: Colors.lightGreenAccent),
                                            ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: <Widget>[
                                              SizedBox(
                                                width: constraints.maxWidth / 2.0,
                                                child: Padding(
                                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: <Widget>[
                                                      if (_whitelists.containsKey(date))
                                                        Row(
                                                          children: <Widget>[
                                                            Text(
                                                              "CAN",
                                                              style: TextStyle(color: Colors.lightGreenAccent),
                                                            ),
                                                            Text(" attend during:"),
                                                          ],
                                                        ),
                                                      Padding(
                                                        padding: EdgeInsets.only(bottom: 10),
                                                      ),
                                                      Padding(
                                                        padding: EdgeInsets.only(bottom: 10),
                                                        child: InkWell(
                                                          onTap: _whitelists[date].length >= maxListSize
                                                              ? null
                                                              : () {
                                                                  showTimePicker(context: context, initialTime: TimeOfDay.now())
                                                                      .then((time) {
                                                                    if (time != null)
                                                                      setState(() {
                                                                        for (TimeOfDay tod in _whitelists[date]) {
                                                                          if (tod.hour == time.hour && tod.minute == time.minute) {
                                                                            return;
                                                                          }
                                                                        }
                                                                        _whitelists.add(date, time);
                                                                      });
                                                                  });
                                                                },
                                                          child: Container(
                                                            decoration: BoxDecoration(
                                                                color: _whitelists[date].length >= maxListSize
                                                                    ? Color(0xFF4f4f4f)
                                                                    : Theme.of(context).primaryColor,
                                                                borderRadius: BorderRadius.circular(3)),
                                                            height: 35,
                                                            child: Row(
                                                              mainAxisAlignment: MainAxisAlignment.start,
                                                              children: <Widget>[
                                                                Padding(
                                                                    padding: EdgeInsets.only(left: 5),
                                                                    child: Icon(
                                                                      Icons.add_circle_outline,
                                                                      color: _whitelists[date].length >= maxListSize
                                                                          ? Color(0xFF999999)
                                                                          : Colors.lightGreenAccent,
                                                                    )),
                                                                Padding(
                                                                  padding: EdgeInsets.only(left: 5),
                                                                  child: Text(
                                                                    "Whitelist Time",
                                                                    style: TextStyle(
                                                                        color: _whitelists[date].length >= maxListSize
                                                                            ? Color(0xFF999999)
                                                                            : Color(0xFFEEEEEE)),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ]..add(
                                                        Column(
                                                          children: _whitelists[date]
                                                              .map(
                                                                (timeOfDay) => Padding(
                                                                  padding: EdgeInsets.only(bottom: 5),
                                                                  child: Container(
                                                                    decoration: BoxDecoration(
                                                                        gradient: LinearGradient(
                                                                            colors: [Colors.lightGreenAccent, Colors.transparent],
                                                                            begin: Alignment.topLeft,
                                                                            end: Alignment.bottomRight,
                                                                            stops: [0.3, 1.0]),
                                                                        borderRadius: BorderRadius.circular(3)),
                                                                    height: 30,
                                                                    child: Row(
                                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                      children: <Widget>[
                                                                        Padding(
                                                                          padding: EdgeInsets.only(left: 5),
                                                                          child: Text(
                                                                            MaterialLocalizations.of(context)
                                                                                .formatTimeOfDay(timeOfDay),
                                                                            style: TextStyle(color: Colors.black),
                                                                          ),
                                                                        ),
                                                                        Spacer(),
                                                                        InkWell(
                                                                          onTap: () {
                                                                            showTimePicker(
                                                                                    context: context,
                                                                                    initialTime: TimeOfDay.now())
                                                                                .then((time) {
                                                                              if (time != null)
                                                                                setState(() {
                                                                                  _whitelists.remove(date, timeOfDay);

                                                                                  for (TimeOfDay tod in _whitelists[date]) {
                                                                                    if (tod.hour == time.hour && tod.minute == time.minute) {
                                                                                      return;
                                                                                    }
                                                                                  }
                                                                                  _whitelists.add(date, time);
                                                                                });
                                                                            });
                                                                          },
                                                                          child: Icon(
                                                                            Icons.edit,
                                                                            color: Theme.of(context).primaryColor,
                                                                          ),
                                                                        ),
                                                                        InkWell(
                                                                          onTap: () {
                                                                            setState(() {
                                                                              _whitelists.remove(date, timeOfDay);
                                                                            });
                                                                          },
                                                                          child: Icon(
                                                                            Icons.delete_forever,
                                                                            color: Colors.red,
                                                                          ),
                                                                        )
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              )
                                                              .toList(),
                                                        ),
                                                      ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: constraints.maxWidth / 2.0,
                                                child: Padding(
                                                  padding: EdgeInsets.only(right: 10),
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: <Widget>[
                                                      if (_whitelists.containsKey(date))
                                                        Row(
                                                          children: <Widget>[
                                                            Text(
                                                              "CAN'T",
                                                              style: TextStyle(color: Colors.redAccent),
                                                            ),
                                                            Text(" attend during:"),
                                                          ],
                                                        ),
                                                      Padding(
                                                        padding: EdgeInsets.only(bottom: 10),
                                                      ),
                                                      Padding(
                                                        padding: EdgeInsets.only(bottom: 10),
                                                        child: InkWell(
                                                          onTap: _blacklists[date].length >= maxListSize
                                                              ? null
                                                              : () {
                                                            showTimePicker(context: context, initialTime: TimeOfDay.now())
                                                                .then((time) {
                                                              if (time != null)
                                                                setState(() {

                                                                  for (TimeOfDay tod in _blacklists[date]) {
                                                                    if (tod.hour == time.hour && tod.minute == time.minute) {
                                                                      return;
                                                                    }
                                                                  }
                                                                  _blacklists.add(date, time);
                                                                });
                                                            });
                                                          },
                                                          child: Container(
                                                            decoration: BoxDecoration(
                                                                color: _blacklists[date].length >= maxListSize
                                                                    ? Color(0xFF4f4f4f)
                                                                    : Theme.of(context).primaryColor,
                                                                borderRadius: BorderRadius.circular(3)),
                                                            height: 35,
                                                            child: Row(
                                                              mainAxisAlignment: MainAxisAlignment.start,
                                                              children: <Widget>[
                                                                Padding(
                                                                    padding: EdgeInsets.only(left: 5),
                                                                    child: Icon(
                                                                      Icons.add_circle_outline,
                                                                      color: _blacklists[date].length >= maxListSize
                                                                          ? Color(0xFF999999)
                                                                          : Colors.lightGreenAccent,
                                                                    )),
                                                                Padding(
                                                                  padding: EdgeInsets.only(left: 5),
                                                                  child: Text(
                                                                    "Blacklist Time",
                                                                    style: TextStyle(
                                                                        color: _blacklists[date].length >= maxListSize
                                                                            ? Color(0xFF999999)
                                                                            : Color(0xFFEEEEEE)),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ]..add(
                                                        ListView(
                                                          shrinkWrap: true,
                                                          children: _blacklists[date]
                                                              .map(
                                                                (timeOfDay) => Padding(
                                                                  padding: EdgeInsets.only(bottom: 5),
                                                                  child: Container(
                                                                    decoration: BoxDecoration(
                                                                        gradient: LinearGradient(
                                                                            colors: [Colors.redAccent, Colors.transparent],
                                                                            begin: Alignment.topLeft,
                                                                            end: Alignment.bottomRight,
                                                                            stops: [0.3, 1.0]),
                                                                        borderRadius: BorderRadius.circular(3)),
                                                                    height: 30,
                                                                    child: Row(
                                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                      children: <Widget>[
                                                                        Padding(
                                                                          padding: EdgeInsets.only(left: 5),
                                                                          child: Text(
                                                                            MaterialLocalizations.of(context)
                                                                                .formatTimeOfDay(timeOfDay),
                                                                            style: TextStyle(color: Colors.black),
                                                                          ),
                                                                        ),
                                                                        Spacer(),
                                                                        InkWell(
                                                                          onTap: () {
                                                                            showTimePicker(
                                                                                    context: context,
                                                                                    initialTime: TimeOfDay.now())
                                                                                .then((time) {
                                                                              if (time != null)
                                                                                setState(() {
                                                                                  _blacklists.remove(date, timeOfDay);

                                                                                  for (TimeOfDay tod in _blacklists[date]) {
                                                                                    if (tod.hour == time.hour && tod.minute == time.minute) {
                                                                                      return;
                                                                                    }
                                                                                  }
                                                                                  _blacklists.add(date, time);
                                                                                });
                                                                            });
                                                                          },
                                                                          child: Icon(
                                                                            Icons.edit,
                                                                            color: Theme.of(context).primaryColor,
                                                                          ),
                                                                        ),
                                                                        InkWell(
                                                                          onTap: () {
                                                                            setState(() {
                                                                              _blacklists.remove(date, timeOfDay);
                                                                            });
                                                                          },
                                                                          child: Icon(
                                                                            Icons.delete_forever,
                                                                            color: Colors.red,
                                                                          ),
                                                                        )
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              )
                                                              .toList(),
                                                        ),
                                                      ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    )
                                    .toList(),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 150,
              child: RaisedButton(
                  onPressed: _disableCreateButton || calender.selectedDates.isEmpty || creating ? null : () {},
                  color: Theme.of(context).primaryColor,
                  child: Text("Join")),
            ),
            Visibility(
              visible: creating,
              child: CircularProgressIndicator(
                value: null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
