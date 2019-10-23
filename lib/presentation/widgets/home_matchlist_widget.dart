import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:squazzle/data/models/models.dart';
import 'package:squazzle/domain/domain.dart';
import 'matchlist_item.dart';

class HomeMatchListWidget extends StatefulWidget {
  HomeMatchListWidget({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _HomeMatchListWidgetState();
  }
}

class _HomeMatchListWidgetState extends State<HomeMatchListWidget>
    with AutomaticKeepAliveClientMixin<HomeMatchListWidget> {
  final GlobalKey<AnimatedListState> listKey = GlobalKey();
  final List<dynamic> matchList = List<dynamic>();
  final List<String> provaList = ['ahah', 'hola'];
  HomeMatchListBloc bloc;

  @override
  void initState() {
    bloc = BlocProvider.of<HomeMatchListBloc>(context);
    bloc.setup();
    bloc.emitEvent(HomeMatchListEvent(type: HomeMatchListEventType.start));
    bloc.matches.listen((matches) => _addMatches(matches));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Expanded(
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        child: BlocEventStateBuilder<HomeMatchListEvent, HomeMatchListState>(
          bloc: bloc,
          builder: (context, state) {
            switch (state.type) {
              case HomeMatchListStateType.init:
                _addMatches(state.activeMatches);
                _addMatches(state.pastMatches);
                return init();
                break;
              case HomeMatchListStateType.fetching:
                return fetching();
                break;
              case HomeMatchListStateType.empty:
                return empty();
                break;
              case HomeMatchListStateType.error:
                return Center(
                  child: Text(state.message,
                      style: TextStyle(color: Colors.blue[300])),
                );
                break;
              default:
                return Container();
            }
          },
        ),
      ),
    );
  }

  Future<Null> _onRefresh() async {
    matchList.clear();
    bloc.emitEvent(
        HomeMatchListEvent(type: HomeMatchListEventType.updateMatches));
  }

  Widget init() {
    return AnimatedList(
      key: listKey,
      initialItemCount: provaList.length,
      itemBuilder: (context, index, animation) {
        return _buildItemProva(provaList[index], animation);
      },
    );
  }

  Widget _buildItem(dynamic item, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: item is ActiveMatch
          ? activeItem(item)
          : PastMatchItem(pastMatch: item, user: bloc.user),
    );
  }

  Widget _buildItemProva(String ahah, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: Text(ahah),
    );
  }

  void _addprova() {
    provaList.add('eheh');
    listKey.currentState.insertItem(0);
  }

  void _addMatches(List<dynamic> matches) {
    matchList.addAll(matches);
    for (int offset = 0; offset < matches.length; offset++) {
      listKey.currentState.insertItem(0 + offset);
    }
  }

  void _removeMatch(int index) {
    var removedItem = matchList.removeAt(index);
    AnimatedListRemovedItemBuilder builder = (context, animation) {
      return _buildItem(removedItem, animation);
    };
    listKey.currentState.removeItem(index, builder);
  }

  void _removeMatches() {
    for (int i = 0; i < matchList.length; i++) {
      var removedItem = matchList.removeAt(0);
      AnimatedListRemovedItemBuilder builder = (context, animation) {
        return _buildItem(removedItem, animation);
      };
      listKey.currentState.removeItem(0, builder);
    }
  }

  Widget activeItem(ActiveMatch activeMatch) {
    return StreamBuilder<bool>(
      initialData: false,
      stream: bloc.connChange,
      builder: (context, snapshot) {
        return ActiveMatchItem(
            activeMatch: activeMatch, isOnline: snapshot.data);
      },
    );
  }

  Widget fetching() {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SpinKitRotatingPlain(
            color: Colors.blue[100],
            size: 60.0,
          ),
          SizedBox(height: 40),
          Text(
            'retrieving matches...',
            style: TextStyle(
                color: Colors.blue[300],
                fontSize: 15,
                fontWeight: FontWeight.w400,
                letterSpacing: 2.0),
          ),
          SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget empty() {
    return Center(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'no active nor past matches stored',
              style: TextStyle(
                  color: Colors.blue[300],
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 2.0),
            ),
            SizedBox(height: 60),
          ]),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
