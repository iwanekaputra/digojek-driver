class SignUpFormModel {
  final String? name;
  final String? birthday;
  final String? gender;
  final String? email;
  final String? city;
  final String? province;
  final String? address;
  final String? agreement;
  final String? nohp;
  final String? vehicletypeId;
  final String? brand;
  final String? registrationNumber;
  final String? manufactureYear;
  final String? color;
  final String? ktp;
  final String? sim;
  // final String? skck;
  final String? image;
  final String? imageVehicle;
  final String? stnk;
  final String? referal;

  SignUpFormModel(
      {this.name,
      this.birthday,
      this.gender,
      this.email,
      this.city,
      this.province,
      this.address,
      this.agreement,
      this.nohp,
      this.vehicletypeId,
      this.brand,
      this.registrationNumber,
      this.manufactureYear,
      this.color,
      this.ktp,
      this.sim,
      // this.skck,
      this.image,
      this.imageVehicle,
      this.stnk,
      this.referal});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'birthday': birthday,
      'gender': gender,
      'email': email,
      'city': city,
      'province': province,
      'address': address,
      'agreement': agreement,
      'nohp': nohp,
      'vehicletype_id': vehicletypeId,
      'brand': brand,
      'registration_number': registrationNumber,
      'manufacture_year': manufactureYear,
      'color': color,
      'ktp': ktp,
      'sim': sim,
      'image': image,
      'image_vehicle': imageVehicle,
      'stnk': stnk,
      'referal': referal
    };
  }
}
