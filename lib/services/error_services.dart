class ErrorService {
  static String getErrorMessage(String codeError) {
    switch (codeError) {
      case 'SKU_NOT_FOUND':
        return 'Produk tidak ditemukan / tidak aktif';
      case 'TRANSACTION_ALREADY_COMPLETED':
        return 'Harap selesaikan transaksi sebelumnya di aplikasi lain';
      case 'DESTINATION_IS_BLOCKED':
        return 'Nomor tujuan sudah tidak aktif / terblokir';
      case 'PRODUCT_SELLER_NOT_FOUND':
        return 'Product tidak tersedia saat ini';
      case 'WRONG_DESTINATION_NUMBER':
        return 'Nomor tujuan salah';
      case 'PRODUCT_IN_MAINTENANCE':
        return 'Mohon maaf produk sedang gangguan';
      case 'DIGIT_NOT_ENOUGH':
        return 'Mohon pastikan kembali nomor tujuan yang anda inputkan';
      case 'PRODUCT_CUT_OFF':
        return 'Mohon maaf product sedang proses cut off, Harap tunggu beberapa saat lagi';
      case 'TAGIHAN_NOT_AVAILABLE':
        return 'Saat ini tagihan belum tersedia';
      case 'SELLER_IN_MAINTENANCE':
        return 'Mohon maaf produk sedang gangguan';
      case 'NOT_SUPPORT_MULTI_TRANSACTION':
        return 'Maaf tidak bisa melakukan transaksi yang sama, harap pilih denom yang lain.';
      case 'SELLER_CUT_OFF':
        return 'Mohon maaf sistem dalam proses cut off';
      case 'LIMIT_TRANSACTION':
        return 'Anda telah mencapai limitasi transaksi, silahkan coba 10 menit lagi';
      default:
        return 'Terjadi Kesalahan / Sistem sedang dalam gangguan';
    }
  }
}
