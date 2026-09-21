import 'package:flutter/material.dart';

import '../theme/prairie_theme.dart';

/// アートグラス（装飾ガラス窓）を思わせる幾何パターンの帯。
///
/// 縦の方立と横の桟を直交させ、交点に色ガラスの小片を置く構成は、
/// ライトが「Tree of Life」などの窓で用いた直線構成に倣ったもの。
class ArtGlassBanner extends StatelessWidget {
  const ArtGlassBanner({super.key, this.height = 88});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _ArtGlassPainter()),
    );
  }
}

class _ArtGlassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final u = h / 4; // 基準モジュール。線の位置はすべてこの倍数に載る。

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = PrairieColors.sand,
    );

    final thin = Paint()
      ..color = PrairieColors.stone
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final came = Paint()
      ..color = PrairieColors.ink.withValues(alpha: 0.55)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    // 二本の横桟。プレーリー様式の水平性を担う主役で、全幅を貫く。
    canvas.drawLine(Offset(0, u), Offset(w, u), came);
    canvas.drawLine(Offset(0, u * 3), Offset(w, u * 3), thin);

    // 窓の一間（ベイ）を単位に、縦の方立を非対称に配する。
    // 等間隔の反復ではなく、長短と粗密の対比で律動を作るのがライトの手法。
    final bay = w / 6;
    const accents = [
      PrairieColors.cherokee,
      PrairieColors.ochre,
      PrairieColors.moss,
    ];
    for (var i = 0; i < 6; i++) {
      final x0 = bay * i;

      // 各間の始まりに通し柱を立て、二本の横桟と直交させる。
      canvas.drawLine(Offset(x0, 0), Offset(x0, h), thin);

      // 横桟の間だけを繋ぐ短い方立。梯子状の密な部分を作る。
      canvas.drawLine(
        Offset(x0 + bay * 0.34, u),
        Offset(x0 + bay * 0.34, u * 3),
        came,
      );
      canvas.drawLine(
        Offset(x0 + bay * 0.5, u),
        Offset(x0 + bay * 0.5, u * 3),
        thin,
      );
      canvas.drawLine(
        Offset(x0 + bay * 0.66, u),
        Offset(x0 + bay * 0.66, u * 3),
        came,
      );

      // 色ガラスの小片は上の横桟の上下に振り分け、左右非対称に置く。
      final accent = accents[i % accents.length];
      final s = u * 0.52;
      canvas.drawRect(
        Rect.fromLTWH(x0 + bay * 0.34, u - s, s, s),
        Paint()..color = accent,
      );
      if (i.isEven) {
        canvas.drawRect(
          Rect.fromLTWH(x0 + bay * 0.66 - s * 0.6, u * 3, s * 0.6, s * 0.6),
          Paint()..color = PrairieColors.ochre,
        );
      }
    }

    // 最下部の地の帯。建物を大地に据える基壇にあたる。
    canvas.drawRect(
      Rect.fromLTWH(0, h - 3, w, 3),
      Paint()..color = PrairieColors.cherokee,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 見出し。方形の小片と、太さの異なる二本の水平線が交差する。
class PrairieSectionHeader extends StatelessWidget {
  const PrairieSectionHeader(
    this.title, {
    super.key,
    this.accent = PrairieColors.cherokee,
    this.subtitle,
  });

  final String title;
  final Color accent;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 10, height: 10, color: accent),
            const SizedBox(width: 10),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(width: 16),
            // 細い線の上に太い帯を重ね、線が交差する層を作る。
            Expanded(
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(height: 1, color: PrairieColors.stone),
                  Container(height: 3, width: 44, color: accent),
                ],
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(subtitle!, style: theme.textTheme.bodySmall),
          ),
        ],
      ],
    );
  }
}

/// 一覧の行。左辺の縦帯が下辺の罫線と直角に交わる。
class PrairieTile extends StatelessWidget {
  const PrairieTile({
    super.key,
    required this.child,
    this.accent = PrairieColors.ochre,
    this.accentWidth = 5,
  });

  final Widget child;
  final Color accent;
  final double accentWidth;

  @override
  Widget build(BuildContext context) {
    // 背景色は Material に持たせる。DecoratedBox に色を置くと
    // 子の ListTile のインク効果が隠れてしまうため。
    return Material(
      color: PrairieColors.parchment,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: accent, width: accentWidth),
            bottom: const BorderSide(color: PrairieColors.stone),
          ),
        ),
        child: child,
      ),
    );
  }
}

/// 上辺に帯を渡した矩形の面。帯と側面の線が角で交差する。
class PrairieCard extends StatelessWidget {
  const PrairieCard({
    super.key,
    required this.child,
    this.accent = PrairieColors.cherokee,
    this.background = PrairieColors.parchment,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final Color accent;
  final Color background;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: PrairieColors.stone),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 4, color: accent),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

/// 層をなす水平の仕切り。太い短線と細い長線を重ねる。
class PrairieRule extends StatelessWidget {
  const PrairieRule({super.key, this.accent = PrairieColors.ochre});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        Container(height: 1, color: PrairieColors.stone),
        Container(height: 3, width: 56, color: accent),
      ],
    );
  }
}
