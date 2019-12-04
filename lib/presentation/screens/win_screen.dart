import 'package:flutter/material.dart';

import 'package:matchymatchy/domain/domain.dart';

class WinScreen extends StatefulWidget {
  final int moves;
  final String matchId;

  WinScreen({this.moves, this.matchId});

  @override
  State<StatefulWidget> createState() {
    return _WinState();
  }
}

class _WinState extends State<WinScreen> with TickerProviderStateMixin {
  WinBloc bloc;

  @override
  void initState() {
    super.initState();
    bloc = BlocProvider.of<WinBloc>(context);
    widget.matchId == null
        ? bloc.emitEvent(WinEvent.single(widget.moves))
        : bloc.emitEvent(WinEvent.multi(widget.matchId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[200],
      appBar: AppBar(
        leading: BackButton(color: Colors.white),
        backgroundColor: Colors.transparent,
        elevation: 0.0,
      ),
      body: BlocEventStateBuilder<WinEvent, WinState>(
        bloc: bloc,
        builder: (context, state) {
          switch (state.type) {
            case WinStateType.waitingForOpp:
              return Center(
                child: Text(
                  'waiting for opponent to end',
                ),
              );
              break;
            case WinStateType.winnerDeclared:
              return Center(
                child: Text('winner: ' + state.winner),
              );
              break;
            default:
              return Container();
          }
        },
      ),
    );
  }
}
