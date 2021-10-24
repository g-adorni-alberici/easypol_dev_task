import 'package:flutter/material.dart';

///Schermata di errore
class ErrorScreen extends StatelessWidget {
  const ErrorScreen({Key? key, required this.error, this.onRetry})
      : super(key: key);

  final String error;
  final Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.report_problem_outlined, size: 96),
          const SizedBox(height: 32),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 32),
          if (onRetry != null)
            OutlinedButton(onPressed: onRetry, child: const Text('RETRY'))
        ],
      ),
    );
  }
}
