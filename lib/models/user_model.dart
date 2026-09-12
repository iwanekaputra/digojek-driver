class UserModel {
  final int? id;
  final String? name;
  final String? birthday;
  final String? gender;
  final String? email;
  final String? city;
  final String? province;
  final String? address;
  final String? nohp;
  final String? brand;
  final String? registrationNumber;
  final int? manufactureYear;
  final String? color;
  final String? image;
  final String? imageVehicle;
  final String? token_driver;
  final String? status_driver;
  final String? latitude;
  final String? longitude;
  final String? name_vehicle_driver;
  final int? balance;
  final int? is_mober;
  final int? is_delivering;
  final String? code_referal;
  final String? vehicletype;

  UserModel(
      {this.id,
      this.name,
      this.birthday,
      this.gender,
      this.email,
      this.city,
      this.province,
      this.address,
      this.nohp,
      this.brand,
      this.registrationNumber,
      this.manufactureYear,
      this.color,
      this.image,
      this.imageVehicle,
      this.token_driver,
      this.status_driver,
      this.latitude,
      this.longitude,
      this.name_vehicle_driver,
      this.balance,
      this.is_mober,
      this.is_delivering,
      this.code_referal,
      this.vehicletype});

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
      id: json['id'],
      name: json['name'],
      birthday: json['birthday'],
      gender: json['gender'],
      email: json['email'],
      city: json['city'],
      province: json['province'],
      address: json['address'],
      nohp: json['nohp'],
      brand: json['brand'],
      registrationNumber: json['vehicle']['registration_number'],
      manufactureYear: json['manufature_year'],
      color: json['color'],
      image: json['link_image'],
      imageVehicle: json['image_vehicle'],
      token_driver: json['token_driver'],
      status_driver: json['status_driver'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      name_vehicle_driver: json['vehicle']['brand'],
      balance: json['balance'],
      is_mober: json['is_mober'],
      is_delivering: json['is_delivering'],
      code_referal: json['code_referal'],
      vehicletype: json['vehicle']['vehiclecategory']['slug']);

  UserModel copyWith(
      {int? balance,
      int? is_mober,
      String? status_driver,
      String? latitude,
      String? longitude}) {
    return UserModel(
        id: id,
        name: name,
        birthday: birthday,
        gender: gender,
        email: email,
        city: city,
        province: province,
        address: address,
        nohp: nohp,
        brand: brand,
        registrationNumber: registrationNumber,
        manufactureYear: manufactureYear,
        color: color,
        image: image,
        imageVehicle: imageVehicle,
        token_driver: token_driver,
        status_driver: status_driver ?? this.status_driver,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        name_vehicle_driver: name_vehicle_driver,
        balance: balance ?? this.balance,
        is_mober: is_mober ?? this.is_mober,
        is_delivering: is_delivering,
        code_referal: code_referal,
        vehicletype: vehicletype);
  }
}
