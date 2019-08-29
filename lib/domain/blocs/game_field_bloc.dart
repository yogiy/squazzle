import 'package:rxdart/rxdart.dart';

import 'package:squazzle/data/models/models.dart';
import 'package:squazzle/domain/domain.dart';
import 'game_bloc.dart';

/// GameFieldWidget's bloc.
class GameFieldBloc extends BlocEventStateBase<WidgetEvent, WidgetState> {
  final GameBloc _gameBloc;

  // Update GameField after every move
  final _gameFieldSubject = BehaviorSubject<GameField>();
  Stream<GameField> get gameField => _gameFieldSubject.stream;

  // Receive move coordinates from user move
  final _moveSubject = PublishSubject<List<int>>();
  Sink<List<int>> get move => _moveSubject.sink;

  GameFieldBloc(this._gameBloc);

  void setup() {
    _moveSubject.listen(_applyMove);
  }

  void _applyMove(List<int> list) async {
    Move move = Move(from: list[0], dir: list[1]);
    GameField newField =
        await _gameBloc.gameRepo.applyMove(_gameBloc.gameField, move);
    _gameBloc.gameField = newField;
    _gameFieldSubject.add(newField);
    _gameBloc.moveNumberSubject.add(await _gameBloc.gameRepo.getMoves());
    bool isCorrect = await _gameBloc.gameRepo
        .moveDone(_gameBloc.gameField, _gameBloc.targetField);
    if (isCorrect) _gameBloc.emitEvent(GameEvent(type: GameEventType.victory));
  }

  @override
  Stream<WidgetState> eventHandler(
      WidgetEvent event, WidgetState currentState) async* {
    if (event.type == WidgetEventType.start) {
      _gameFieldSubject.add(_gameBloc.gameField);
    }
  }

  @override
  void dispose() {
    _gameFieldSubject.close();
    _moveSubject.close();
    super.dispose();
  }
}
