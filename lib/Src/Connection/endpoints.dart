abstract final class Endpoints {
  static const signIn = '/functions/v1-sign-in';
  static const signUp = '/functions/v1-sign-up';
  static const getUser = '/functions/v1-get-user';
  static const logout = '/logout';
  static const dashboardOverview = '/functions/v1-dashboard-overview';
  static const dashboardReportCatalog =
      '/functions/v1-dashboard-report-catalog';
  static const dashboardRunReport = '/functions/v1-dashboard-run-report';
  static const dashboardExportReport =
      '/functions/v1-dashboard-export-report';
  static const dashboardExportStatus =
      '/functions/v1-dashboard-export-status';
  static const dashboardSavePreferences =
      '/functions/v1-dashboard-save-preferences';
  static const dashboardSaveReport =
      '/functions/v1-dashboard-save-report';
  static const dashboardDeleteSavedReport =
      '/functions/v1-dashboard-delete-saved-report';
  static const ordersList = '/functions/v1-orders-list';
  static const ordersFormOptions = '/functions/v1-orders-form-options';
  static const ordersSearchClients = '/functions/v1-orders-search-clients';
  static const ordersSearchProducts = '/functions/v1-orders-search-products';
  static const ordersGet = '/functions/v1-orders-get';
  static const ordersSave = '/functions/v1-orders-save';
  static const ordersConfirm = '/functions/v1-orders-confirm';
  static const ordersPreview = '/functions/v1-orders-preview';
  static const ordersPdf = '/functions/v1-orders-pdf';
  static const ordersDocumentStatus =
      '/functions/v1-orders-document-status';
  static const ordersSendEmail = '/functions/v1-orders-send-email';
  static const ordersCancel = '/functions/v1-orders-cancel';
  static const ordersDuplicate = '/functions/v1-orders-duplicate';
  static const accountBootstrap = '/functions/v1-account-bootstrap';
  static const profileUpdate = '/functions/v1-profile-update';
  static const companySave = '/functions/v1-company-save';
  static const companyLogoUpload = '/functions/v1-company-logo-upload';
  static const accountUsersList = '/functions/v1-account-users-list';
  static const accountUserInvite = '/functions/v1-account-user-invite';
  static const accountUserUpdate = '/functions/v1-account-user-update';
  static const accountUserDeactivate =
      '/functions/v1-account-user-deactivate';
  static const paymentTermsList = '/functions/v1-payment-terms-list';
  static const paymentTermSave = '/functions/v1-payment-term-save';
  static const paymentTermDelete = '/functions/v1-payment-term-delete';
  static const billingCatalog = '/functions/v1-billing-catalog';
  static const billingCheckoutCreate =
      '/functions/v1-billing-checkout-create';
  static const billingCheckoutVerify =
      '/functions/v1-billing-checkout-verify';
  static const billingPortalCreate = '/functions/v1-billing-portal-create';
  static const billingSubscriptionCancel =
      '/functions/v1-billing-subscription-cancel';
  static const billingSubscriptionResume =
      '/functions/v1-billing-subscription-resume';
  static const clientsList = '/functions/v1-clients-list';
  static const clientsFormOptions = '/functions/v1-clients-form-options';
  static const clientsGet = '/functions/v1-clients-get';
  static const clientsSave = '/functions/v1-clients-save';
  static const clientsDelete = '/functions/v1-clients-delete';
  static const clientsPostalCodeLookup =
      '/functions/v1-clients-postal-code-lookup';
  static const clientsImport = '/functions/v1-clients-import';
  static const productsList = '/functions/v1-products-list';
  static const productsFormOptions = '/functions/v1-products-form-options';
  static const productsGet = '/functions/v1-products-get';
  static const productsSave = '/functions/v1-products-save';
  static const productsDelete = '/functions/v1-products-delete';
  static const productImageUpload = '/functions/v1-product-image-upload';
  static const productsImport = '/functions/v1-products-import';
  static const productsExport = '/functions/v1-products-export';
  static const productImagesDeleteAll =
      '/functions/v1-product-images-delete-all';
  static const tasksList = '/functions/v1-tasks-list';
  static const tasksFormOptions = '/functions/v1-tasks-form-options';
  static const tasksSearchClients = '/functions/v1-tasks-search-clients';
  static const tasksGet = '/functions/v1-tasks-get';
  static const tasksSave = '/functions/v1-tasks-save';
  static const tasksComplete = '/functions/v1-tasks-complete';
  static const tasksDelete = '/functions/v1-tasks-delete';
  static const tasksExport = '/functions/v1-tasks-export';
  static const logisticsBootstrap = '/functions/v1-logistics-bootstrap';
  static const routesList = '/functions/v1-routes-list';
  static const routesCandidates = '/functions/v1-routes-candidates';
  static const routesOptimize = '/functions/v1-routes-optimize';
  static const routesSave = '/functions/v1-routes-save';
  static const routesGet = '/functions/v1-routes-get';
  static const routesStart = '/functions/v1-routes-start';
  static const routeStopUpdate = '/functions/v1-route-stop-update';
  static const routesFinish = '/functions/v1-routes-finish';
  static const carriersList = '/functions/v1-carriers-list';
  static const carriersSave = '/functions/v1-carriers-save';
  static const carriersDelete = '/functions/v1-carriers-delete';
  static const trackingsList = '/functions/v1-trackings-list';
  static const trackingsSearchOrders =
      '/functions/v1-trackings-search-orders';
  static const trackingsSave = '/functions/v1-trackings-save';
  static const trackingsGet = '/functions/v1-trackings-get';
  static const trackingsRefresh = '/functions/v1-trackings-refresh';

  static String cloudFunction(String functionName) {
    return '/functions/$functionName';
  }
}
