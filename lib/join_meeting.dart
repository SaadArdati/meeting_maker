import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meeting_maker/configure_meeting.dart';
import 'package:meeting_maker/main.dart';
import 'package:meeting_maker/main.dart';

import 'main.dart';

class JoinMeetingPage extends StatefulWidget {
  final databaseReference = FirebaseDatabase.instance.reference();
  final FirebaseUser _currentUser;


  JoinMeetingPage(this._currentUser);

  @override
  State<StatefulWidget> createState() => _JoinMeetingPageState();
}

class _JoinMeetingPageState extends State<JoinMeetingPage> {
  TextEditingController controller = TextEditingController();

  String errorToShow = "";
  bool _showingError = false;
  bool _disableJoinButton = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Center(
        child: Column(
          children: <Widget>[
            SizedBox(height: 35),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text("JOIN",
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
                Padding(
                    padding: EdgeInsets.only(left: 40, right: 40, top: 15),
                    child: Column(
                      children: <Widget>[
                        TextField(
                          controller: controller,
                          onChanged: (text) {
                            setState(() {
                            });
                          },
                          enabled: !_disableJoinButton,
                          maxLength: 10,
                          decoration: InputDecoration(
                              hintText: "#000000", labelText: "Meeting Code"),
                        ),
                      ],
                    )),
                SizedBox(
                  width: 150,
                  child: RaisedButton(
                      onPressed: _disableJoinButton || controller.text.isEmpty
                          ? null
                          : () {
                              setState(() {
                                _disableJoinButton = true;
                              });

                              widget.databaseReference
                                  .reference()
                                  .child(controller.text)
                                  .once()
                                  .then((DataSnapshot snapshot) {
                                if (snapshot.value == null) {
                                  setState(() {
                                    _showingError = true;
                                    _disableJoinButton = false;
                                    errorToShow =
                                        "No meeting exists with that code.";
                                  });
                                } else {

                                  List<DateTime> dates = List();

                                  List<int> datesJson = (snapshot.value['selected_dates'] as List).cast<int>().toList();

                                  for (int millis in datesJson) {
                                    DateTime dt = DateTime.fromMillisecondsSinceEpoch(millis);
                                    dates.add(dt);
                                  }

                                  Navigator.pushReplacement(
                                      context,
                                      CupertinoPageRoute(
                                          builder: (context) => ConfigureMeeting(widget._currentUser, controller.text, dates, snapshot.value['title'], snapshot.value['owner_name'])));
                                }
                              });
                            },
                      color: Theme.of(context).primaryColor,
                      child: Text("Join")),
                ),
                SizedBox(height: 20),
                Stack(
                  children: <Widget>[
                    Visibility(
                      visible: _disableJoinButton,
                      child: CircularProgressIndicator(
                        value: null,
                      ),
                    ),
                    Visibility(
                      visible: !_disableJoinButton && _showingError,
                      child: Text(
                        errorToShow,
                        style: TextStyle(color: Colors.red),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

