import 'package:flutter/material.dart';

/// フランク・ロイド・ライトのプレーリー様式に着想を得た配色。
///
/// 大地・草原・陽光といった自然素材の色を基調とし、
/// 差し色にはライトが自邸や家具に繰り返し用いた「チェロキーレッド」を置く。
abstract final class PrairieColors {
  /// チェロキーレッド。ライトの象徴色で、主要な差し色として使う。
  static const Color cherokee = Color(0xFF9E3B26);

  /// タリアセンの土壁を思わせる黄土色。第二の差し色。
  static const Color ochre = Color(0xFFBE8A32);

  /// 草原の緑。正解の表示に使う。
  static const Color moss = Color(0xFF4E6B4F);

  /// 焼き締めた煉瓦の色。不正解の表示に使う。
  static const Color brick = Color(0xFF8C2F1B);

  /// 墨のような焦げ茶。文字色。
  static const Color ink = Color(0xFF2B2722);

  /// 石材の目地。罫線・境界線の色。
  static const Color stone = Color(0xFFCCC0A9);

  /// 砂。面を一段沈める際の背景色。
  static const Color sand = Color(0xFFF0E9DA);

  /// 羊皮紙。基調となる背景色。
  static const Color parchment = Color(0xFFFAF7EF);
}

/// プレーリー様式の直線性を保つため、角丸は一切使わない。
const RoundedRectangleBorder kSquareBorder = RoundedRectangleBorder(
  borderRadius: BorderRadius.zero,
);

/// 水平線を強調するための基準モジュール（軒の出のような一定間隔）。
const double kPrairieUnit = 8.0;

ThemeData buildPrairieTheme() {
  final seeded = ColorScheme.fromSeed(
    seedColor: PrairieColors.cherokee,
    brightness: Brightness.light,
  );
  final scheme = seeded.copyWith(
    primary: PrairieColors.cherokee,
    onPrimary: PrairieColors.parchment,
    secondary: PrairieColors.ochre,
    onSecondary: PrairieColors.ink,
    tertiary: PrairieColors.moss,
    onTertiary: PrairieColors.parchment,
    error: PrairieColors.brick,
    onError: PrairieColors.parchment,
    surface: PrairieColors.parchment,
    onSurface: PrairieColors.ink,
    surfaceContainerLowest: PrairieColors.parchment,
    surfaceContainerLow: PrairieColors.sand,
    surfaceContainer: PrairieColors.sand,
    outline: PrairieColors.stone,
    outlineVariant: PrairieColors.stone,
  );

  final base = ThemeData(useMaterial3: true, colorScheme: scheme);

  return base.copyWith(
    scaffoldBackgroundColor: PrairieColors.parchment,
    textTheme: _prairieTextTheme(base.textTheme),

    // 見出し部は水平の帯として扱い、下辺に太い線を通して床と壁を分ける。
    appBarTheme: const AppBarTheme(
      backgroundColor: PrairieColors.sand,
      foregroundColor: PrairieColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      shape: Border(
        bottom: BorderSide(color: PrairieColors.cherokee, width: 3),
      ),
      titleTextStyle: TextStyle(
        color: PrairieColors.ink,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 2.0,
      ),
    ),

    // 影で浮かせず、線で輪郭を描く。
    cardTheme: const CardThemeData(
      color: PrairieColors.parchment,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: PrairieColors.stone),
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: PrairieColors.stone,
      thickness: 1,
      space: 1,
    ),

    listTileTheme: const ListTileThemeData(
      shape: kSquareBorder,
      iconColor: PrairieColors.cherokee,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),

    filledButtonTheme: FilledButtonThemeData(style: _buttonStyle()),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: _buttonStyle().copyWith(
        side: const WidgetStatePropertyAll(
          BorderSide(color: PrairieColors.stone),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(style: _buttonStyle()),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: PrairieColors.cherokee,
      foregroundColor: PrairieColors.parchment,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: kSquareBorder,
      extendedTextStyle: TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: 1.4,
      ),
    ),

    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: PrairieColors.parchment,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: PrairieColors.stone),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: PrairieColors.stone),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: PrairieColors.cherokee, width: 2),
      ),
      labelStyle: TextStyle(letterSpacing: 1.2),
    ),

    dialogTheme: const DialogThemeData(
      backgroundColor: PrairieColors.parchment,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: PrairieColors.stone),
      ),
      titleTextStyle: TextStyle(
        color: PrairieColors.ink,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.6,
      ),
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: PrairieColors.parchment,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: kSquareBorder,
    ),

    checkboxTheme: const CheckboxThemeData(shape: kSquareBorder),

    snackBarTheme: const SnackBarThemeData(
      backgroundColor: PrairieColors.ink,
      contentTextStyle: TextStyle(color: PrairieColors.parchment),
      shape: kSquareBorder,
      behavior: SnackBarBehavior.floating,
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: PrairieColors.cherokee,
      linearTrackColor: PrairieColors.stone,
      linearMinHeight: 4,
    ),
  );
}

ButtonStyle _buttonStyle() => const ButtonStyle(
  shape: WidgetStatePropertyAll(kSquareBorder),
  padding: WidgetStatePropertyAll(
    EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  ),
  textStyle: WidgetStatePropertyAll(
    TextStyle(fontWeight: FontWeight.w600, letterSpacing: 1.4),
  ),
);

/// 字間を広げ、建築の銘板のような落ち着いた水平感を出す。
TextTheme _prairieTextTheme(TextTheme t) => t.copyWith(
  headlineMedium: t.headlineMedium?.copyWith(
    letterSpacing: 3.0,
    fontWeight: FontWeight.w300,
  ),
  headlineSmall: t.headlineSmall?.copyWith(
    letterSpacing: 2.0,
    fontWeight: FontWeight.w400,
  ),
  titleLarge: t.titleLarge?.copyWith(
    letterSpacing: 1.2,
    fontWeight: FontWeight.w500,
  ),
  titleMedium: t.titleMedium?.copyWith(
    letterSpacing: 1.8,
    fontWeight: FontWeight.w600,
  ),
  titleSmall: t.titleSmall?.copyWith(letterSpacing: 1.4),
  labelLarge: t.labelLarge?.copyWith(letterSpacing: 1.5),
);
