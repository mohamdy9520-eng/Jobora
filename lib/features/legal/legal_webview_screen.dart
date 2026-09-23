// lib/features/legal/legal_webview_screen.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/localization/app_localizations.dart';

class LegalWebViewScreen extends StatefulWidget {
  const LegalWebViewScreen({
    super.key,
    required this.baseUrl,
    required this.titleKey,
    this.actions,
  });

  /// The page URL WITHOUT the lang query param — this widget appends
  /// `?lang=<current app locale>` itself, so every caller stays in sync
  /// automatically instead of building the query string manually.
  final String baseUrl;
  final String titleKey;
  final List<Widget>? actions;

  @override
  State<LegalWebViewScreen> createState() => _LegalWebViewScreenState();
}

class _LegalWebViewScreenState extends State<LegalWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  bool _hasLoadedOnce = false;

  String _fullUrl(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final separator = widget.baseUrl.contains('?') ? '&' : '?';
    return '${widget.baseUrl}${separator}lang=$lang';
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() {
            _isLoading = true;
            _hasError = false;
          }),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (_) => setState(() {
            _isLoading = false;
            _hasError = true;
          }),
        ),
      );
    // Localizations.localeOf(context) needs an InheritedWidget lookup,
    // which isn't safe to do inside initState() — didChangeDependencies()
    // is the correct place, and it also re-fires if the app locale
    // changes later while this screen is on screen.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoadedOnce) {
      _hasLoadedOnce = true;
      _controller.loadRequest(Uri.parse(_fullUrl(context)));
    }
  }

  void _retry() {
    _controller.loadRequest(Uri.parse(_fullUrl(context)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(widget.titleKey)),
        actions: widget.actions,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            if (_hasError)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(context.tr('legal_error_loading')),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: _retry, child: Text(context.tr('retry'))),
                  ],
                ),
              )
            else
              WebViewWidget(controller: _controller),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}