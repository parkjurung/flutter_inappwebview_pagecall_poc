import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview_pagecall/flutter_inappwebview_pagecall.dart';
import 'package:device_info/device_info.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Directory, File, Platform;
import 'package:url_launcher/url_launcher.dart';

main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  double currentvol = 0.5;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: InAppWebViewPage());
  }
}

void _permission() async {
  Map<Permission, PermissionStatus> statuses =
      await [Permission.microphone].request();

  for (var permission in statuses.values) {
    if (permission.isPermanentlyDenied || permission.isPermanentlyDenied) {
      print("isPermanentlyDenied");
      openAppSettings();
    } else if (permission.isRestricted) {
      print("isRestricted");
      openAppSettings();
    } else if (permission.isDenied) {
      print("isDenied");
    }
  }
}

class InAppWebViewPage extends StatefulWidget {
  @override
  _InAppWebViewPageState createState() => _InAppWebViewPageState();
}

class _InAppWebViewPageState extends State<InAppWebViewPage> {
  late InAppWebViewController _webViewController;
  late InAppWebViewController _webViewPopupController;
  String newtabUrl = "";
  String prevUrl = "";

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future _future() async {
    if (Platform.isIOS) {
      var iosInfo = await DeviceInfoPlugin().iosInfo;
      await Future.delayed(const Duration(seconds: 1));
      var osVersion = iosInfo.systemVersion;
      _permission();
      return osVersion;
    }
  }

  Future<void> openBrowser(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw "Could not launch $url";
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        resizeToAvoidBottomInset: false,
        body: FutureBuilder(
            future: _future(),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.hasData == false) {
                return CircularProgressIndicator(); // CircularProgressIndicator : 로딩 에니메이션
              } else if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '다시 실행하세요: ${snapshot.error}',
                    style: TextStyle(fontSize: 15),
                  ),
                );
              } else {
                String? pageType = '';
                Uri? browserUrl;
                return MaterialApp(
                  home: Scaffold(
                    body: SafeArea(
                      child: InAppWebView(
                        initialUrlRequest: URLRequest(
                            url: Uri.parse(
                                "https://wjtballtab-lms.wjthinkbig.com/emp/login")),
                        initialOptions: InAppWebViewGroupOptions(
                            crossPlatform: InAppWebViewOptions(
                                useShouldOverrideUrlLoading: true,
                                mediaPlaybackRequiresUserGesture: false,
                                javaScriptEnabled: true,
                                javaScriptCanOpenWindowsAutomatically:
                                    true                                 ),
                            ios: IOSInAppWebViewOptions(
                                allowsInlineMediaPlayback: true,
                                allowsAirPlayForMediaPlayback: true),
                            android: AndroidInAppWebViewOptions(
                                supportMultipleWindows: true)),
                        onLoadStart: (controller, url) {
                          if (url != null) {
                            pageType = url.queryParameters['pageType'];
                            if (pageType != null && pageType!.isNotEmpty) {
                              if (pageType == 'AT') {
                                browserUrl = url;
                              }
                            }
                          }
                        },
                        shouldOverrideUrlLoading:
                          (controller, navigationAction) async {
                        var uri = navigationAction.request.url;
                        if (uri.toString().contains("app.pagecall")) {
                          return NavigationActionPolicy.CANCEL; 
                        }
                        return NavigationActionPolicy.ALLOW;
                      },
                        onLoadStop: (controller, url) {
                          print("onLoadStop: $url, prevUrl: $prevUrl");
                          if (url != null) {
                            if (newtabUrl.isEmpty) {
                              if (url.toString().contains(
                                  "contents/empList/middleEmpList.do")) {
                                print("openBrowser: $browserUrl");
                                _webViewController.loadUrl(
                                    urlRequest:
                                        URLRequest(url: Uri.parse(prevUrl)));
                                openBrowser(browserUrl!);
                              } else {
                                print("saveUrl: $url");
                                prevUrl = url.toString();
                              }
                            } else {
                              print("ReloadUrl: $url");
                              newtabUrl = "";
                              _webViewController.loadUrl(
                                  urlRequest:
                                      URLRequest(url: Uri.parse(prevUrl)));
                            }
                          }
                        },
                        onCloseWindow: (controller) {
                          print("onCloseWindow");
                        },
                        onWebViewCreated: (InAppWebViewController controller) {
                          // print('onWebViewCreated');
                          _webViewController = controller;
                        },
                        onCreateWindow:
                            (controller, createWindowRequest) async {
                          return showDialog(
                            context: context,
                            builder: (context) {
                              return MaterialApp(
                                  home: Scaffold(
                                body: SafeArea(
                                  child: Column(
                                    children: <Widget>[
                                      Expanded(
                                          child: InAppWebView(
                                        windowId: createWindowRequest.windowId,
                                        initialOptions:
                                            InAppWebViewGroupOptions(
                                          crossPlatform: InAppWebViewOptions(
                                              javaScriptCanOpenWindowsAutomatically:
                                                  true,
                                              userAgent:
                                                  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/${snapshot.data.toString()} Safari/605.1.15 Pagecall"),
                                        ),
                                        onWebViewCreated:
                                            (InAppWebViewController
                                                controller) {
                                          print("newTab");
                                          _webViewPopupController = controller;
                                        },
                                        onLoadStart: (controller, url) {
                                          print("newtab onLoadStart: $url");
                                        },
                                        onLoadStop: (controller, url) {
                                          print("newtab onLoadStop: $url");
                                          if (url != null) {
                                            print("newtab onLoadStop2");
                                            newtabUrl = url.toString();
                                          }
                                        },
                                        onCloseWindow: (controller) {
                                          print("newtab onCloseWindow");
                                        },
                                      )),
                                      ButtonBar(
                                        alignment: MainAxisAlignment.center,
                                        children: <Widget>[
                                          ElevatedButton(
                                            child: const Icon(
                                                Icons.exit_to_app_outlined),
                                            onPressed: () async {
                                              final result =
                                                  await selectDialog();
                                              print("dialogClose: $result");
                                              if (result == "yes") {
                                                print("prev: $prevUrl");
                                                _webViewPopupController
                                                    .evaluateJavascript(
                                                        source:
                                                            'window.Pagecall.terminate()');
                                                await Future.delayed(
                                                    const Duration(seconds: 1));
                                                Navigator.pop(context);
                                              }
                                            },
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ));
                            },
                          );
                        },
                      ),
                    ),
                  ),
                );
              }
            }),
      ),
    );
  }

  Future<String> selectDialog() async {
    final result = await showDialog(
        context: context,
        //barrierDismissible - Dialog를 제외한 다른 화면 터치 x
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            // RoundedRectangleBorder - Dialog 화면 모서리 둥글게 조절
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0)),
            //Dialog Main Title
            title: Column(
              children: const <Widget>[
                Text("알림"),
              ],
            ),
            //
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const <Widget>[
                Text(
                  "현재 창에서 나가시겠어요?",
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: const Text("머무르기"),
                onPressed: () {
                  Navigator.pop(context, "cancel");
                },
              ),
              TextButton(
                child: const Text("나가기"),
                onPressed: () {
                  Navigator.pop(context, "yes");
                },
              ),
            ],
          );
        });
    return result;
  }

  void newTabCloseDialog() {}
}