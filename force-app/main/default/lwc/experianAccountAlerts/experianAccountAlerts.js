import { LightningElement, api, wire, track } from "lwc";
import getAccountAlertsAndStatus from "@salesforce/apex/ExperianAccountAlertsController.getAccountAlertsAndStatus";
import updateAccountAlertStatus from "@salesforce/apex/ExperianAccountAlertsController.updateAccountAlertStatus";
import getAlertDetails from "@salesforce/apex/ExperianAccountAlertsController.getAlertDetails";
import { refreshApex } from "@salesforce/apex";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import AlertDetailsModal from "c/alertDetailsModal";

export default class ExperianAccountAlerts extends LightningElement {
  @api recordId;
  @track alerts = [];
  @track accountName;
  @track alertStatus;
  @track isLoading = true;
  wiredAlertsResult;

  @wire(getAccountAlertsAndStatus, { accountId: "$recordId" })
  wiredAlerts(result) {
    this.wiredAlertsResult = result;
    this.isLoading = true;
    if (result.data) {
      this.accountName = result.data.accountName;
      this.alertStatus = result.data.alertStatus;
      this.alerts = result.data.alerts;
      this.isLoading = false;
      if (this.isUnread) {
        this.showToast(
          "Unread Alerts",
          "You have unread account alerts.",
          "warning"
        );
      }
    } else if (result.error) {
      this.handleError(result.error);
    }
  }

  get hasAlerts() {
    return this.alerts.length > 0;
  }

  get isUnread() {
    return this.alertStatus === "Unread";
  }

  get alertStatusClass() {
    return this.isUnread ? "slds-theme_error" : "slds-theme_success";
  }

  handleMarkAsRead() {
    if (this.isUnread) {
      this.isLoading = true;
      updateAccountAlertStatus({ accountId: this.recordId, newStatus: "Read" })
        .then(() => {
          this.showToast("Success", "Account alerts marked as read", "success");
          return refreshApex(this.wiredAlertsResult);
        })
        .catch((error) => {
          this.handleError(error);
        })
        .finally(() => {
          this.isLoading = false;
        });
    }
  }

  handleError(error) {
    console.error("Error:", error);
    let errorMessage = "An unexpected error occurred. Please try again.";
    if (error.body && error.body.message) {
      console.log("error.body.message:", error.body.message);
      errorMessage = error.body.message;
    } else if (error.message) {
      errorMessage = error.message;
      console.log("error.message:", error.message);
    }
    this.showToast("Error", errorMessage, "error");
    this.isLoading = false;
  }

  handleAlertClick(event) {
    event.preventDefault(); // Prevent default navigation
    const alertId = event.currentTarget.dataset.id;
    console.log("handleAlertClick called with alertId:", alertId);
    this.openModal(alertId);
  }

  showToast(title, message, variant) {
    this.dispatchEvent(
      new ShowToastEvent({
        title: title,
        message: message,
        variant: variant
      })
    );
  }

  async openModal(alertId) {
    console.log("openModal called with alertId:", alertId);
    this.isLoading = true;
    console.log("isLoading set to true");
    try {
      const result = await getAlertDetails({
        accountId: this.recordId,
        alertId: alertId
      });
      console.log("getAlertDetails result:", JSON.stringify(result, null, 2));
      if (result && result.success) {
        try {
          console.log("Attempting to open AlertDetailsModal");
          const modalResult = await AlertDetailsModal.open({
            size: "small",
            content: result
          });
          console.log(
            "AlertDetailsModal opened successfully, result:",
            modalResult
          );
        } catch (modalError) {
          console.error("Error opening modal:", modalError);
          console.error("Modal error stack:", modalError.stack);
          this.handleError(
            new Error(
              "Failed to open alert details modal: " + modalError.message
            )
          );
        }
      } else {
        throw new Error(result.comments || "Failed to retrieve alert details");
      }
    } catch (error) {
      console.error("Error in openModal:", error);
      console.error("Error stack:", error.stack);
      this.handleError(error);
    } finally {
      this.isLoading = false;
      console.log("isLoading set to false");
    }
  }
}
