import 'package:flutter/material.dart';

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
    'TERSEDIA MINUM': 'assets/images/minuman.jpg',
    'UBI KENTANG': 'assets/images/kentang.jpg',
  };

  return categoryMap[category] ?? 'assets/images/placeholder.jpg';
}

class ProductIconTile extends StatelessWidget {
  final String category;

  const ProductIconTile({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      imagePathForProduct(category),
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          Container(color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported)),
    );
  }
}