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
                    child: Text("Pick the times for each day you can attend the meeting in"),
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
                      child: TabBarView(
                        controller: _tabController,
                        children: calender.selectedDates.isEmpty
                            ? <Widget>[]
                            : calender.selectedDates
                                .map(
                                  (date) => ListView(
                                    children: <Widget>[
                                      Column(
                                        children: <Widget>[
                                          Padding(
                                            padding: EdgeInsets.only(top: 20),
                                          ),
                                          if (!_whitelists.containsKey(date) && !_blacklists.containsKey(date))
                                            Text(
                                              "Can attend during any time of this day.",
                                              style: TextStyle(color: Colors.lightGreenAccent),
                                            ),
                                          if (_whitelists.containsKey(date))
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: <Widget>[
                                                Padding(
                                                  padding: EdgeInsets.symmetric(horizontal: 20),
                                                  child: Row(
                                                    children: <Widget>[
                                                      Text(
                                                        "CAN",
                                                        style: TextStyle(color: Colors.lightGreenAccent),
                                                      ),
                                                      Text(" attend during these times:"),
                                                    ],
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.only(bottom: 20),
                                                ),
                                              ]..addAll(
                                                  _whitelists[date]
                                                      .map(
                                                        (timeOfDay) => Padding(
                                                          padding: EdgeInsets.only(left: 30, right: 30, bottom: 5),
                                                          child: FlatButton(
                                                            color: Color(0xFFEEEEEE),
                                                            onPressed: () {},
                                                            child: Row(
                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                              children: <Widget>[
                                                                Text(
                                                                  MaterialLocalizations.of(context).formatTimeOfDay(timeOfDay),
                                                                  style: TextStyle(fontSize: 18, color: Colors.black),
                                                                ),
                                                                FlatButton(
                                                                  shape: CircleBorder(),
                                                                  color: Color(0x00),
                                                                  onPressed: () {
                                                                    setState(() {
                                                                      _whitelists.remove(date, timeOfDay);
                                                                    });
                                                                  },
                                                                  child: Icon(
                                                                    Icons.delete_forever,
                                                                    color: Colors.red,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      )
                                                      .toList(),
                                                ),
                                            ),
                                          Padding(
                                            padding: EdgeInsets.only(right: 30, left: 30, top: 20),
                                            child: RaisedButton(
                                                onPressed: () {
                                                  showTimePicker(context: context, initialTime: TimeOfDay.now()).then((time) {
                                                    setState(() {
                                                      _whitelists.add(date, time);
                                                    });
                                                  });
                                                },
                                                color: Theme.of(context).primaryColor,
                                                child: Row(
                                                  children: <Widget>[
                                                    Icon(Icons.add_circle_outline),
                                                    Padding(
                                                      padding: EdgeInsets.only(right: 10),
                                                    ),
                                                    Text("Whitelist specific time range"),
                                                  ],
                                                )),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 30),
                                            child: RaisedButton(
                                                onPressed: () {
                                                  showTimePicker(context: context, initialTime: TimeOfDay.now()).then((time) {
                                                    setState(() {
                                                      _blacklists.add(date, time);
                                                    });
                                                  });
                                                },
                                                color: Theme.of(context).primaryColor,
                                                child: Row(
                                                  children: <Widget>[
                                                    Icon(Icons.remove_circle_outline),
                                                    Padding(
                                                      padding: EdgeInsets.only(right: 10),
                                                    ),
                                                    Text("Blacklist specific time range"),
                                                  ],
                                                )),
                                          ),
                                          if (false)
                                            TimePickerSpinner(
                                              is24HourMode: false,
                                              normalTextStyle: TextStyle(fontSize: 18),
                                              highlightedTextStyle:
                                                  TextStyle(fontSize: 24, color: Theme.of(context).primaryColor),
                                              spacing: 10,
                                              itemHeight: 40,
                                              isForce2Digits: false,
                                              onTimeChange: (time) {
                                                setState(() {});
                                              },
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                )
                                .toList(),
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
