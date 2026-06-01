import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Cashfree Checkout Screen using the Cashfree JS SDK via WebView.
///
/// The Cashfree JS SDK requires the `payment_session_id` to open the
/// production hosted checkout. Opening `payments.cashfree.com/order/#<session_id>`
/// does NOT work because that URL only accepts the old `order_token` format.
class CashfreeCheckoutScreen extends StatefulWidget {
  final String paymentSessionId;
  final String orderId;
  final void Function(bool success, String orderId) onPaymentResult;

  const CashfreeCheckoutScreen({
    super.key,
    required this.paymentSessionId,
    required this.orderId,
    required this.onPaymentResult,
  });

  @override
  State<CashfreeCheckoutScreen> createState() => _CashfreeCheckoutScreenState();
}

class _CashfreeCheckoutScreenState extends State<CashfreeCheckoutScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _paymentResultHandled = false;

  // The return URL set in the Cashfree order — lovebug.live domain is whitelisted
  static const String _returnUrlBase = 'https://www.lovebug.live/payment-success';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) {
          if (url.startsWith(_returnUrlBase)) {
            _handlePaymentReturn(url);
          }
        },
        onNavigationRequest: (NavigationRequest request) {
          final url = request.url;
          // Intercept lovebug.live return URL
          if (url.startsWith(_returnUrlBase)) {
            _handlePaymentReturn(url);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
        onPageFinished: (url) {
          setState(() => _isLoading = false);
        },
        onWebResourceError: (WebResourceError error) {
          print('WebView error: ${error.description}');
        },
      ))
      ..loadHtmlString(_buildCheckoutHtml());
  }

  String _buildCheckoutHtml() {
    final sessionId = widget.paymentSessionId;
    final orderId = widget.orderId;
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>LoveBug Payment</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      background: #0a0a0a;
      color: #fff;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
    }
    .spinner {
      width: 48px; height: 48px;
      border: 4px solid rgba(255,255,255,0.15);
      border-top-color: #e91e63;
      border-radius: 50%;
      animation: spin 0.9s linear infinite;
      margin-bottom: 20px;
    }
    @keyframes spin { to { transform: rotate(360deg); } }
    .msg { font-size: 16px; color: rgba(255,255,255,0.7); text-align: center; padding: 0 32px; }
    .logo { font-size: 28px; font-weight: 700; margin-bottom: 32px; color: #e91e63; }
  </style>
</head>
<body>
  <div class="logo">💖 LoveBug</div>
  <div class="spinner"></div>
  <div class="msg">Opening secure payment page…</div>

  <!-- Cashfree Production JS SDK -->
  <script src="https://sdk.cashfree.com/js/v3/cashfree.js"></script>
  <script>
    window.addEventListener('load', function () {
      try {
        const cashfree = Cashfree({ mode: "production" });
        cashfree.checkout({
          paymentSessionId: "$sessionId",
          redirectTarget: "_self",   // Redirect inside this WebView
        }).then(function (result) {
          if (result.error) {
            console.error("Cashfree checkout error:", JSON.stringify(result.error));
            window.location.href =
              "https://www.lovebug.live/payment-success?order_id=$orderId&status=FAILED";
          } else if (result.redirect) {
            // Payment is processing / redirecting — normal
            console.log("Cashfree redirecting...");
          }
        }).catch(function (err) {
          console.error("Checkout exception:", err);
          window.location.href =
            "https://www.lovebug.live/payment-success?order_id=$orderId&status=FAILED";
        });
      } catch (e) {
        console.error("Cashfree init error:", e);
      }
    });
  </script>
</body>
</html>
''';
  }

  void _handlePaymentReturn(String url) {
    if (_paymentResultHandled) return;
    _paymentResultHandled = true;

    print('🔄 Payment return URL received: $url');

    final uri = Uri.tryParse(url);
    final status = uri?.queryParameters['status']?.toUpperCase() ?? '';

    // A FAILED status in the URL means explicit failure. Everything else
    // (or no status param) means the user came back — verify server-side.
    final likelySuccess = status != 'FAILED';

    if (mounted) {
      Navigator.of(context).pop();
      widget.onPaymentResult(likelySuccess, widget.orderId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Secure Payment',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            if (!_paymentResultHandled) {
              _paymentResultHandled = true;
              Navigator.of(context).pop();
              widget.onPaymentResult(false, widget.orderId);
            }
          },
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFFE91E63)),
                  SizedBox(height: 16),
                  Text(
                    'Loading payment…',
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
