import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class LongListNoMore extends StatelessWidget {
  final bool init;
  final Function(bool init) child;
  const LongListNoMore({this.init = false, this.child, Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return child != null ? child(init) : Container(
      alignment: Alignment.center,
      padding: EdgeInsets.only(top: 40, bottom: 40),
      child: Text(
        init ? '暂无相关内容' : '已经到底了',
        style: TextStyle(
          color: Colors.black.withOpacity(0.5),
          fontWeight: FontWeight.bold,
          fontSize: 13
        )
      )
    );
  }
}