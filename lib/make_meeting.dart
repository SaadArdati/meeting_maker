import 'package:calendarro/calendarro.dart';
import 'package:calendarro/date_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:date_range_picker/date_range_picker.dart';
import 'package:meeting_maker/share_id_page.dart';
import 'package:random_string/random_string.dart';
import 'dart:convert';

import 'custom_day_tile_builder.dart';

class MakeMeetingPage extends StatefulWidget {
  final databaseReference = FirebaseDatabase.instance.reference();
  final FirebaseUser _currentUser;

  MakeMeetingPage(this._currentUser);

  @override
  State<StatefulWidget> createState() => _MakeMeetingPageState();
}

class _MakeMeetingPageState extends State<MakeMeetingPage> {
  final calendarroStateKey = GlobalKey<CalendarroState>();

  TextEditingController controller = TextEditingController();

  bool _disableCreateButton = false;
  bool creating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: ListView(
        children: <Widget>[
          Center(
            child: Column(
              children: <Widget>[
                SizedBox(height: 35),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text("MAKE",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 30,
                            fontFamily: "Lobster")),
                    Text(
                      "a meeting",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Color(0xFFeeeeee),
                          fontSize: 15,
                          fontFamily: "Pacifico"),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(left: 40, right: 40, top: 20),
                  child: Text(
                    "Specify a title for your meeting:",
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                    padding: EdgeInsets.only(left: 40, right: 40, top: 15),
                    child: Column(
                      children: <Widget>[
                        TextField(
                          enabled: !_disableCreateButton && !creating,
                          controller: controller,
                          onChanged: (text) {
                            setState(() {});
                          },
                          maxLength: 30,
                          decoration: InputDecoration(
                              hintText: "My Marvelous Meeting",
                              labelText: "Meeting Title",
                              isDense: true),
                        ),
                      ],
                    )),
                Padding(
                  padding:
                      EdgeInsets.only(left: 40, right: 40, bottom: 30, top: 40),
                  child: Text(
                    "Pick which days the meeting can potentially be held on:",
                    textAlign: TextAlign.center,
                  ),
                ),
                AbsorbPointer(
                  absorbing: creating,
                  child: Calendarro(
                    key: calendarroStateKey,
                    startDate: DateTime.now(),
                    endDate: DateTime.now().add(Duration(days: 30)),
                    displayMode: DisplayMode.MONTHS,
                    selectionMode: SelectionMode.MULTI,
                    dayTileBuilder: CustomDayTileBuilder(),
                    onTap: (date) {
                      setState(() {});
                    },
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: RaisedButton(
                      onPressed: _disableCreateButton ||
                              controller.text.isEmpty ||
                              calendarroStateKey
                                  .currentState.selectedDates.isEmpty ||
                              creating
                          ? null
                          : () {
                              setState(() {
                                creating = true;
                              });

                              List<DateTime> dates =
                                  calendarroStateKey.currentState.selectedDates;

                              String id = randomAlphaNumeric(5);

                              widget.databaseReference.child(id).set({
                                'title': controller.text,
                                'owner_email': widget._currentUser.email,
                                'owner_name': widget._currentUser.displayName,
                                'selected_dates': dates
                                    .map((date) => date.millisecondsSinceEpoch)
                                    .toList()
                              }).whenComplete(() {
                                setState(() {
                                  creating = false;
                                  Navigator.pushReplacement(
                                      context,
                                      CupertinoPageRoute(
                                          builder: (context) =>
                                              ShareMeetingID(id)));
                                });
                              }).catchError((error) {
                                print(error);
                                setState(() {
                                  creating = false;
                                });
                              });
                            },
                      color: Theme.of(context).primaryColor,
                      child: Text("Create")),
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
        ],
      ),
    );
  }
}
