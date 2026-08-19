import 'package:flutter/material.dart';

const Map<String, String> _itemKeywordMap = {
  'SUSU KAMBING': 'assets/images/items/susu.jpg',
  'DAGING KAMBING': 'assets/images/items/daging_kambing.jpg',
  'DAGING BABI': 'assets/images/items/daging_babi.jpg',
  'DAGING KERBAU': 'assets/images/items/daging_kerbau.jpg',
  'WHOLE LEG AYAM': 'assets/images/items/whole_leg_ayam.jpg',
  'KEPAK AYAM': 'assets/images/items/kepak_ayam.jpg',
  'KACANG TANAH': 'assets/images/items/kacang_tanah.jpg',
  'KACANG PANJANG': 'assets/images/items/kacang_panjang.jpg',
  'KACANG BENDI': 'assets/images/items/kacang_bendi.jpg',
  'KACANG SOYA': 'assets/images/items/kacang_soya.jpg',
  'KACANG BUNCIS': 'assets/images/items/kacang_buncis.jpg',
  'SOS TOMATO': 'assets/images/items/sos_tomato.jpg',
  'SOS CILI': 'assets/images/items/sos_cili.jpg',
  'IKAN TILAPIA': 'assets/images/items/ikan_tilapia.jpg',
  'IKAN KELI': 'assets/images/items/ikan_keli.jpg',
  'DRAGON FRUIT': 'assets/images/items/dragon_fruit.jpg',
  'KUBIS PANJANG': 'assets/images/items/kubis_panjang.jpg',
  'KUBIS BULAT': 'assets/images/items/kubis_bulat.jpg',
  'KUBIS BUNGA': 'assets/images/items/kubis_bunga.jpg',
  'CILI HIJAU': 'assets/images/items/cili_hijau.jpg',
  'CILI MERAH': 'assets/images/items/cili_merah.jpg',
  'MENTEGA KACANG': 'assets/images/items/mentega_kacang.jpg',
  'TEMBIKAI SUSU': 'assets/images/items/tembikai_susu.jpg',
  'TEMBIKAI MERAH': 'assets/images/items/tembikai_merah.jpg',
  'LIMAU NIPIS': 'assets/images/items/limau_nipis.jpg',
  'LIMAU KASTURI': 'assets/images/items/limau_kasturi.jpg',
  'BAWANG PERAI': 'assets/images/items/bawang_perai.jpg',
  'BAWANG PUTIH': 'assets/images/items/bawang_putih.jpg',
  'LADA BENGGALA': 'assets/images/items/lada_benggala.jpg',
  'JEM STRAWBERI': 'assets/images/items/jem_strawberi.jpg',
  'LOBAK MERAH': 'assets/images/items/lobak_merah.jpg',
  'GULA MERAH': 'assets/images/items/gula_merah.jpg',
  'MIRINDA OREN': 'assets/images/items/mirinda_oren.png',
  'F&N OREN': 'assets/images/items/fn_oren.jpg',
  '100 PLUS': 'assets/images/items/seratus_plus.jpg',
  'COCA COLA': 'assets/images/items/cola_cola.jpg',
  'SEVEN UP': 'assets/images/items/seven_up.png',
  'RED BULL': 'assets/images/items/red_bull.png',
  'PEPSI': 'assets/images/items/pepsi.jpg',
  'YEO': 'assets/images/items/yeos.jpg',
  'YOGURT': 'assets/images/items/yogurt.jpg',
  'DRINHO': 'assets/images/items/drinho.jpg',
  'SUSU SEGAR': 'assets/images/items/susu.jpg',
  'UDANG': 'assets/images/items/udang.jpg',
  'SOTONG': 'assets/images/items/sotong.jpg',
  'JAMBU': 'assets/images/items/jambu.jpg',
  'BETIK': 'assets/images/items/betik.jpg',
  'TERUNG': 'assets/images/items/terung.jpg',
  'KANGKUNG': 'assets/images/items/kangkung.jpg',
  'TOMATO': 'assets/images/items/tomato.jpg',
  'KAILAN': 'assets/images/items/kailan.jpg',
  'TIMUN': 'assets/images/items/timun.jpg',
  'HALIA': 'assets/images/items/halia.jpg',
  'ANGGUR': 'assets/images/items/anggur.jpg',
  'PISANG': 'assets/images/items/pisang.jpg',
  'BROKOLI': 'assets/images/items/brokoli.jpg',
  'BAYAM': 'assets/images/items/bayam.jpg',
  'BERUS GIGI': 'assets/images/items/berus_gigi.jpg',
  'UBAT GIGI': 'assets/images/items/ubat_gigi.jpg',
  'NESTLE': 'assets/images/items/nestle.jpg',
  'NESCAFE': 'assets/images/items/nescafe.jpg',
  'QUAKER': 'assets/images/items/quaker.jpg',
  'IKAN': 'assets/images/items/ikan.jpg',
  'KETAM': 'assets/images/items/ikan.jpg',
};

const Map<String, String> _categoryMap = {
  'AYAM': 'assets/images/ayam.jpg',
  'BAHAN LAUT': 'assets/images/bahan_laut.jpg',
  'BAHAN-BAHAN MINUMAN': 'assets/images/minuman.jpg',
  'BAWANG': 'assets/images/bawang.jpg',
  'BERAS': 'assets/images/beras.jpg',
  'BIHUN': 'assets/images/bihun.jpg',
  'BUAH-BUAHAN': 'assets/images/buah.jpg',
  'CILI KERING': 'assets/images/cili.jpg',
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
  'MAKANAN BAYI': 'assets/images/makanan_bayi.jpg',
  'MEE/KUETIAU': 'assets/images/mee.jpg',
  'MENTEGA': 'assets/images/mentega.jpg',
  'MI SEGERA': 'assets/images/mi_segera.jpg',
  'MINYAK DAN LEMAK': 'assets/images/minyak.jpg',
  'PENJAGAAN DIRI': 'assets/images/penjagaan_diri.jpg',
  'PENJAGAAN RUMAH': 'assets/images/penjagaan_rumah.jpg',
  'REMPAH RATUS (BERBUNGKUS)': 'assets/images/rempah.jpg',
  'REMPAH RATUS (TIDAK BERBUNGKUS)': 'assets/images/ratus.jpg',
  'SANTAN (KOTAK)': 'assets/images/santan.jpg',
  'SAPUAN (SPREADS)': 'assets/images/spreads.jpg',
  'SAYUR-SAYURAN': 'assets/images/sayur.jpg',
  'SUSU BAYI': 'assets/images/susu_bayi.jpg',
  'TELUR': 'assets/images/telur.jpg',
  'TEPUNG': 'assets/images/tepung.jpg',
  'TERSEDIA MINUM': 'assets/images/tersedia_minum.jpg',
  'UBI KENTANG': 'assets/images/kentang.jpg',
};

final List<String> _sortedItemKeywords = _itemKeywordMap.keys.toList()
  ..sort((a, b) => b.length.compareTo(a.length)); // longest/most specific first

String imagePathForCategory(String category) {
  return _categoryMap[category] ?? 'assets/images/grocery.jpg';
}

String imagePathForProduct(String itemName, String category) {
  final upperName = itemName.toUpperCase();

  for (final keyword in _sortedItemKeywords) {
    if (upperName.contains(keyword)) {
      return _itemKeywordMap[keyword]!;
    }
  }

  return imagePathForCategory(category);
}

class ProductIconTile extends StatelessWidget {
  final String itemName;
  final String category;

  final bool isCategoryTile;

  const ProductIconTile({
    super.key,
    required this.itemName,
    required this.category,
    this.isCategoryTile = false,
  });

  @override
  Widget build(BuildContext context) {
    final path = isCategoryTile
        ? imagePathForCategory(category)
        : imagePathForProduct(itemName, category);
    return Image.asset(
      path,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          Image.asset(imagePathForCategory(category), fit: BoxFit.cover),
    );
  }
}