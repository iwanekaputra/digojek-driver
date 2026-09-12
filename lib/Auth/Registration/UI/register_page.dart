import 'dart:convert';
import 'dart:io';

import 'package:deliq_delivery/Auth/Verification/UI/verification_register_page.dart';
import 'package:deliq_delivery/Themes/colors.dart';
import 'package:deliq_delivery/services/auth_service.dart';
import 'package:deliq_delivery/services/shared_services.dart';
import 'package:deliq_delivery/shared/shared_values.dart';
import 'package:http/http.dart' as http;

import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:deliq_delivery/Components/bottom_bar.dart';
import 'package:deliq_delivery/Components/forms.dart';
import 'package:deliq_delivery/Locale/locales.dart';
import 'package:deliq_delivery/Routes/routes.dart';
import 'package:deliq_delivery/blocs/auth/auth_bloc.dart';
import 'package:deliq_delivery/models/sign_up_form_model.dart';
import 'package:deliq_delivery/shared/shared_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

//register page for registration of a new user
class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: true,
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context)!.register!,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
      body: FadedSlideAnimation(
        beginOffset: const Offset(0, 0.1),
        endOffset: const Offset(0, 0),
        slideCurve: Curves.fastOutSlowIn,
        child: const RegisterForm(),
      ),
    );
  }
}

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  RegisterFormState createState() => RegisterFormState();
}

class RegisterFormState extends State<RegisterForm> {
  final nameController = TextEditingController(text: '');
  final birthdayController = TextEditingController(text: '');
  final emailController = TextEditingController(text: '');
  final addressController = TextEditingController(text: '');
  final nohpController = TextEditingController(text: '');
  final brandController = TextEditingController(text: '');
  final registrationNumberController = TextEditingController(text: '');
  final manufactureYearController = TextEditingController(text: '');
  final colorController = TextEditingController(text: '');

  final referalController = TextEditingController(text: '');

  bool? isAgree = false;
  bool isLoading = false;

  XFile? selectedProfile;
  XFile? selectedKtp;
  XFile? selectedSim;
  XFile? selectedStnk;
  XFile? selectedVehicle;

  Object? selectedProvinceObject;
  Object? selectedCityObject;

  String? selectedProvinceId;
  String? selectedCityId;

  String? _valGender;
  String? selectedProvince;
  String? selectedCity;
  String? selectedVehicleTypeId;
  final List _listGender = ["Laki-Laki", "Perempuan"];
  List _listVehicleType = [];

  List<dynamic> listProvince = [];
  List<dynamic> listCity = [];

  static const int MAX_FILE_SIZE_BYTES = 1 * 1024 * 1024; // 1MB dalam bytes
  static const double MAX_FILE_SIZE_MB = 1.0;

  bool validate() {
    if (selectedKtp == null ||
        selectedProfile == null ||
        selectedSim == null ||
        selectedStnk == null ||
        selectedVehicle == null ||
        nameController.text.isEmpty ||
        birthdayController.text.isEmpty ||
        emailController.text.isEmpty ||
        addressController.text.isEmpty ||
        nohpController.text.isEmpty ||
        brandController.text.isEmpty ||
        registrationNumberController.text.isEmpty ||
        manufactureYearController.text.isEmpty ||
        colorController.text.isEmpty ||
        _valGender == null ||
        _valGender!.isEmpty ||
        selectedCity == null ||
        selectedCity!.isEmpty ||
        selectedProvince == null ||
        selectedProvince!.isEmpty ||
        selectedVehicleTypeId == null ||
        isAgree == false) {
      return false;
    }

    return true;
  }

  Future<bool> validateAllImages() async {
    List<Map<String, dynamic>> imagesToValidate = [
      {'file': selectedProfile, 'name': 'Profile'},
      {'file': selectedKtp, 'name': 'KTP'},
      {'file': selectedSim, 'name': 'SIM'},
      {'file': selectedStnk, 'name': 'STNK'},
      {'file': selectedVehicle, 'name': 'Kendaraan'},
    ];

    for (var imageData in imagesToValidate) {
      XFile? file = imageData['file'];
      String name = imageData['name'];

      if (file != null) {
        bool isValid = await validateImageSize(file, name);
        if (!isValid) {
          return false;
        }
      }
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async => await initData());
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    birthdayController.dispose();
    addressController.dispose();
    nohpController.dispose();
    brandController.dispose();
    registrationNumberController.dispose();
    manufactureYearController.dispose();
    colorController.dispose();
    referalController.dispose();
    super.dispose();
  }

  Future<void> initData() async {
    getProvince();
    getListVehicleCategory();
  }

  Future<bool> validateImageSize(XFile file, String imageName) async {
    final fileSize = await file.length();

    if (fileSize > MAX_FILE_SIZE_BYTES) {
      if (mounted) {
        showCustomSnackbar(context,
            'Ukuran gambar $imageName terlalu besar. Maksimal ${MAX_FILE_SIZE_MB}MB');
      }
      return false;
    }
    return true;
  }

  String formatFileSize(int bytes) {
    double mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(2)} MB';
  }

  Future<XFile?> selectAndValidateImage(String imageName) async {
    try {
      final image = await selectImage();
      if (image != null) {
        final isValid = await validateImageSize(image, imageName);
        if (isValid) {
          return image;
        } else {
          final fileSize = await image.length();
          if (mounted) {
            showCustomSnackbar(context,
                'Ukuran file yang dipilih: ${formatFileSize(fileSize)}');
          }
          return null;
        }
      }
      return null;
    } catch (e) {
      if (mounted) {
        showCustomSnackbar(context, 'Gagal memilih gambar: ${e.toString()}');
      }
      return null;
    }
  }

  Future<void> getListVehicleCategory() async {
    final res = await SharedServices().getListVehicleCategory();

    if (res.isSuccess) {
      setState(() {
        _listVehicleType = res.value;
      });
    }
  }

  void getProvince() async {
    final res = await http.get(Uri.parse('${baseUrl}/province'),
        headers: {'key': RAJA_ONGKIR_API_KEY});
    if (res.statusCode == 200) {
      setState(() {
        listProvince = jsonDecode(res.body)['data'];
      });
    }
  }

  void getCityByProvince() async {
    final res = await http.get(Uri.parse('${baseUrl}/city/$selectedProvinceId'),
        headers: {'key': RAJA_ONGKIR_API_KEY});
    if (res.statusCode == 200) {
      setState(() {
        listCity = jsonDecode(res.body)['data'];
      });
    }
  }

  void getDataCityProvince() async {
    final res = await http.get(
        Uri.parse(
            '${baseUrl}/city?id=$selectedCityId&province=$selectedProvinceId'),
        headers: {'key': RAJA_ONGKIR_API_KEY});

    if (res.statusCode == 200) {
      setState(() {
        selectedCity = jsonDecode(res.body)['data']['city_name'];
        selectedProvince = jsonDecode(res.body)['data']['province'];
      });
    }
  }

  InputDecoration _customDropdownDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).primaryColor),
      ),
    );
  }

  Widget _buildSectionCard(
      {required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  // Section: Data Diri
                  _buildSectionCard(
                    title: 'Data Diri',
                    children: [
                      CustomFormField(
                        title: AppLocalizations.of(context)!.fullName!,
                        controller: nameController,
                      ),
                      const SizedBox(height: 12),
                      CustomFormField(
                        title: AppLocalizations.of(context)!.emailAddress!,
                        controller: emailController,
                      ),
                      const SizedBox(height: 12),
                      CustomFormField(
                        title: AppLocalizations.of(context)!.mobileNumber!,
                        controller: nohpController,
                      ),
                      const SizedBox(height: 12),
                      CustomFormDate(
                        title: 'Tanggal Lahir',
                        controller: birthdayController,
                        onTap: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(1950),
                            lastDate: DateTime(2100),
                          );

                          if (pickedDate != null) {
                            String formattedDate =
                                DateFormat('yyyy-MM-dd').format(pickedDate);
                            setState(() {
                              birthdayController.text = formattedDate;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Jenis Kelamin',
                              style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: 6),
                          DropdownButtonFormField(
                            decoration: _customDropdownDecoration(
                                "Pilih Jenis Kelamin"),
                            isExpanded: true,
                            value: _valGender,
                            items: _listGender.map((value) {
                              return DropdownMenuItem(
                                child: Text(value,
                                    style: const TextStyle(fontSize: 14)),
                                value: value,
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _valGender = value.toString();
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Provinsi',
                              style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: 6),
                          DropdownButtonFormField(
                            decoration:
                                _customDropdownDecoration("Pilih Provinsi"),
                            isExpanded: true,
                            value: selectedProvinceObject,
                            items: listProvince.map((value) {
                              return DropdownMenuItem(
                                child: Text(value['name'],
                                    style: const TextStyle(fontSize: 14)),
                                value: value,
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value is Map<String, dynamic>) {
                                setState(() {
                                  selectedProvinceObject = value;
                                  selectedProvinceId = value['code'].toString();
                                  selectedProvince = value['name'];
                                  listCity = [];
                                  selectedCityObject = null;
                                  selectedCityId = null;
                                });
                              }
                              getCityByProvince();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Kota',
                              style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: 6),
                          DropdownButtonFormField(
                            decoration: _customDropdownDecoration("Pilih Kota"),
                            isExpanded: true,
                            value: selectedCityObject,
                            items: listCity.map((value) {
                              return DropdownMenuItem(
                                child: Text(value['name'],
                                    style: const TextStyle(fontSize: 14)),
                                value: value,
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value is Map<String, dynamic>) {
                                setState(() {
                                  selectedCityObject = value;
                                  selectedCity = value['name'];
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      CustomFormField(
                        title: 'Alamat',
                        controller: addressController,
                      ),
                      const SizedBox(height: 12),
                      CustomFormField(
                        title: 'Referal',
                        controller: referalController,
                      ),
                    ],
                  ),

                  // Section: Data Kendaraan
                  _buildSectionCard(
                    title: 'Data Kendaraan',
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Jenis Kendaraan',
                              style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: 6),
                          DropdownButtonFormField(
                            decoration: _customDropdownDecoration(
                                "Pilih Jenis Kendaraan"),
                            isExpanded: true,
                            value: selectedVehicleTypeId,
                            items: _listVehicleType.map((value) {
                              return DropdownMenuItem(
                                child: Text(value['name'],
                                    style: const TextStyle(fontSize: 14)),
                                value: value['id'].toString(),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedVehicleTypeId = value.toString();
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      CustomFormField(
                        title: 'Warna',
                        controller: colorController,
                      ),
                      const SizedBox(height: 12),
                      CustomFormField(
                        title: 'Merk',
                        controller: brandController,
                      ),
                      const SizedBox(height: 12),
                      CustomFormField(
                        title: 'Plat Nomor',
                        controller: registrationNumberController,
                      ),
                      const SizedBox(height: 12),
                      CustomFormField(
                        title: 'Tahun Pembuatan',
                        controller: manufactureYearController,
                      ),
                    ],
                  ),

                  // Section: Upload Berkas
                  _buildSectionCard(
                    title: 'Data Gambar',
                    children: [
                      buildImageUploadsSection(),
                    ],
                  ),
                  const SizedBox(height: 120), // Padding offset bottom bar
                ],
              ),
            ),
      bottomSheet: isLoading
          ? const SizedBox.shrink()
          : Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          activeColor: Theme.of(context).primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          value: isAgree,
                          onChanged: (value) {
                            setState(() {
                              isAgree = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Dengan Mendaftar, Saya Menyetujui semua kebijakan yang di berikan oleh PT DIGOJEK",
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                    color: Colors.grey[700],
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  buildContinueButton(),
                ],
              ),
            ),
    );
  }

  Widget buildImageUpload({
    required String title,
    required XFile? selectedImage,
    required Function(XFile?) onImageSelected,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: () async {
            final image = await selectAndValidateImage(title);
            onImageSelected(image);
          },
          child: Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selectedImage != null
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
                width: selectedImage != null ? 1.5 : 1,
              ),
              image: selectedImage == null
                  ? null
                  : DecorationImage(
                      fit: BoxFit.cover,
                      image: FileImage(File(selectedImage.path)),
                    ),
            ),
            child: selectedImage != null
                ? Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      margin: const EdgeInsets.all(6),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 28,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Upload $title',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        if (selectedImage != null)
          FutureBuilder<int>(
            future: selectedImage.length(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Text(
                  formatFileSize(snapshot.data!),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
      ],
    );
  }

  Widget buildImageUploadsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  color: Colors.blue.shade700, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Maksimal ukuran gambar per berkas ${MAX_FILE_SIZE_MB}MB.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            buildImageUpload(
              title: 'Profile',
              selectedImage: selectedProfile,
              onImageSelected: (image) {
                setState(() {
                  selectedProfile = image;
                });
              },
            ),
            buildImageUpload(
              title: 'KTP',
              selectedImage: selectedKtp,
              onImageSelected: (image) {
                setState(() {
                  selectedKtp = image;
                });
              },
            ),
            buildImageUpload(
              title: 'SIM',
              selectedImage: selectedSim,
              onImageSelected: (image) {
                setState(() {
                  selectedSim = image;
                });
              },
            ),
            buildImageUpload(
              title: 'STNK',
              selectedImage: selectedStnk,
              onImageSelected: (image) {
                setState(() {
                  selectedStnk = image;
                });
              },
            ),
            buildImageUpload(
              title: 'Kendaraan',
              selectedImage: selectedVehicle,
              onImageSelected: (image) {
                setState(() {
                  selectedVehicle = image;
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
          ),
        ),
        onPressed: () async {
          if (!validate()) {
            showCustomSnackbar(context, 'Semua field harus diisi');
            return;
          }

          bool allImagesValid = await validateAllImages();
          if (!allImagesValid) {
            showCustomSnackbar(context,
                'Pastikan semua gambar berukuran maksimal ${MAX_FILE_SIZE_MB}MB');
            return;
          }

          setState(() {
            isLoading = true;
          });

          try {
            final res = await AuthService().sendOtpWaRegister(
              SignUpFormModel(
                name: nameController.text,
                birthday: birthdayController.text,
                gender: _valGender,
                email: emailController.text,
                city: selectedCity,
                province: selectedProvince,
                address: addressController.text,
                agreement: '1',
                nohp: nohpController.text,
                vehicletypeId: selectedVehicleTypeId,
                brand: brandController.text,
                registrationNumber: registrationNumberController.text,
                manufactureYear: manufactureYearController.text,
                color: colorController.text,
                ktp: base64Encode(
                  File(selectedKtp!.path).readAsBytesSync(),
                ),
                sim: base64Encode(
                  File(selectedSim!.path).readAsBytesSync(),
                ),
                image: base64Encode(
                  File(selectedProfile!.path).readAsBytesSync(),
                ),
                imageVehicle: base64Encode(
                  File(selectedVehicle!.path).readAsBytesSync(),
                ),
                stnk: base64Encode(
                  File(selectedStnk!.path).readAsBytesSync(),
                ),
                referal: referalController.text,
              ),
            );

            if (res.isSuccess) {
              setState(() {
                isLoading = false;
              });
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VerificationRegisterPage(
                    SignUpFormModel(
                      name: nameController.text,
                      birthday: birthdayController.text,
                      gender: _valGender,
                      email: emailController.text,
                      city: selectedCity,
                      province: selectedProvince,
                      address: addressController.text,
                      agreement: '1',
                      nohp: nohpController.text,
                      vehicletypeId: selectedVehicleTypeId,
                      brand: brandController.text,
                      registrationNumber: registrationNumberController.text,
                      manufactureYear: manufactureYearController.text,
                      color: colorController.text,
                      ktp: base64Encode(
                        File(selectedKtp!.path).readAsBytesSync(),
                      ),
                      sim: base64Encode(
                        File(selectedSim!.path).readAsBytesSync(),
                      ),
                      image: base64Encode(
                        File(selectedProfile!.path).readAsBytesSync(),
                      ),
                      imageVehicle: base64Encode(
                        File(selectedVehicle!.path).readAsBytesSync(),
                      ),
                      stnk: base64Encode(
                        File(selectedStnk!.path).readAsBytesSync(),
                      ),
                      referal: referalController.text,
                    ),
                  ),
                ),
              );
            } else if (res.validationErrors!.isNotEmpty) {
              setState(() {
                isLoading = false;
              });
              Map<String, dynamic> errors = res.validationErrors!;
              Map<String, List<String>> newErrors = errors.map((key, value) {
                return MapEntry(key, List<String>.from(value));
              });

              newErrors.entries.forEach((entry) {
                List<String> messages = entry.value;
                messages.forEach((message) {
                  showCustomSnackbar(context, message);
                });
              });
            } else {
              setState(() {
                isLoading = false;
              });
              showCustomSnackbar(context, 'Terjadi Kesalahan');
            }
          } catch (e) {
            setState(() {
              isLoading = false;
            });
            showCustomSnackbar(context, 'Error: ${e.toString()}');
          }
        },
        child: Text(
          "Lanjut",
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
      ),
    );
  }
}
