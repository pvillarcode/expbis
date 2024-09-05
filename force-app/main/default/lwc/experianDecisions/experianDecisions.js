import { LightningElement, api, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import pullNewDecision from "@salesforce/apex/ExperianDecisionController.pullNewDecision";
import getAllDecisions from "@salesforce/apex/ExperianDecisionController.getAllDecisions";
import { refreshApex } from "@salesforce/apex";

export default class DecisionHistory extends LightningElement {
  @api recordId;
  @api accountId;
  currentDecision = {};
  priorDecisions = [];
  isLoading = false;
  wiredDecisionsResult;

  @wire(getAllDecisions, { accountId: "$recordId" })
  wiredDecisions(result) {
    this.wiredDecisionsResult = result;
    const { error, data } = result;
    if (data) {
      this.processDecisions(data);
    } else if (error) {
      console.error("Error fetching decisions", error);
      this.showToast(
        "Error",
        "Failed to fetch decisions: " + error.body.message,
        "error"
      );
    }
  }

  processDecisions(decisions) {
    if (decisions && decisions.length > 0) {
      this.currentDecision = this.formatDecision(decisions[0]);
      this.priorDecisions = decisions
        .slice(1)
        .map((decision) => this.formatDecision(decision));
    } else {
      this.currentDecision = this.getEmptyDecision();
      this.priorDecisions = [];
    }
  }

  formatDecision(decision) {
    return {
      id: decision.Id,
      date: this.formatDate(decision.CreatedDate),
      score: decision.Score__c,
      decision: decision.Decision__c,
      creditLimit: decision.Credit_Limit__c,
      triggeredRule: decision.Triggered_Rule__c,
      statusClass: this.getStatusClass(decision.Decision__c),
      icon: this.getStatusIcon(decision.Decision__c)
    };
  }

  formatDate(dateString) {
    if (!dateString) return "N/A";
    const date = new Date(dateString);
    return new Intl.DateTimeFormat("en-US", {
      year: "numeric",
      month: "short",
      day: "numeric"
    }).format(date);
  }

  formatCurrency(amount) {
    if (!amount) return "N/A";
    console.log(amount);
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency: "USD"
    }).format(amount);
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
        return "utility:success";
      case "DECLINE":
        return "utility:error";
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
