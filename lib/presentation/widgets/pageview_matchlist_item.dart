import 'package:flutter/material.dart';
import 'package:kiwi/kiwi.dart' as kiwi;

import 'package:squazzle/presentation/screens/multi_screen.dart';
import 'package:squazzle/data/models/models.dart';
import 'package:squazzle/domain/domain.dart';

abstract class MatchListItem {}

class ActiveMatchItem extends StatefulWidget implements MatchListItem {
  final ActiveMatch activeMatch;

  ActiveMatchItem(this.activeMatch);

  @override
  State<StatefulWidget> createState() {
    return _ActiveMatchItemState();
  }
}

class _ActiveMatchItemState extends State<ActiveMatchItem> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      child: Hero(
        tag: widget.activeMatch.matchId,
        child: GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                child: MultiScreen(widget.activeMatch.matchId),
                bloc: kiwi.Container().resolve<MultiBloc>(),
              ),
            ),
          ),
          child: Card(
            color: Colors.blue[200],
            child: Text(widget.activeMatch.gfid.toString(),
                style: TextStyle(color: Colors.black)),
          ),
        ),
      ),
    );
  }
}

class PastMatchItem extends StatefulWidget implements MatchListItem {
  final PastMatch pastMatch;

  PastMatchItem(this.pastMatch);

  @override
  State<StatefulWidget> createState() {
    return _PastMatchItemState();
  }
}

class _PastMatchItemState extends State<PastMatchItem> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Text('past' + widget.pastMatch.moves.toString(),
          style: TextStyle(color: Colors.black)),
    );
  }
}
