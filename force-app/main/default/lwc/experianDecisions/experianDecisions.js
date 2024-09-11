import { LightningElement, api, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import initiateDecisionProcess from "@salesforce/apex/ExperianDecisionController.initiateDecisionProcess";
import pullDecisionForSelectedBusiness from "@salesforce/apex/ExperianDecisionController.pullDecisionForSelectedBusiness";
import getAllDecisions from "@salesforce/apex/ExperianDecisionController.getAllDecisions";
import { refreshApex } from "@salesforce/apex";
import BusinessSelectionModal from "c/businessSelectionModal";

export default class ExperianDecisions extends LightningElement {
  @api recordId;
  @track currentDecision = {};
  @track priorDecisions = [];
  @track isLoading = false;
  wiredDecisionsResult;
  lastDecisionId;

  columns = [
    { label: "Date", fieldName: "date", type: "text" },
    { label: "Score", fieldName: "score", type: "text" },
    { label: "Decision", fieldName: "decision", type: "text" },
    { label: "Credit Limit", fieldName: "creditLimit", type: "text" },
    { label: "Triggered Rule", fieldName: "triggeredRule", type: "text" }
  ];

  businessColumns = [
    { label: "Business Name", fieldName: "name", type: "text" },
    { label: "BIN", fieldName: "bin", type: "text" },
    { label: "Address", fieldName: "fullAddress", type: "text" },
    {
      type: "button",
      typeAttributes: {
        label: "Select",
        name: "select",
        title: "Select",
        disabled: false,
        value: "select",
        iconPosition: "left"
      }
    }
  ];

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
      const latestDecision = decisions[0];
      const formattedLatestDecision = this.formatDecision(latestDecision);

      if (
        !this.lastDecisionId ||
        this.lastDecisionId !== formattedLatestDecision.id
      ) {
        this.currentDecision = formattedLatestDecision;
        if (decisions.length > 1) {
          this.priorDecisions = decisions
            .slice(1)
            .map((decision) => this.formatDecision(decision));
        }
        this.lastDecisionId = formattedLatestDecision.id;
      }
    } else {
      this.currentDecision = this.getEmptyDecision();
      this.priorDecisions = [];
      this.lastDecisionId = null;
    }
    this.isLoading = false;
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
    console.log("dateString", dateString);
    if (!dateString) return "N/A";
    const date = new Date(dateString);
    return new Intl.DateTimeFormat("en-US", {
      year: "numeric",
      month: "short",
      day: "numeric"
    }).format(date);
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

  async handlePullNewDecision() {
    this.isLoading = true;
    try {
      const result = await initiateDecisionProcess({
        accountId: this.recordId
      });
      if (result.success === false) {
        this.showToast("Error", result.message, "error");
      } else if (result.businessResults) {
        // Show modal with business results
        const businessResults = this.processBusinessResults(
          result.businessResults
        );
        const selectedBusiness = await BusinessSelectionModal.open({
          size: "medium",
          businessResults: businessResults
        });
        if (selectedBusiness) {
          await this.pullDecisionForBusiness(selectedBusiness);
        }
      } else if (result.decision) {
        // Decision pulled for existing business
        this.processNewDecision(result.decision);
        this.showToast("Success", result.message, "success");
      }
    } catch (error) {
      console.error("Error initiating decision process", error);
      this.showToast(
        "Error",
        "Failed to initiate decision process: " + error.body.message,
        "error"
      );
    } finally {
      this.isLoading = false;
    }
  }

  async pullDecisionForBusiness(selectedBusiness) {
    try {
      const result = await pullDecisionForSelectedBusiness({
        accountId: this.recordId,
        bin: selectedBusiness.bin,
        businessName: selectedBusiness.name,
        street: selectedBusiness.street,
        city: selectedBusiness.city,
        state: selectedBusiness.state,
        zip: selectedBusiness.zip
      });

      if (result.success) {
        this.processNewDecision(result.decision);
      } else {
        this.showToast("Error", result.message, "error");
      }
    } catch (error) {
      console.error("Error pulling decision for selected business", error);
      this.showToast(
        "Error",
        "Failed to pull decision: " + error.body.message,
        "error"
      );
    }
  }

  processBusinessResults(results) {
    return results.map((business) => ({
      ...business,
      fullAddress: `${business.street}, ${business.city}, ${business.state} ${business.zip}`
    }));
  }

  handleBusinessSelection(event) {
    const selectedBusiness = this.businessResults.find(
      (business) => business.bin === event.detail.row.bin
    );
    this.isLoading = true;
    this.showModal = false;

    pullDecisionForSelectedBusiness({
      accountId: this.recordId,
      bin: selectedBusiness.bin,
      businessName: selectedBusiness.name,
      street: selectedBusiness.street,
      city: selectedBusiness.city,
      state: selectedBusiness.state,
      zip: selectedBusiness.zip
    })
      .then((result) => {
        if (result.success) {
          this.processNewDecision(result.decision);
          this.showToast("Success", result.message, "success");
        } else {
          this.showToast("Error", result.message, "error");
        }
      })
      .catch((error) => {
        console.error("Error pulling decision for selected business", error);
        this.showToast(
          "Error",
          "Failed to pull decision: " + error.body.message,
          "error"
        );
      })
      .finally(() => {
        this.isLoading = false;
      });
  }

  processNewDecision(decision) {
    console.log("decision", decision);
    const formattedDecision = this.formatDecision(decision);

    // Clear prior decisions if this is the first decision
    if (!this.lastDecisionId) {
      this.priorDecisions = [];
    } else {
      this.priorDecisions = [this.currentDecision, ...this.priorDecisions];
    }
    this.currentDecision = formattedDecision;
    this.lastDecisionId = formattedDecision.id;
    refreshApex(this.wiredDecisionsResult);

    // Determine toast variant based on decision
    const toastVariant = this.getToastVariant(formattedDecision.decision);
    this.showToast(
      "New Decision",
      `Decision: ${formattedDecision.decision}`,
      toastVariant
    );
  }

  closeModal() {
    this.showModal = false;
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
  get hasPriorDecisions() {
    return this.priorDecisions.length > 0;
  }
}
