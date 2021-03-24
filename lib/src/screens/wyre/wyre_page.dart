import 'dart:async';
import 'dart:io';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/store/dashboard/orders_store.dart';
import 'package:cake_wallet/view_model/wyre_view_model.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WyrePage extends BasePage {
  WyrePage(this.wyreViewModel,
      {@required this.ordersStore, @required this.url});

  final OrdersStore ordersStore;
  final String url;
  final WyreViewModel wyreViewModel;

  @override
  String get title => S.current.buy;

  @override
  Color get backgroundDarkColor => Colors.white;

  @override
  Color get titleColor => Palette.darkBlueCraiola;

  @override
  Widget body(BuildContext context) =>
      WyrePageBody(wyreViewModel, ordersStore: ordersStore, url: url);
}

class WyrePageBody extends StatefulWidget {
  WyrePageBody(this.wyreViewModel, {this.ordersStore, this.url});

  final OrdersStore ordersStore;
  final String url;
  final WyreViewModel wyreViewModel;

  @override
  WyrePageBodyState createState() => WyrePageBodyState();
}

class WyrePageBodyState extends State<WyrePageBody> {
  String orderId;
  WebViewController _webViewController;
  GlobalKey _webViewkey;
  Timer _timer;
  bool _isSaving;

  @override
  void initState() {
    super.initState();
    _webViewkey = GlobalKey();
    _isSaving = false;
    widget.ordersStore.orderId = '';

    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();

    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) async {

      try {
        if (_webViewController == null || _isSaving) {
          return;
        }

        final url = await _webViewController.currentUrl();

        if (url.contains('completed')) {
          final urlParts = url.split('/');
          orderId = urlParts.last;
          widget.ordersStore.orderId = orderId;

          if (orderId.isNotEmpty) {
            _isSaving = true;
            await widget.wyreViewModel.saveOrder(orderId);
            timer.cancel();
          }
        }
      } catch (e) {
        _isSaving = false;
        print(e);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WebView(
        key: _webViewkey,
        initialUrl: widget.url,
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (WebViewController controller) =>
            setState(() => _webViewController = controller));
  }
}
