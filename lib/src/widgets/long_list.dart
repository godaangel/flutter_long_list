import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_long_list/src/widgets/multi_exposure_listener.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';
import '../store/long_list_provider.dart';
import '../utils/exposure.dart';
import './loading.dart';
import './long_list_builder.dart';
import './nomore.dart';
import './overflow_widget.dart';
import './error.dart';
import './exposure_listener.dart';

enum LongListMode {grid, list, sliver_grid, sliver_list, sliver_custom}

class LongList<T extends Clone<T>> extends StatelessWidget {
  final String id;
  final bool shrinkWrap;
  final ScrollPhysics physics;
  final LongListMode mode;
  final EdgeInsets padding;
  final double cacheExtent;
  final ScrollController controller;
  final SliverGridDelegate gridDelegate;
  final Axis scrollDirection;
  final Function(BuildContext context, LongListProvider<T> provider, String id,
      int index, T data) itemWidget;
  final Function exposureCallback;
  final Widget loading;
  final Function(bool init) nomore;
  final Widget sliverHead;
  final double sliverHeadHeight;
  final List<Widget> sliverChildren;

  final Exposure exposure = Exposure();

  LongList({
    Key key,
    this.id,
    this.shrinkWrap = false,
    this.physics,
    this.cacheExtent,
    @required this.itemWidget,
    this.mode = LongListMode.list,
    this.padding = const EdgeInsets.all(0.0),
    this.loading,
    this.nomore,
    this.controller,
    this.gridDelegate,
    this.scrollDirection = Axis.vertical,
    this.exposureCallback,
    this.sliverHead,
    this.sliverChildren,
    this.sliverHeadHeight,
  }) : assert(itemWidget != null),
    super(key: key);

  void _loadmore(BuildContext context) {
    LongListProvider<T> provider = Provider.of<LongListProvider<T>>(context, listen: false);
    if (provider.listConfig[id].hasMore && !provider.listConfig[id].hasError && !provider.listConfig[id].isLoading) {
      provider.loadMore(id);
    }
  }

  Future _onRefresh(LongListProvider<T> provider) async{
    await provider.refresh(id);
  }
  
  void _exposureCallback(BuildContext context, List<ToExposureItem> exposureList) {
    LongListProvider<T> provider = Provider.of<LongListProvider<T>>(context, listen: false);
    if (exposureList.isNotEmpty && exposureCallback != null) {
      return exposureCallback(provider, exposureList);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (mode != LongListMode.sliver_custom) {
      return ExposureListener<T>(
        id: id,
        scrollDirection: Axis.vertical,
        exposure: exposure,
        padding: padding,
        sliverHeadHeight: sliverHeadHeight,
        loadmore: () => _loadmore(context),
        callback: (exposureList) => _exposureCallback(context, exposureList),
        child: longList(context)
      );
    } else {
      return MultiExposureListener(
        scrollDirection: Axis.vertical,
        exposure: exposure,
        padding: padding,
        sliverHeadHeight: sliverHeadHeight,
        loadmore: () => _loadmore(context),
        callback: (exposureList) => _exposureCallback(context, exposureList),
        child: longList(context)
      );
    }
  }

  Widget longList(BuildContext context) {
    return GlowNotificationWidget(
      showGlowLeading: false,
      showGlowTrailing: false,
      child: Selector<LongListProvider<T>, Tuple4<int, bool, bool, bool>>(
        selector: (_, provider) => Tuple4(
          provider.list[id].length,
          provider.listConfig[id].isLoading,
          provider.listConfig[id].hasMore,
          provider.listConfig[id].hasError,
        ),
        shouldRebuild: (pre, next) => pre != next,
        builder: (_, data, __) {
          LongListProvider<T> _provider = context.read<LongListProvider<T>>();
          if (data.item1 >= 0) {
            return RefreshIndicator(
              onRefresh: () => _onRefresh(_provider),
              child: LongListBuilder(
                id: id,
                mode: mode,
                shrinkWrap: shrinkWrap,
                physics: physics,
                cacheExtent: cacheExtent,
                provider: _provider,
                controller: controller,
                scrollDirection: scrollDirection,
                gridDelegate: gridDelegate,
                padding: padding,
                itemCount: (data.item2 || !data.item3) ? data.item1 + 1 : data.item1,
                sliverHead: sliverHead,
                sliverChildren: sliverChildren,
                child: (context, index) {
                  if (!data.item3 && _provider.list[id].length == index) {
                    return LongListNoMore(
                      child: nomore
                    );
                  } else if (data.item2 && data.item1 == index) {
                    return LongListLoading(
                      position: LoadingPosition.bottom,
                      child: loading,
                    );
                  } else {
                    return Selector<LongListProvider<T>, T>(
                      shouldRebuild: (pre, next) => pre != next,
                      selector: (_, provider) => provider.list[id][index],
                      builder: (_, data, __) {
                        return itemWidget(
                          context,
                          _provider,
                          id,
                          index,
                          data.clone(),
                        );
                      }
                    );
                  }
                },
              )
            );
          } else {
            if (!data.item3) {
              return LongListNoMore(
                init: true,
                child: nomore,
              );
            } else if (data.item4) {
              return LongListError<T>(id: id);
            } else {
              return LongListLoading(
                position: LoadingPosition.center,
                child: loading,
              );
            }
          }
        }
      ),
    );
  }
}
