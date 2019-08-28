import 'package:squazzle/data/data.dart';
import 'game_repo.dart';

/// MultiBloc's repository.
class MultiRepo extends GameRepo {
  final ApiProvider apiProvider;
  final MessagingEventBus messProvider;

  MultiRepo(this.apiProvider, this.messProvider, LogicProvider logicProvider,
      DbProvider dbProvider, SharedPrefsProvider prefsProvider)
      : super(
            logicProvider: logicProvider,
            dbProvider: dbProvider,
            prefsProvider: prefsProvider);

  @override
  Future<bool> moveDone(GameField gameField, TargetField targetField) async {
    var need = logicProvider.needToSendMove(gameField, targetField);
    if (need) {
      await prefsProvider.storeGf(gameField);
      await prefsProvider
          .storeTarget(logicProvider.diffToSend(gameField, targetField));
      Session session = await prefsProvider.getSession();
      bool isCorrect =
          await logicProvider.checkIfCorrect(gameField, targetField);
      await apiProvider.sendMove(session, isCorrect);
    }
    return logicProvider.checkIfCorrect(gameField, targetField);
  }

  Future<bool> forfeit() async {
    var userId = await prefsProvider.getUid();
    var matchId = await prefsProvider.getMatchId();
    return apiProvider.sendForfeit(userId, matchId);
  }

  Future<MatchOnline> queuePlayer() async {
    await prefsProvider.restoreMoves();
    String uid = await prefsProvider.getUid();
    String token = await messProvider.getToken();
    MatchOnline situation = await apiProvider.queuePlayer(uid, token);
    if (situation.started == 1) {
      prefsProvider.storeMoves(situation.moves); // delete
      prefsProvider.storeMatchId(situation.matchId); // delete
      dbProvider.storeActiveMatch(situation);
    }
    return situation;
  }

  void storeMatchId(String matchId) => prefsProvider.storeMatchId(matchId);
}
