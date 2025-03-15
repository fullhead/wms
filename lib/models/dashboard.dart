class DashboardStatistics {
  final int userCount;
  final int groupCount;
  final int productCount;
  final int categoryCount;
  final int receiveCount;
  final int issueCount;
  final int warehouseProductCount;
  final int filledCells;
  final int emptyCells;

  DashboardStatistics({
    required this.userCount,
    required this.groupCount,
    required this.productCount,
    required this.categoryCount,
    required this.receiveCount,
    required this.issueCount,
    required this.warehouseProductCount,
    required this.filledCells,
    required this.emptyCells,
  });

  factory DashboardStatistics.fromJson(Map<String, dynamic> json) {
    return DashboardStatistics(
      userCount: json['userCount'] as int,
      groupCount: json['groupCount'] as int,
      productCount: json['productCount'] as int,
      categoryCount: json['categoryCount'] as int,
      receiveCount: json['receiveCount'] as int,
      issueCount: json['issueCount'] as int,
      warehouseProductCount: json['warehouseProductCount'] as int,
      filledCells: json['filledCells'] as int,
      emptyCells: json['emptyCells'] as int,
    );
  }
}

class RecentReceive {
  final int receiveID;
  final int quantity;
  final int cellID;
  final String cellName;
  final DateTime receiveDate;
  final String productName;
  final String productImage;
  final String categoryName;

  RecentReceive({
    required this.receiveID,
    required this.quantity,
    required this.cellID,
    required this.cellName,
    required this.receiveDate,
    required this.productName,
    required this.productImage,
    required this.categoryName,
  });

  factory RecentReceive.fromJson(Map<String, dynamic> json) {
    return RecentReceive(
      receiveID: json['ReceiveID'] as int,
      quantity: json['quantity'] as int,
      cellID: json['CellID'] as int,
      cellName: json['CellName'] as String,
      receiveDate: DateTime.parse(json['ReceiveDate']),
      productName: json['ProductName'] as String,
      productImage: json['ProductImage'] as String,
      categoryName: json['CategoryName'] as String,
    );
  }
}

class RecentIssue {
  final int issueID;
  final int quantity;
  final int cellID;
  final String cellName;
  final DateTime issueDate;
  final String productName;
  final String productImage;
  final String categoryName;

  RecentIssue({
    required this.issueID,
    required this.quantity,
    required this.cellID,
    required this.cellName,
    required this.issueDate,
    required this.productName,
    required this.productImage,
    required this.categoryName,
  });

  factory RecentIssue.fromJson(Map<String, dynamic> json) {
    return RecentIssue(
      issueID: json['IssueID'] as int,
      quantity: json['quantity'] as int,
      cellID: json['CellID'] as int,
      cellName: json['CellName'] as String,
      issueDate: DateTime.parse(json['IssueDate']),
      productName: json['ProductName'] as String,
      productImage: json['ProductImage'] as String,
      categoryName: json['CategoryName'] as String,
    );
  }
}

class MostReceived {
  final String productName;
  final String categoryName;
  final int totalReceived;
  final DateTime lastReceiveTime;

  MostReceived({
    required this.productName,
    required this.categoryName,
    required this.totalReceived,
    required this.lastReceiveTime,
  });

  factory MostReceived.fromJson(Map<String, dynamic> json) {
    return MostReceived(
      productName: json['ProductName'] as String,
      categoryName: json['CategoryName'] as String,
      totalReceived: json['totalReceived'] as int,
      lastReceiveTime: DateTime.parse(json['lastReceiveTime']),
    );
  }
}

class MostIssued {
  final String productName;
  final String categoryName;
  final int totalIssued;
  final DateTime lastIssueTime;

  MostIssued({
    required this.productName,
    required this.categoryName,
    required this.totalIssued,
    required this.lastIssueTime,
  });

  factory MostIssued.fromJson(Map<String, dynamic> json) {
    return MostIssued(
      productName: json['ProductName'] as String,
      categoryName: json['CategoryName'] as String,
      totalIssued: json['totalIssued'] as int,
      lastIssueTime: DateTime.parse(json['lastIssueTime']),
    );
  }
}

class DashboardMonitoring {
  final List<RecentReceive> recentReceives;
  final List<RecentIssue> recentIssues;
  final List<MostReceived> mostReceived;
  final List<MostIssued> mostIssued;

  DashboardMonitoring({
    required this.recentReceives,
    required this.recentIssues,
    required this.mostReceived,
    required this.mostIssued,
  });

  factory DashboardMonitoring.fromJson(Map<String, dynamic> json) {
    var recentReceivesJson = json['recentReceives'] as List;
    var recentIssuesJson = json['recentIssues'] as List;
    var mostReceivedJson = json['mostReceived'] as List;
    var mostIssuedJson = json['mostIssued'] as List;

    return DashboardMonitoring(
      recentReceives:
          recentReceivesJson.map((e) => RecentReceive.fromJson(e)).toList(),
      recentIssues:
          recentIssuesJson.map((e) => RecentIssue.fromJson(e)).toList(),
      mostReceived:
          mostReceivedJson.map((e) => MostReceived.fromJson(e)).toList(),
      mostIssued: mostIssuedJson.map((e) => MostIssued.fromJson(e)).toList(),
    );
  }
}
