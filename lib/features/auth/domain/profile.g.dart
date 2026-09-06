// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Profile _$ProfileFromJson(Map<String, dynamic> json) => _Profile(
  id: json['id'] as String,
  displayName: json['displayName'] as String,
  locale:
      $enumDecodeNullable(_$AppLocaleEnumMap, json['locale']) ?? AppLocale.sr,
);

Map<String, dynamic> _$ProfileToJson(_Profile instance) => <String, dynamic>{
  'id': instance.id,
  'displayName': instance.displayName,
  'locale': _$AppLocaleEnumMap[instance.locale]!,
};

const _$AppLocaleEnumMap = {AppLocale.sr: 'sr', AppLocale.en: 'en'};
