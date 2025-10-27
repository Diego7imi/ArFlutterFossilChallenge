import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../helpers/timer.dart';
import '../widgets/costanti.dart';

class TimerWidget extends StatelessWidget {
  const TimerWidget({super.key});

  /// Funzione di utilità che formatta un valore temporale espresso in secondi
  /// nel formato "minuti:secondi", ad esempio:
  ///   125 secondi -> "2:05"
  ///
  /// Viene usata per mostrare in modo leggibile il tempo rimanente nel timer.
  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// Metodo principale che costruisce l’interfaccia grafica del widget del timer.
  /// Il widget è reattivo grazie a `Obx` (di GetX), quindi si aggiorna automaticamente
  /// ogni volta che cambia uno stato osservabile nel `TimerController`.
  ///
  /// Mostra una barra di avanzamento e il tempo rimanente formattato.
  /// Quando il timer non è in esecuzione, non mostra nulla (usa `SizedBox.shrink()`).
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = TimerController.to;
      print('TimerWidget: Building with isTimerRunning=${controller.isTimerRunning.value}');
      if (!controller.isTimerRunning.value) {
        print('TimerWidget: Timer not running, returning SizedBox.shrink');
        return const SizedBox.shrink();
      }

      print('TimerWidget: Rendering progress bar with ${controller.remainingSeconds.value} seconds');
      double progress = controller.remainingSeconds.value / controller.getInitialDuration();

      return Container(
        margin: const EdgeInsets.only(bottom: 6, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        decoration: BoxDecoration(
          color: marrone!.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tempo rimanente: ${_formatTime(controller.remainingSeconds.value)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontFamily: 'PlayfairDisplay',
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
          ],
        ),
      );
    });
  }
}