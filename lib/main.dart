import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'join_meeting.dart';
import 'make_meeting.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meeting Maker',
      theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: Color(0xFF00adb5),
          accentColor: Color(0xFF00adb5),
          backgroundColor: Color(0xFF222831),
          scaffoldBackgroundColor: Color(0xFF222831),
          canvasColor: Color(0xFF222831),
          textTheme: Theme.of(context).textTheme.apply(
              bodyColor: Color(0xFFeeeeee),
              displayColor: Color(0xFFeeeeee),
              fontFamily: "RobotoMono")),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  StreamSubscription<FirebaseUser> _listener;
  FirebaseUser _currentUser;

  bool disableButtons = false;

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();

    if (_currentUser == null) {
      _handleGoogleSignIn()
          .then((FirebaseUser user) =>
              {print(user.email), disableButtons = false})
          .catchError((e) => {print(e)});
    }
  }

  @override
  void dispose() {
    _listener.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        body: Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  width: 200,
                  child: RaisedButton(
                    color: Color(0xFFeeeeee),
                    onPressed: disableButtons
                        ? null
                        : () {
                            setState(() {
                              disableButtons = true;

                              _checkCurrentUser();

                              if (_currentUser == null) {
                                _handleGoogleSignIn()
                                    .then((FirebaseUser user) =>
                                {print(user.email), disableButtons = false})
                                    .catchError((e) => {print(e)});
                              }
                            });
                          },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Image.asset(
                          'assets/g_logo_500.png',
                          width: 24,
                        ),
                        Padding(padding: EdgeInsets.only(right: 10)),
                        Text(
                          "Login using Google",
                          textAlign: TextAlign.left,
                          style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 15,
                              fontFamily: "Pacifico"),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  "Couldn't sign you in. Try again.",
                  style: TextStyle(color: Colors.red),
                )
              ]),
        ),
      );
    } else {
      return Scaffold(
          body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            InkWell(
              onTap: () {
                Navigator.push(
                    context,
                    CupertinoPageRoute(
                        builder: (context) => JoinMeetingPage(_currentUser)));
              },
              splashColor: Theme.of(context).primaryColor,
              highlightColor: Theme.of(context).primaryColor,
              child: SizedBox(
                width: double.infinity,
                height: 150,
                child: Container(
                  color: Color(0xFFeeeeee),
                  child: Center(
                      child: Column(
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
                            color: Color(0xFF222831),
                            fontSize: 15,
                            fontFamily: "Pacifico"),
                      ),
                    ],
                  )),
                ),
              ),
            ),
            SizedBox(height: 5),
            Text(
              "- OR -",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Color(0xFFEEEEEE),
                  fontSize: 20,
                  fontFamily: "Pacifico"),
            ),
            SizedBox(height: 5),
            InkWell(
              onTap: () {
                Navigator.push(
                    context,
                    CupertinoPageRoute(
                        builder: (context) => MakeMeetingPage(_currentUser)));
              },
              child: SizedBox(
                width: double.infinity,
                height: 150,
                child: Container(
                  color: Color(0xFFeeeeee),
                  child: Center(
                      child: Column(
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
                            color: Color(0xFF222831),
                            fontSize: 15,
                            fontFamily: "Pacifico"),
                      ),
                    ],
                  )),
                ),
              ),
            ),
          ],
        ),
      ));
    }
  }

  Future<FirebaseUser> _handleGoogleSignIn() async {
    final GoogleSignInAccount googleUser = await widget._googleSignIn.signIn();
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final FirebaseUser user =
        (await widget._auth.signInWithCredential(credential)).user;
    assert(user.email != null);
    assert(user.displayName != null);
    assert(!user.isAnonymous);
    assert(await user.getIdToken() != null);

    final FirebaseUser currentUser = await widget._auth.currentUser();
    assert(user.uid == currentUser.uid);
    setState(() {
      _currentUser = user;
    });
    return user;
  }

  void _checkCurrentUser() async {
    _currentUser = await widget._auth.currentUser();
    _currentUser?.getIdToken(refresh: true);

    _listener = widget._auth.onAuthStateChanged.listen((FirebaseUser user) {
      setState(() {
        _currentUser = user;
      });
    });
  }
}
