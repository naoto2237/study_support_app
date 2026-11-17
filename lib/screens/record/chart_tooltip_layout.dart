// ======================================================================
// 【部品】グラフの吹き出しの置き場所
//
// 主なクラス: ChartTooltipLayoutDelegate
// 使う場所: 学習記録の推移（study_time_chart_section.dart）、
//           学習時間の比較グラフ（comparison_chart_section.dart）
// ・押した位置の少し上（指でかくれない）に、吹き出しのまん中が来るようにする
// ・左右はグラフの外にはみ出さないようにおさめる。上は、グラフの上にはみ出してもよい
// ・グラフの部品の吹き出しは棒のてっぺんにしか出せないので、
//   吹き出しは各グラフで自分で作り、この部品で置き場所を決める
// ======================================================================

import 'package:flutter/widgets.dart';

class ChartTooltipLayoutDelegate extends SingleChildLayoutDelegate {
  // 押している位置（グラフ全体の左上から数えた座標）
  final Offset touchPosition;

  // 指の先と吹き出しのすき間
  static const double gap = 40;

  ChartTooltipLayoutDelegate(this.touchPosition);

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return constraints.loosen();
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final maxLeft = (size.width - childSize.width).clamp(0.0, double.infinity);
    final left = (touchPosition.dx - childSize.width / 2).clamp(0.0, maxLeft);
    final top = touchPosition.dy - childSize.height - gap;

    return Offset(left, top);
  }

  @override
  bool shouldRelayout(ChartTooltipLayoutDelegate oldDelegate) {
    return oldDelegate.touchPosition != touchPosition;
  }
}
