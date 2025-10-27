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

  /// Carica l'ID utente attualmente loggato e gestisce lo stato del timer.
  ///
  /// Funzionamento:
  /// - Recupera l'`userId` corrente tramite `_authViewModel.getIdSession()`.
  /// - Se l’utente è autenticato (`_currentUserId != null`), carica eventuali
  ///   dati del timer salvati in precedenza (`loadTimerState()`).
  /// - Se nessun utente è loggato, pulisce lo stato locale del timer (`clearTimerState()`).
  Future<void> _loadUserId() async {
    _currentUserId = await _authViewModel.getIdSession();
    print('TimerController: Loaded userId: $_currentUserId');
    if (_currentUserId != null) {
      await loadTimerState();
    } else {
      await clearTimerState();
    }
  }

  /// Verifica se il timer è attualmente in esecuzione per una specifica challenge.
  ///
  /// Funzionamento:
  /// - Controlla che l’oggetto `_timer` non sia `null`
  ///   (quindi che un timer sia effettivamente attivo)
  ///   e che `_currentChallengeId` coincida con l’`id` fornito.
  /// - Ritorna `true` se il timer in corso è relativo a quella challenge,
  ///   altrimenti `false`.
  bool isTimerRunningForChallenge(String challengeId) {
    final running = _timer != null && _currentChallengeId == challengeId;
    print('isTimerRunningForChallenge $challengeId: $running');
    return running;
  }

  /// Verifica se una challenge è giocabile per l’utente corrente.
  ///
  /// Funzionamento:
  /// - Se l’utente non è loggato (`_currentUserId == null`), ritorna `false`.
  /// - Recupera dai `SharedPreferences` il timestamp di scadenza
  ///   associato alla challenge e all’utente.
  /// - Determina se la challenge è **scaduta** confrontando il tempo corrente
  ///   con quello memorizzato.
  /// - Se il timer è ancora in corso o la challenge non è scaduta,
  ///   la funzione ritorna `true`, consentendo di giocare.
  ///
  /// Serve a impedire che un utente riavvii una challenge già scaduta.
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

  /// Avvia un timer associato a una specifica challenge.
  ///
  /// Funzionamento:
  /// - Controlla che un utente sia loggato e che non ci sia già un timer attivo
  ///   per la stessa challenge.
  /// - Imposta i valori iniziali (`remainingSeconds`, `_initialDuration`, ecc.)
  ///   e aggiorna lo stato.
  /// - Crea un `Timer.periodic` che ogni secondo:
  ///   - Decrementa i secondi rimanenti.
  ///   - Aggiorna la UI o i listener.
  ///   - Quando il tempo scade:
  ///     - Ferma il timer.
  ///     - Registra la scadenza nei `SharedPreferences`.
  ///     - Pulisce lo stato del timer (`clearTimerState()`).
  ///
  /// Inoltre, salva immediatamente lo stato iniziale del timer
  /// (challenge, timestamp e durata) in modo da poterlo ripristinare
  /// se l’app viene chiusa.
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

  /// Interrompe manualmente il timer corrente.
  ///
  /// Funzionamento:
  /// - Cancella il timer in corso (se presente).
  /// - Reimposta le variabili di stato (`_timer`, `_currentChallengeId`,
  ///   `remainingSeconds`, `isTimerRunning`).
  /// - Elimina i dati salvati del timer dai `SharedPreferences`.
  /// - Aggiorna lo stato per riflettere la modifica.
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


  /// Restituisce i secondi rimanenti per il timer in corso.
  int getRemainingSeconds() => remainingSeconds.value;
  /// Restituisce la durata iniziale impostata al momento dell’avvio del timer.
  int getInitialDuration() => _initialDuration;

  /// Salva lo stato corrente del timer nei `SharedPreferences`.
  ///
  /// Funzionamento:
  /// - Memorizza l’ID della challenge, il timestamp di avvio e la durata.
  /// - Queste informazioni vengono utilizzate da `loadTimerState()`
  ///   per ripristinare il timer se l’app viene riaperta.
  /// - I dati sono salvati in chiavi personalizzate per utente.
  Future<void> saveTimerState(String challengeId, int startTimestamp, int duration) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('timer_challenge_id_$_currentUserId', challengeId);
    await prefs.setInt('timer_start_timestamp_$_currentUserId', startTimestamp);
    await prefs.setInt('timer_duration_$_currentUserId', duration);
    print('Timer state saved: $challengeId, $startTimestamp, $duration for user $_currentUserId');
  }

  /// Pulisce completamente lo stato salvato del timer per l’utente corrente.
  ///
  /// Funzionamento:
  /// - Cancella tutte le chiavi salvate nei `SharedPreferences`
  ///   relative al timer dell’utente.
  /// - Utilizzato sia quando il timer termina naturalmente,
  ///   sia quando l’utente viene disconnesso.
  Future<void> clearTimerState() async {
    if (_currentUserId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('timer_challenge_id_$_currentUserId');
    await prefs.remove('timer_start_timestamp_$_currentUserId');
    await prefs.remove('timer_duration_$_currentUserId');
    print('Timer state cleared for user $_currentUserId');
  }


  /// Carica lo stato del timer dai `SharedPreferences` se esiste.
  ///
  /// Funzionamento:
  /// - Verifica la presenza di un timer salvato per l’utente corrente.
  /// - Se trova dati validi (`challengeId`, `startTimestamp`, `duration`):
  ///   - Calcola quanti secondi sono passati dal momento dell’avvio.
  ///   - Se il tempo non è ancora scaduto, riavvia automaticamente il timer
  ///     con i secondi rimanenti.
  ///   - Se il tempo è scaduto, marca la challenge come “scaduta”
  ///     e pulisce i dati salvati.
  /// - Se non trova dati validi, pulisce eventuali residui.
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

  /// Rimuove la chiave di scadenza per una specifica challenge.
  ///
  /// Funzionamento:
  /// - Elimina dai `SharedPreferences` la voce `timer_expired_*`
  ///   associata a quell’utente e challenge.
  /// - Serve per “resettare” una challenge scaduta, permettendo
  ///   eventualmente di rigiocarla.
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