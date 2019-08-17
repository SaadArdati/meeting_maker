import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meeting_maker/main.dart';
import 'package:meeting_maker/main.dart';
import 'package:share/share.dart';

import 'main.dart';

class ShareMeetingID extends StatefulWidget {
  final String _id;

  ShareMeetingID(this._id);

  @override
  State<StatefulWidget> createState() => _ShareMeetingIDState();
}

class _ShareMeetingIDState extends State<ShareMeetingID> {
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
                Padding(
                  padding: EdgeInsets.only(left: 40, right: 40, top: 15),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(bottom: 40),
                      ),
                      Text(
                          "Share this code with whoever you want to join your meeting."),
                      Padding(
                        padding: EdgeInsets.only(bottom: 40),
                      ),
                      InkWell(
                          borderRadius: BorderRadius.circular(24),
                          splashColor: Theme.of(context).primaryColor,
                          onTap: () {
                            Clipboard.setData(
                                new ClipboardData(text: widget._id));
                          },
                          child: Text(
                            widget._id,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 24),
                          )),
                      Padding(
                        padding: EdgeInsets.only(bottom: 40),
                      ),
                      SizedBox(
                        width: 110.0,
                        child: RaisedButton(
                          color: Color(0xFFEEEEEE),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24)),
                          onPressed: () {
                            Share.share(widget._id);
                          },
                          child: Row(
                            children: <Widget>[
                              Icon(Icons.share,
                                  color: Theme.of(context).primaryColor),
                              Padding(
                                padding: EdgeInsets.only(right: 10),
                              ),
                              Text(
                                "Share",
                                style: TextStyle(
                                    color: Theme.of(context).primaryColor),
                              )
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
