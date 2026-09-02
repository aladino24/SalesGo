enum AppRole {
  sales,
  marketing,
  supervisor,
  branchManager,
  keyAccountManager,
  it,
}

extension AppRoleExtension on AppRole {
  String get label {
    switch (this) {
      case AppRole.sales:
        return 'Sales';
      case AppRole.marketing:
        return 'Marketing';
      case AppRole.supervisor:
        return 'Supervisor';
      case AppRole.branchManager:
        return 'Branch Manager';
      case AppRole.keyAccountManager:
        return 'Key Account Manager';
      case AppRole.it:
        return 'IT Administrator';
    }
  }

  bool get isSuperUser => this == AppRole.it;
  bool get canApproveVisit => isSuperUser || this == AppRole.supervisor || this == AppRole.branchManager;
  bool get canApproveDeliveryNote => isSuperUser || this == AppRole.branchManager;
  bool get canApproveTransaction => isSuperUser || this == AppRole.supervisor || this == AppRole.branchManager;
  bool get canMonitorTeam => isSuperUser || this == AppRole.supervisor || this == AppRole.branchManager;
  bool get canViewBranchReports => isSuperUser || this == AppRole.supervisor || this == AppRole.branchManager;
  bool get canManageRoutes => isSuperUser || this == AppRole.supervisor || this == AppRole.branchManager;
  bool get canRequestNewOutlet => isSuperUser || this == AppRole.sales || this == AppRole.marketing || this == AppRole.supervisor || this == AppRole.branchManager;
}
