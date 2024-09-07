import { LightningElement, track, wire } from "lwc";
import getAlerts from "@salesforce/apex/ExperianAlertListController.getAlerts";
import getFilteredAlerts from "@salesforce/apex/ExperianAlertListController.getFilteredAlerts";
import updateAlertStatus from "@salesforce/apex/ExperianAlertListController.updateAlertStatus";

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

  @wire(getAlerts)
  wiredAlerts({ error, data }) {
    if (data) {
      this.alerts = data.map((alert) => ({
        ...alert,
        selected: false,
        statusClass: alert.Status__c.toLowerCase()
      }));
      this.filterAlerts();
    } else if (error) {
      console.error("Error fetching alerts:", error);
    }
  }

  filterAlerts() {
    getFilteredAlerts({
      searchTerm: this.searchTerm,
      selectedView: this.selectedView,
      selectedAlertTypes: this.selectedAlertTypes,
      daysAgo: this.selectedTimeframe
        ? parseInt(this.selectedTimeframe, 10)
        : null
    })
      .then((result) => {
        this.filteredAlerts = result.map((alert) => ({
          ...alert,
          selected: false,
          statusClass: alert.Status__c.toLowerCase()
        }));
      })
      .catch((error) => {
        console.error("Error filtering alerts:", error);
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
    this.filteredAlerts = this.filteredAlerts.map((alert) => {
      return alert.Id === alertId ? { ...alert, selected: isChecked } : alert;
    });
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
      this.selectedAlertTypes.push(alertType);
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
    this.filterAlerts();
  }

  markSelectedAsRead() {
    const selectedAlertIds = this.filteredAlerts
      .filter((alert) => alert.selected)
      .map((alert) => alert.Id);
    updateAlertStatus({ alertIds: selectedAlertIds, newStatus: "Read" })
      .then(() => {
        this.filterAlerts();
      })
      .catch((error) => {
        console.error("Error updating alert status:", error);
      });
  }

  deleteSelected() {
    // Note: Implement delete functionality if required
    console.log("Delete functionality not implemented");
  }

  markAsRead(event) {
    const alertId = event.target.dataset.id;
    updateAlertStatus({ alertIds: [alertId], newStatus: "Read" })
      .then(() => {
        this.filterAlerts();
      })
      .catch((error) => {
        console.error("Error updating alert status:", error);
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
    const csv = this.filteredAlerts
      .map((alert) =>
        [
          alert.Name,
          alert.Definition__c,
          alert.Alert_ID__c,
          alert.Priority__c,
          alert.Status__c
        ].join(",")
      )
      .join("\n");
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
