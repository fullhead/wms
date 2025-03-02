import 'package:wms/core/utils.dart';

class Group {
  int groupID;
  String groupName;
  String groupAccessLevel;
  bool groupStatus;
  DateTime groupCreationDate;

  Group({
    required this.groupID,
    required this.groupName,
    required this.groupAccessLevel,
    required this.groupStatus,
    required this.groupCreationDate,
  });

  /// Фабричный конструктор для создания группы из JSON (Map) полученный от API
  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      groupID: json['GroupID'] ?? 0,
      groupName: json['GroupName'] ?? '',
      groupAccessLevel: json['GroupLevel'] ?? '',
      groupStatus: parseStatus(json['GroupStatus']),
      groupCreationDate:
          DateTime.tryParse(json['GroupCreationDate']?.toString() ?? '') ??
              DateTime.now(),
    );
  }

  /// Преобразует объект Group в Map (JSON) для отправки на сервер.
  Map<String, dynamic> toJson() {
    return {
      'groupName': groupName,
      'groupLevel': groupAccessLevel,
      'groupStatus': groupStatus,
    };
  }
}
