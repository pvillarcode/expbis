import { LightningElement, api, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getAllDecisions from "@salesforce/apex/ExperianDecisionController.getAllDecisions";
import pullNewDecision from "@salesforce/apex/ExperianDecisionController.pullNewDecision";
import refreshApex from "@salesforce/apex";

export default class ExperianDecisions extends NavigationMixin(
  LightningElement
) {
  @api recordId;
  currentDecision = {};
  priorDecisions = [];
  error;

  @wire(getAllDecisions, { accountId: "$recordId" })
  wiredDecisions({ error, data }) {
    if (data) {
      this.processDecisions(data);
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.currentDecision = {};
      this.priorDecisions = [];
    }
  }

  processDecisions(decisions) {
    if (decisions && decisions.length > 0) {
      this.currentDecision = this.formatDecision(decisions[0]);
      this.priorDecisions = decisions
        .slice(1)
        .map((decision) => this.formatDecision(decision));
    } else {
      this.currentDecision = {};
      this.priorDecisions = [];
    }
  }

  formatDecision(decision) {
    return {
      id: decision.Id,
      date: decision.CreatedDate,
      score: decision.Score__c,
      decision: decision.Decision__c,
      creditLimit: decision.Credit_Limit__c,
      triggeredRule: decision.Triggered_Rule__c,
      statusClass: this.getStatusClass(decision.Decision__c),
      icon: this.getStatusIcon(decision.Decision__c)
    };
  }

  handleRowAction(event) {
    const recordId = event.detail.row.id;
    this.navigateToRecordPage(recordId);
  }

  navigateToRecordPage(recordId) {
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: recordId,
        objectApiName: "Experian_Decision__c",
        actionName: "view"
      }
    });
  }

  handleCurrentDecisionClick() {
    if (this.currentDecision.id) {
      this.navigateToRecordPage(this.currentDecision.id);
    }
  }

  formatDate(dateString) {
    if (!dateString) return "N/A";
    const date = new Date(dateString);
    return date.toISOString().split("T")[0];
  }

  getEmptyDecision() {
    return {
      id: "",
      date: "N/A",
      score: "N/A",
      decision: "N/A",
      creditLimit: "N/A",
      triggeredRule: "N/A",
      statusClass: "slds-text-color_weak",
      icon: "utility:help"
    };
  }

  handlePullNewDecision() {
    this.isLoading = true;
    pullNewDecision({ accountId: this.recordId })
      .then((result) => {
        if (result.success === false) {
          this.showToast("Error", result.message, "error");
        } else {
          // Refresh all decisions after pulling a new one
          refreshApex(this.wiredDecisionsResult);
        }
      })
      .then(() => {
        if (this.currentDecision) {
          const toastVariant = this.getToastVariant(
            this.currentDecision.decision
          );
          this.showToast(
            "New Decision",
            `Decision: ${this.currentDecision.decision}`,
            toastVariant
          );
        }
      })
      .catch((error) => {
        console.error("Error pulling new decision", error);
        this.showToast(
          "Error",
          "Failed to pull new decision: " + error.body.message,
          "error"
        );
      })
      .finally(() => {
        this.isLoading = false;
      });
  }

  getStatusClass(decision) {
    switch (decision.toUpperCase()) {
      case "APPROVE":
        return "slds-text-color_success";
      case "DECLINE":
        return "slds-text-color_error";
      case "MANUAL REVIEW":
        return "slds-text-color_warning";
      default:
        return "slds-text-color_weak";
    }
  }

  getStatusIcon(decision) {
    switch (decision.toUpperCase()) {
      case "APPROVE":
        return "utility:check";
      case "DECLINE":
        return "utility:close";
      case "MANUAL REVIEW":
        return "utility:warning";
      default:
        return "utility:help";
    }
  }

  getToastVariant(decision) {
    switch (decision.toUpperCase()) {
      case "APPROVE":
        return "success";
      case "DECLINE":
        return "error";
      case "MANUAL REVIEW":
        return "warning";
      default:
        return "info";
    }
  }

  showToast(title, message, variant) {
    const evt = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant
    });
    this.dispatchEvent(evt);
  }
}
