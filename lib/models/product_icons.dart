import 'package:flutter/material.dart';

// Maps common keywords found in item names to representative icons.
// Checked in order — first match wins, so put more specific keywords first.
// Maps PriceCatcher item_category values directly to representative
// image paths. Category values are already clean/standardized, so we
// match on them directly instead of guessing keywords from item names.
String imagePathForProduct(String category) {
  const categoryMap = <String, String>{
    'AYAM': 'assets/images/ayam.jpg',
    'BAHAN LAUT': 'assets/images/bahan_laut.jpg',
    'BAHAN-BAHAN MINUMAN': 'assets/images/minuman.jpg',
    'BAWANG': 'assets/images/bawang.jpg',
    'BERAS': 'assets/images/beras.jpg',
    'BERUS GIGI': 'assets/images/berus_gigi.jpg',
    'BIHUN': 'assets/images/bihun.jpg',
    'BISKUT': 'assets/images/biskut.jpg',
    'BUAH-BUAHAN': 'assets/images/buah.jpg',
    'CILI KERING': 'assets/images/cili.jpg',
    'COKLAT': 'assets/images/coklat.jpg',
    'DAGING': 'assets/images/daging.jpg',
    'ESEN DAN RAGI': 'assets/images/esen_ragi.jpg',
    'GULA': 'assets/images/gula.jpg',
    'HASIL LAUT KERING': 'assets/images/laut_kering.jpg',
    'IKAN DALAM TIN': 'assets/images/ikan_tin.jpg',
    'IKAN DARAT': 'assets/images/ikan.jpg',
    'KACANG': 'assets/images/kacang.jpg',
    'KELAPA': 'assets/images/kelapa.jpg',
    'KICAP DAN SOS': 'assets/images/kicap_sos.jpg',
    'KRIMER DAN SUSU TEPUNG': 'assets/images/susu_tepung.jpg',
    'LAMPIN PAKAI BUANG': 'assets/images/lampin.jpg',
    'LAUK': 'assets/images/lauk.jpg',
    'MAJALAH': 'assets/images/majalah.jpg',
    'MAKANAN BAYI': 'assets/images/makanan_bayi.jpg',
    'MAKANAN RINGAN': 'assets/images/snacks.jpg',
    'MAKANAN SEGERA': 'assets/images/makanan_segera.jpg',
    'MEE / BIHUN / KUEY TEOW': 'assets/images/mee.jpg',
    'MEE/KUETIAU': 'assets/images/mee.jpg',
    'MENTEGA': 'assets/images/mentega.jpg',
    'MI SEGERA': 'assets/images/mi_segera.jpg',
    'MINUMAN': 'assets/images/minuman.jpg',
    'MINYAK DAN LEMAK': 'assets/images/minyak.jpg',
    'MOUTH WASH': 'assets/images/mouthwash.jpg',
    'NASI': 'assets/images/nasi.jpg',
    'PENGHALAU NYAMUK': 'assets/images/penghalau_nyamuk.jpg',
    'PENJAGAAN DIRI': 'assets/images/penjagaan_diri.jpg',
    'PENJAGAAN RUMAH': 'assets/images/penjagaan_rumah.jpg',
    'PEWANGI RUMAH': 'assets/images/pewangi.jpg',
    'REMPAH RATUS (BERBUNGKUS)': 'assets/images/rempah.jpg',
    'REMPAH RATUS (TIDAK BERBUNGKUS)': 'assets/images/rempah.jpg',
    'ROTI': 'assets/images/roti.jpg',
    'SABUN BADAN': 'assets/images/sabun.jpg',
    'SANTAN (KOTAK)': 'assets/images/santan.jpg',
    'SAPUAN (SPREADS)': 'assets/images/spreads.jpg',
    'SAYUR-SAYURAN': 'assets/images/sayur.jpg',
    'SUSU BAYI': 'assets/images/susu_bayi.jpg',
    'SYAMPU': 'assets/images/syampu.jpg',
    'TAUHU DAN TEMPE': 'assets/images/tauhu.jpg',
    'TELUR': 'assets/images/telur.jpg',
    'TEPUNG': 'assets/images/tepung.jpg',
    'TERSEDIA MINUM': 'assets/images/minuman.jpg',
    'TISU': 'assets/images/tisu.jpg',
    'TUALA WANITA': 'assets/images/tuala_wanita.jpg',
    'UBAT GIGI': 'assets/images/ubat_gigi.jpg',
    'UBAT-UBATAN': 'assets/images/ubat.jpg',
    'UBI KENTANG': 'assets/images/kentang.jpg',
    'ALAT TULIS DAN BAHAN BACAAN': 'assets/images/alat_tulis.jpg',
    'LAIN-LAIN': 'assets/images/placeholder.jpg',
  };

  return categoryMap[category] ?? 'assets/images/placeholder.jpg';
}

// A soft background color per icon, so tiles/cards look intentional
// rather than plain white circles.
Color colorForProduct(String itemName) {
  final name = itemName.toUpperCase();

  const colorMap = <String, Color>{
    'AYAM': Color(0xFFFCE8D5),
    'TELUR': Color(0xFFFFF3C4),
    'IKAN': Color(0xFFD6EAF8),
    'DAGING': Color(0xFFF5D0D0),
    'SAYUR': Color(0xFFD9F2D9),
    'BUAH': Color(0xFFFAD7D7),
    'MINYAK': Color(0xFFFFF0D9),
    'SUSU': Color(0xFFEAF2FB),
    'ROTI': Color(0xFFF3E2C8),
    'BISKUT': Color(0xFFF0E0C8),
    'MINUMAN': Color(0xFFD6F0F0),
    'BERAS': Color(0xFFF0EAD6),
    'GULA': Color(0xFFFCE4EC),
  };

  for (final entry in colorMap.entries) {
    if (name.contains(entry.key)) return entry.value;
  }

  return Colors.grey.shade200;
}