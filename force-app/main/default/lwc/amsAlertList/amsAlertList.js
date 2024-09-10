import { LightningElement, track } from "lwc";
import getAlertsByAccount from "@salesforce/apex/ExperianAlertListController.getAlertsByAccount";
import getFilteredAlerts from "@salesforce/apex/ExperianAlertListController.getFilteredAlerts";
import updateAccountAlertStatus from "@salesforce/apex/ExperianAlertListController.updateAccountAlertStatus";

export default class AmsAlertList extends LightningElement {
  @track alerts = [];
  @track filteredAlerts = [];
  @track isFilterModalOpen = false;
  @track isDetailModalOpen = false;
  @track isCodeLegendModalOpen = false;
  @track selectedAlert = {};
  @track selectedView = "all";
  @track searchTerm = "";
  @track selectedTimeframe = "";
  @track selectedAlertTypes = [];
  @track isLoading = false;

  viewOptions = [
    { label: "View All AMS", value: "all" },
    { label: "Unread", value: "unread" },
    { label: "Read", value: "read" }
  ];

  timeframeOptions = [
    { label: "Last 60 days", value: "60" },
    { label: "Last 30 days", value: "30" },
    { label: "Custom", value: "custom" }
  ];

  alertTypes = [
    { label: "1+ Days Past Due", value: "L01" },
    { label: "31+ Days Past Due", value: "L31" },
    { label: "61+ Days Past Due", value: "L61" },
    { label: "91+ Days Past Due", value: "L91" },
    { label: "Activity Indicator Change", value: "AIC" },
    { label: "Address Change", value: "LAC" },
    { label: "Bankruptcy", value: "BBK" }
  ];

  connectedCallback() {
    this.loadAlerts();
  }

  loadAlerts() {
    this.isLoading = true;
    getAlertsByAccount()
      .then((result) => {
        this.alerts = this.processAlerts(result);
        this.filteredAlerts = [...this.alerts];
        this.isLoading = false;
      })
      .catch((error) => {
        console.error("Error fetching alerts:", error);
        this.isLoading = false;
      });
  }

  processAlerts(alerts) {
    return alerts.map((accountWrapper) => ({
      ...accountWrapper,
      statusClass:
        accountWrapper.alertStatus &&
        accountWrapper.alertStatus.toLowerCase() === "unread"
          ? "slds-badge unread"
          : "slds-badge read"
    }));
  }

  filterAlerts() {
    this.isLoading = true;
    getFilteredAlerts({
      searchTerm: this.searchTerm,
      selectedView: this.selectedView,
      selectedAlertTypes: this.selectedAlertTypes,
      daysAgo: this.selectedTimeframe
        ? parseInt(this.selectedTimeframe, 10)
        : null
    })
      .then((result) => {
        this.filteredAlerts = this.processAlerts(result);
        this.isLoading = false;
      })
      .catch((error) => {
        console.error("Error filtering alerts:", error);
        this.isLoading = false;
      });
  }

  handleViewChange(event) {
    this.selectedView = event.detail.value;
    this.filterAlerts();
  }

  handleSearch(event) {
    this.searchTerm = event.target.value;
    this.filterAlerts();
  }

  handleSelectAll(event) {
    const isChecked = event.target.checked;
    this.filteredAlerts = this.filteredAlerts.map((alert) => ({
      ...alert,
      selected: isChecked
    }));
  }

  handleSelectAlert(event) {
    const alertId = event.target.name;
    const isChecked = event.target.checked;
    this.filteredAlerts = this.filteredAlerts.map((alert) =>
      alert.Id === alertId ? { ...alert, selected: isChecked } : alert
    );
  }

  openFilterModal() {
    this.isFilterModalOpen = true;
  }

  closeFilterModal() {
    this.isFilterModalOpen = false;
  }

  openDetailModal(event) {
    const alertId = event.target.dataset.id;
    this.selectedAlert = this.filteredAlerts.find(
      (alert) => alert.Id === alertId
    );
    this.isDetailModalOpen = true;
  }

  closeDetailModal() {
    this.isDetailModalOpen = false;
  }

  openCodeLegendModal() {
    this.isCodeLegendModalOpen = true;
  }

  closeCodeLegendModal() {
    this.isCodeLegendModalOpen = false;
  }

  handleTimeframeChange(event) {
    this.selectedTimeframe = event.detail.value;
  }

  handleAlertTypeChange(event) {
    const alertType = event.target.value;
    const isChecked = event.target.checked;

    if (isChecked) {
      this.selectedAlertTypes = [...this.selectedAlertTypes, alertType];
    } else {
      this.selectedAlertTypes = this.selectedAlertTypes.filter(
        (type) => type !== alertType
      );
    }
  }

  applyFilters() {
    this.filterAlerts();
    this.closeFilterModal();
  }

  resetList() {
    this.selectedView = "all";
    this.searchTerm = "";
    this.selectedTimeframe = "";
    this.selectedAlertTypes = [];
    this.loadAlerts();
  }

  markSelectedAsRead() {
    const selectedAccountIds = this.filteredAlerts
      .filter((account) => account.selected)
      .map((account) => account.accountId);
    if (selectedAccountIds.length > 0) {
      this.updateAlertStatus(selectedAccountIds, "Read");
    } else {
      // Optionally, show a message that no accounts were selected
      console.log("No accounts selected to mark as read");
    }
  }

  markAsRead(event) {
    const accountId = event.target.dataset.id;
    this.updateAlertStatus([accountId], "Read");
  }

  updateAlertStatus(accountIds, newStatus) {
    this.isLoading = true;
    updateAccountAlertStatus({ accountIds, newStatus })
      .then(() => {
        // Update local data instead of reloading all alerts
        this.updateLocalAlertStatus(accountIds, newStatus);
        this.isLoading = false;
      })
      .catch((error) => {
        console.error("Error updating account alert status:", error);
        this.isLoading = false;
        // Handle error (e.g., show error toast)
      });
  }

  updateLocalAlertStatus(accountIds, newStatus) {
    this.filteredAlerts = this.filteredAlerts.map((alert) => {
      if (accountIds.includes(alert.accountId)) {
        return {
          ...alert,
          alertStatus: newStatus,
          statusClass:
            newStatus.toLowerCase() === "unread"
              ? "slds-badge unread"
              : "slds-badge read"
        };
      }
      return alert;
    });

    // If you're also maintaining a separate alerts array, update it too
    this.alerts = this.alerts.map((alert) => {
      if (accountIds.includes(alert.accountId)) {
        return {
          ...alert,
          alertStatus: newStatus,
          statusClass:
            newStatus.toLowerCase() === "unread"
              ? "slds-badge unread"
              : "slds-badge read"
        };
      }
      return alert;
    });
  }

  printAlerts() {
    window.print();
  }

  handleRowClick(event) {
    const alertId = event.currentTarget.dataset.id;
    if (!event.target.closest("lightning-input, lightning-button-menu")) {
      this.openDetailModal({ target: { dataset: { id: alertId } } });
    }
  }

  exportAlerts() {
    const headers = [
      "Business Name",
      "Alert Type",
      "Alert ID",
      "Priority",
      "Status"
    ];
    const csv = [
      headers.join(","),
      ...this.filteredAlerts.map((alert) =>
        [
          alert.Name,
          alert.Definition__c,
          alert.Alert_ID__c,
          alert.Priority__c,
          alert.Status__c
        ]
          .map((field) => `"${field}"`)
          .join(",")
      )
    ].join("\n");

    const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
    const link = document.createElement("a");
    if (link.download !== undefined) {
      const url = URL.createObjectURL(blob);
      link.setAttribute("href", url);
      link.setAttribute("download", "alerts.csv");
      link.style.visibility = "hidden";
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
    }
  }
}
