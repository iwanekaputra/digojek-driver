import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:deliq_delivery/Account/UI/account_page.dart';
import 'package:deliq_delivery/Locale/locales.dart';
import 'package:flutter/material.dart';

class TncPage extends StatelessWidget {
  const TncPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      drawer: const AccountPageBody(),
      appBar: AppBar(
        titleSpacing: 0.0,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.tnc!,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FadedSlideAnimation(
        beginOffset: const Offset(0, 0.3),
        endOffset: const Offset(0, 0),
        slideCurve: Curves.linearToEaseOut,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // --- HERO BRANDING HEADER ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36.0),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: FadedScaleAnimation(
                    fadeDuration: const Duration(milliseconds: 400),
                    scaleDuration: const Duration(milliseconds: 400),
                    child: const Image(
                      image: AssetImage("images/logos/logo.png"),
                      height: 100.0,
                      width: 100.0,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              // --- CONTENT CONTAINER ---
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Judul Utama
                    Text(
                      'Syarat & Ketentuan Penggunaan',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Harap baca ketentuan berikut sebelum menggunakan aplikasi DIGOJEK Driver.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Card 1: Pengantar & Hak Cipta
                    _buildSectionCard(
                      context,
                      icon: Icons.gavel_rounded,
                      title: '1. Ketentuan Umum & Kekayaan Intelektual',
                      content:
                          'Ketentuan ini berlaku untuk aplikasi DIGOJEK Driver yang disediakan gratis oleh PT DIGOJEK ("Penyedia Layanan"). Dengan mengunduh atau menggunakan aplikasi, Anda secara otomatis menyetujui seluruh ketentuan ini.\n\n'
                          'Dilarang keras memodifikasi, menyalin, mengisolasi kode sumber, menerjemahkan, atau membuat versi turunan dari aplikasi maupun merek dagang kami tanpa izin tertulis. Seluruh hak cipta, merek dagang, dan hak basis data tetap menjadi milik penuh Penyedia Layanan.',
                    ),

                    // Card 2: Layanan & Biaya
                    _buildSectionCard(
                      context,
                      icon: Icons.payments_outlined,
                      title: '2. Layanan & Penyesuaian Biaya',
                      content:
                          'Penyedia Layanan berkomitmen untuk memberikan performa aplikasi yang optimal. Kami berhak mengubah fungsi aplikasi atau memberlakukan biaya atas layanan tertentu kapan saja. Setiap perubahan biaya akan diinformasikan secara transparan terlebih dahulu kepada Anda.',
                    ),

                    // Card 3: Keamanan & Akun
                    _buildSectionCard(
                      context,
                      icon: Icons.security_rounded,
                      title: '3. Data Pribadi & Keamanan Perangkat',
                      content:
                          'Aplikasi menyimpan dan memproses data pribadi yang Anda berikan untuk kepentingan operasional layanan. Anda bertanggung jawab penuh atas keamanan perangkat Anda.\n\n'
                          'Sangat disarankan untuk tidak melakukan rooting atau jailbreak pada ponsel Anda. Tindakan tersebut dapat merusak fitur keamanan bawaan, membuat perangkat rentan terhadap malware, serta menyebabkan aplikasi tidak dapat berfungsi sebagaimana mestinya.',
                    ),

                    // Card 4: Konektivitas & Biaya Pihak Ketiga
                    _buildSectionCard(
                      context,
                      icon: Icons.wifi_off_rounded,
                      title: '4. Akses Internet & Penggunaan Data',
                      content:
                          'Sebagian fitur memerlukan koneksi internet aktif (Wi-Fi atau Data Seluler). Penyedia Layanan tidak bertanggung jawab atas kendala performa aplikasi yang disebabkan oleh ketiadaan sinyal atau kuota data yang habis.\n\n'
                          'Penggunaan aplikasi di luar jangkauan Wi-Fi dapat dikenai tarif data reguler atau roaming sesuai kebijakan operator seluler Anda. Seluruh biaya pemakaian data tersebut menjadi tanggung jawab pengguna.',
                    ),

                    // Card 5: Tanggung Jawab & Batasan
                    _buildSectionCard(
                      context,
                      icon: Icons.report_problem_outlined,
                      title: '5. Batasan Tanggung Jawab',
                      content:
                          '• Perangkat Pribadi: Anda bertanggung jawab untuk memastikan baterai perangkat Anda cukup untuk mengakses layanan.\n'
                          '• Keakuratan Data: Informasi aplikasi dapat berasal dari penyedia pihak ketiga. Penyedia Layanan tidak bertanggung jawab atas kerugian langsung maupun tidak langsung akibat ketergantungan penuh pada fungsi aplikasi.',
                    ),

                    // Card 6: Pembaruan & Penghentian
                    _buildSectionCard(
                      context,
                      icon: Icons.system_update_rounded,
                      title: '6. Pembaruan & Penghentian Layanan',
                      content:
                          'Aplikasi dapat diperbarui sewaktu-waktu untuk mendukung kompatibilitas sistem operasi. Anda menyetujui untuk selalu menerima pembaruan yang ditawarkan.\n\n'
                          'Penyedia Layanan berhak menghentikan ketersediaan aplikasi kapan saja tanpa pemberitahuan sebelumnya. Saat terjadi penghentian, seluruh lisensi penggunaan Anda berakhir dan Anda wajib menghapus aplikasi dari perangkat.',
                    ),

                    // Card 7: Perubahan Ketentuan
                    _buildSectionCard(
                      context,
                      icon: Icons.edit_note_rounded,
                      title: 'Perubahan Ketentuan',
                      content:
                          'Syarat dan Ketentuan ini dapat diperbarui secara berkala. Perubahan akan berlaku serta merta setelah dipublikasikan pada halaman ini.\n\n'
                          '• Berlaku sejak: 5 Juli 2024',
                    ),

                    const SizedBox(height: 10),

                    // SECTION: Kontak Kami
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.primaryColor.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.mail_outline_rounded,
                                color: theme.primaryColor,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Hubungi Kami',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Jika Anda memiliki pertanyaan atau saran mengenai Syarat dan Ketentuan ini, silakan hubungi kami melalui email:',
                            style: theme.textTheme.bodySmall?.copyWith(
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            'DIGOJEK@gmail.com',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widget untuk membuat Card konsisten & rapi
  Widget _buildSectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
  }) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: theme.primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(height: 1, thickness: 0.5),
          ),
          Text(
            content,
            style: theme.textTheme.bodySmall?.copyWith(
              height: 1.5,
              color: Colors.black87,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }
}
