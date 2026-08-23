abstract final class ApiEndpoints {
  static const login = '/auth/login';
  static const refreshToken = '/auth/refresh';
  static const logout = '/auth/logout';

  static const products = '/master/products';
  static const outlets = '/master/outlets';
  static const routeAssignments = '/master/route-assignments';
  static const routeAssignmentsBulk = '/master/route-assignments/bulk';
  static const routeSales = '/master/route-sales';
  static const visits = '/visits';
  static const visitActivities = '/outlets';
  static const notifications = '/notifications';
  static const notificationDevices = '/notifications/devices';
  static const meetings = '/meetings';
  static const meetingJoinByCode = '/meetings/join-by-code';
  static const salesOrders = '/sales-orders';
  static const checkIns = '/visits/check-in';
  static const checkOuts = '/visits/check-out';
  static const purchases = '/purchases';
  static const returns = '/returns';
  static const gifts = '/gifts';
  static const outletNotes = '/outlet-notes';
  // A payment is posted to /receivables/{invoiceId}/payments. This base is
  // retained for UI code that resolves the selected invoice first.
  static const receivablePayments = '/receivables';
  static const deferVisit = '/visits/defer';
  static const cancelVisit = '/visits/cancel';
  static const visitApprovals = '/approvals/visits';
  static const dashboard = '/dashboard';
  static const approvals = '/approvals';
  static const serverState = '/sync/state';
  static const promotions = '/promotions';
  static const files = '/files';
  static const monitoringTeam = '/monitoring/team';
  static const monitoringLocations = '/monitoring/locations';
  static const monitoringActivities = '/monitoring/activities';
  static const reportsSummary = '/reports/summary';
  static const reportsVisitsCsv = '/reports/visits/export.csv';
  static const attachments = '/attachments';
  static const masterSnapshot = '/master/snapshot';
  static const routeEstimate = '/routes/estimate';
  static const journeys = '/journeys';
  static const currentJourney = '/journeys/current';
  static const deliveryNotes = '/delivery-notes';
}
