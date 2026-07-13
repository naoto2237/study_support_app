import 'package:flutter/material.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Duration goalTime = const Duration(hours: 3);
  Duration todayTotal = Duration.zero;

  double get progress =>
      todayTotal.inSeconds / goalTime.inSeconds;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ホーム")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                child: StopwatchWidget(
                  onStop: (time) {
                    setState(() {
                      todayTotal += time;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 30),

            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "🎯 今日の目標",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "${goalTime.inHours}時間${goalTime.inMinutes % 60}分",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),

                    const SizedBox(height: 25),

                    const Text(
                      "📈 達成率",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(10),
                    ),

                    const SizedBox(height: 10),

                    Align(
                      alignment: Alignment.centerRight,
                      child: Text("${(progress * 100).toStringAsFixed(0)}%",),
                    ),

                    const SizedBox(height: 25),

                    const Text(
                      "今日の累計",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "${todayTotal.inHours}時間${todayTotal.inMinutes % 60}分",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}


class StopwatchWidget extends StatefulWidget {

  final Function(Duration) onStop;

  const StopwatchWidget({
    super.key,
    required this.onStop,
  });

  @override
  State<StopwatchWidget> createState() => _StopwatchWidgetState();
}

class _StopwatchWidgetState extends State<StopwatchWidget> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;

  void _start() {
    if (_stopwatch.isRunning) return;

    _stopwatch.start();

    _timer = Timer.periodic(
      const Duration(milliseconds: 100),
          (_) {
        setState(() {});
      },
    );
  }

  void _stop() {
    _stopwatch.stop();
    _timer?.cancel();

    widget.onStop(_stopwatch.elapsed);
  }

  void _reset() {
    _stop();
    _stopwatch.reset();
    setState(() {});
  }

  String _formatTime() {
    final elapsed = _stopwatch.elapsed;

    final hours = elapsed.inHours.toString().padLeft(2, '0');
    final minutes =
    (elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final seconds =
    (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    final milliseconds =
    (elapsed.inMilliseconds % 1000 ~/ 100).toString();

    return "$hours:$minutes:$seconds.$milliseconds";
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTime(),
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _start,
              child: const Text("開始"),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _stop,
              child: const Text("停止"),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _reset,
              child: const Text("リセット"),
            ),
          ],
        ),
      ],
    );
  }
}

