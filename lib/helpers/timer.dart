import 'dart:async';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ar/helpers/auth_view_model.dart';

class TimerController extends GetxController {
  static TimerController get to => Get.find();
  Timer? _timer;
  var remainingSeconds = 0.obs;
  var isTimerRunning = false.obs;
  String? _currentChallengeId;
  String? _currentUserId;
  int _initialDuration = 0;
  final AuthViewModel _authViewModel = Get.find<AuthViewModel>();

  @override
  void onInit() {
    super.onInit();
    _loadUserId();
    ever(_authViewModel.userId, (_) => _loadUserId());
  }

  Future<void> _loadUserId() async {
    _currentUserId = await _authViewModel.getIdSession();
    print('TimerController: Loaded userId: $_currentUserId');
    if (_currentUserId != null) {
      await loadTimerState();
    } else {
      await clearTimerState();
    }
  }

  bool isTimerRunningForChallenge(String challengeId) {
    final running = _timer != null && _currentChallengeId == challengeId;
    print('isTimerRunningForChallenge $challengeId: $running');
    return running;
  }

  Future<bool> isChallengePlayable(String challengeId) async {
    if (_currentUserId == null) {
      print('isChallengePlayable: No user logged in');
      return false;
    }
    final prefs = await SharedPreferences.getInstance();
    final expiryKey = 'timer_expired_$_currentUserId' '_$challengeId';
    final expiryTimestamp = prefs.getInt(expiryKey);
    final isExpired = expiryTimestamp != null && DateTime.now().millisecondsSinceEpoch ~/ 1000 > expiryTimestamp;
    final isRunning = isTimerRunningForChallenge(challengeId);
    print('isChallengePlayable $challengeId for user $_currentUserId: expired=$isExpired, isRunning=$isRunning');
    return !isExpired || (isExpired && isRunning);
  }

  void startTimer(String challengeId, int durationInSeconds) async {
    if (_currentUserId == null) {
      print('startTimer: No user logged in');
      return;
    }
    if (isTimerRunningForChallenge(challengeId)) {
      print('Timer already running for challenge $challengeId');
      return;
    }

    print('Starting timer for challenge $challengeId with $durationInSeconds seconds for user $_currentUserId');
    _currentChallengeId = challengeId;
    remainingSeconds.value = durationInSeconds;
    _initialDuration = durationInSeconds;
    isTimerRunning.value = true;

    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      if (remainingSeconds.value <= 0) {
        print('Timer finished for challenge $challengeId for user $_currentUserId');
        timer.cancel();
        _timer = null;
        _currentChallengeId = null;
        isTimerRunning.value = false;
        final prefs = await SharedPreferences.getInstance();
        final expiryKey = 'timer_expired_$_currentUserId' '_$challengeId';
        await prefs.setInt(expiryKey, DateTime.now().millisecondsSinceEpoch ~/ 1000);
        await clearTimerState();
        update();
      } else {
        remainingSeconds.value--;
        print('Timer tick: ${remainingSeconds.value} seconds remaining');
        update();
      }
    });

    await saveTimerState(challengeId, DateTime.now().millisecondsSinceEpoch ~/ 1000, durationInSeconds);
    update();
  }

  void stopTimer() async {
    print('Stopping timer for user $_currentUserId');
    _timer?.cancel();
    _timer = null;
    _currentChallengeId = null;
    remainingSeconds.value = 0;
    isTimerRunning.value = false;
    await clearTimerState();
    update();
  }

  int getRemainingSeconds() => remainingSeconds.value;
  int getInitialDuration() => _initialDuration;

  Future<void> saveTimerState(String challengeId, int startTimestamp, int duration) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('timer_challenge_id_$_currentUserId', challengeId);
    await prefs.setInt('timer_start_timestamp_$_currentUserId', startTimestamp);
    await prefs.setInt('timer_duration_$_currentUserId', duration);
    print('Timer state saved: $challengeId, $startTimestamp, $duration for user $_currentUserId');
  }

  Future<void> clearTimerState() async {
    if (_currentUserId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('timer_challenge_id_$_currentUserId');
    await prefs.remove('timer_start_timestamp_$_currentUserId');
    await prefs.remove('timer_duration_$_currentUserId');
    print('Timer state cleared for user $_currentUserId');
  }

  Future<void> loadTimerState() async {
    if (_currentUserId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final challengeId = prefs.getString('timer_challenge_id_$_currentUserId');
    final startTimestamp = prefs.getInt('timer_start_timestamp_$_currentUserId');
    final duration = prefs.getInt('timer_duration_$_currentUserId');

    if (challengeId != null && startTimestamp != null && duration != null) {
      final elapsedSeconds = (DateTime.now().millisecondsSinceEpoch ~/ 1000) - startTimestamp;
      final remaining = duration - elapsedSeconds;
      if (remaining > 0) {
        print('Restoring timer for challenge $challengeId with $remaining seconds for user $_currentUserId');
        startTimer(challengeId, remaining);
      } else {
        print('Timer expired for challenge $challengeId, marking as expired');
        final expiryKey = 'timer_expired_$_currentUserId' '_$challengeId';
        await prefs.setInt(expiryKey, startTimestamp + duration);
        await clearTimerState();
      }
    } else {
      print('No saved timer state found for user $_currentUserId');
      await clearTimerState();
    }
  }

  Future<void> clearExpiredChallenge(String challengeId) async {
    if (_currentUserId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final expiryKey = 'timer_expired_$_currentUserId' '_$challengeId';
    await prefs.remove(expiryKey);
    print('Cleared expired challenge $challengeId for user $_currentUserId');
  }

  @override
  void onClose() {
    _timer?.cancel();
    print('TimerController disposed for user $_currentUserId');
    super.onClose();
  }
}