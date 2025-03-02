import 'group.dart';
import 'package:wms/core/utils.dart';

class User {
  int userID;
  String userFullname;
  String userName;
  String userPassword;
  Group userGroup;
  String userAvatar;
  bool userStatus;
  DateTime userCreationDate;
  DateTime userLastLoginDate;

  User({
    required this.userID,
    required this.userFullname,
    required this.userName,
    required this.userPassword,
    required this.userGroup,
    required this.userAvatar,
    required this.userStatus,
    required this.userCreationDate,
    required this.userLastLoginDate,
  });

  /// Фабричный конструктор для создания объекта User из JSON.
  factory User.fromJson(Map<String, dynamic> json, Group group) {
    return User(
      userID: json['UserID'] ?? 0,
      userFullname: json['UserFullName'] ?? '',
      userName: json['UserUsername'] ?? '',
      userPassword: json['UserPassword'] ?? '',
      userGroup: group,
      userAvatar: json['UserAvatar'] ?? '',
      userStatus: parseStatus(json['UserStatus']),
      userCreationDate:
          DateTime.tryParse(json['UserCreationDate']?.toString() ?? '') ??
              DateTime.now(),
      userLastLoginDate:
          DateTime.tryParse(json['UserLastLoginDate']?.toString() ?? '') ??
              DateTime.now(),
    );
  }

  /// Преобразует объект User в JSON для отправки на сервер.
  Map<String, dynamic> toJson() {
    return {
      'userFullName': userFullname,
      'userUsername': userName,
      'userPassword': userPassword,
      'userAvatar': userAvatar,
      'userStatus': userStatus ? 1 : 0,
      'userCreationDate': userCreationDate.toIso8601String(),
      'userLastLoginDate': userLastLoginDate.toIso8601String(),
      'groupID': userGroup.groupID,
    };
  }
}
