enum AppRole {
  sales,
  supervisor,
  branchManager,
  keyAccountManager,
}

extension AppRoleExtension on AppRole {
  String get label {
    switch (this) {
      case AppRole.sales:
        return 'Sales';
      case AppRole.supervisor:
        return 'Supervisor';
      case AppRole.branchManager:
        return 'Branch Manager';
      case AppRole.keyAccountManager:
        return 'Key Account Manager';
    }
  }

  bool get canApproveVisit => this == AppRole.supervisor || this == AppRole.branchManager;
  bool get canApproveDeliveryNote => this == AppRole.branchManager;
  bool get canApproveTransaction => this == AppRole.supervisor || this == AppRole.branchManager;
  bool get canMonitorTeam => this == AppRole.supervisor || this == AppRole.branchManager;
  bool get canViewBranchReports => this == AppRole.supervisor || this == AppRole.branchManager;
}
