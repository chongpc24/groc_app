//premise.dart
class Premise {
  final int premiseCode;
  final String premise;
  final String address;
  final String premiseType;
  final String state;
  final String district;

  Premise({
    required this.premiseCode,
    required this.premise,
    required this.address,
    required this.premiseType,
    required this.state,
    required this.district,
  });

  factory Premise.fromMap(Map<String, dynamic> map) {
    return Premise(
      premiseCode: map['premiseCode'] as int,
      premise: map['premise'] as String? ?? '',
      address: map['address'] as String? ?? '',
      premiseType: map['premiseType'] as String? ?? '',
      state: map['state'] as String? ?? '',
      district: map['district'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'premiseCode': premiseCode,
    'premise': premise,
    'address': address,
    'premiseType': premiseType,
    'state': state,
    'district': district,
  };
}