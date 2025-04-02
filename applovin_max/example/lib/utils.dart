import 'package:flutter/material.dart';

class StatusBar extends StatelessWidget {
  final String statusText;

  const StatusBar({
    super.key,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // Expands to the screen width
      padding: const EdgeInsets.all(10.0), // Padding inside the banner
      color: Colors.green, // Background color of the banner
      child: Text(
        statusText,
        style: const TextStyle(fontSize: 20),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class ScrolledStatusBar extends StatefulWidget {
  final String statusText;

  const ScrolledStatusBar({
    super.key,
    required this.statusText,
  });

  @override
  State<ScrolledStatusBar> createState() => _ScrolledStatusBarState();
}

class _ScrolledStatusBarState extends State<ScrolledStatusBar> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant ScrolledStatusBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.statusText != oldWidget.statusText) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10.0),
      color: Colors.green,
      child: SizedBox(
        height: 100,
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.vertical,
          child: Text(
            widget.statusText,
            style: const TextStyle(fontSize: 20),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed; // Nullable onPressed

  const AppButton({
    super.key,
    required this.text,
    this.onPressed, // Optional onPressed
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 40, right: 40),
      child: SizedBox(
        height: 36, // Set button height
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[200],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8), // Custom border radius
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 18, // Set text font size to 18
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
