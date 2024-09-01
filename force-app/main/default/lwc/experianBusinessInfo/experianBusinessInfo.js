import { LightningElement, wire, track } from "lwc";
import { CurrentPageReference } from "lightning/navigation";
import getExperianBusinessInfo from "@salesforce/apex/ExperianBusinessController.getExperianBusinessInfo";

export default class ExperianBusinessInfo extends LightningElement {
  accountId;
  @track experianBusinessRecords = {
    Commercial_Score__c: "N/A",
    FSR_Score__c: "N/A",
    Credit_Limit_Recommendation__c: "N/A",
    Days_Beyond_Terms__c: "N/A",
    Derogatory_Legal__c: "0",
    Fraud_Alerts__c: "N/A",
    Industry_DBT__c: "N/A"
  };

  @wire(CurrentPageReference)
  currentPageReference(currentPageReference) {
    if (currentPageReference && currentPageReference.attributes.recordId) {
      this.accountId = currentPageReference.attributes.recordId;
      console.log("Account Id: ", this.accountId);
      this.loadExperianBusinessData();
    } else {
      console.error("No Account Id provided");
    }
  }

  get recordId() {
    return this.currentPageReference?.attributes?.recordId || null;
  }

  loadExperianBusinessData() {
    if (!this.accountId) {
      console.error("No Account Id provided");
      return;
    }

    getExperianBusinessInfo({ accountId: this.accountId })
      .then((result) => {
        if (result && result.length > 0) {
          this.experianBusinessRecords = result[0]; // Assuming result is an array and we need the first record
        } else {
          this.experianBusinessRecords = {}; // Handle case where no records are returned
        }
        console.log("Experian Business Data: ", result);
      })
      .catch((error) => {
        console.error("Error loading Experian Business data", error);
      });
  }

  get intelliscore() {
    return this.experianBusinessRecords.Commercial_Score__c || "N/A";
  }

  get financialStabilityRisk() {
    return this.experianBusinessRecords.FSR_Score__c || "N/A";
  }

  get creditLimitRecommendation() {
    return (
      this.experianBusinessRecords.Commercial_Credit_Limit_Recommendation__c ||
      "N/A"
    );
  }

  get daysBeyondTerms() {
    return this.experianBusinessRecords.Days_Beyond_Terms__c || "N/A";
  }

  get derogatoryLegal() {
    return this.experianBusinessRecords.Derogatory_Legal__c || "0";
  }

  get fraudAlerts() {
    return this.experianBusinessRecords.Fraud_Alerts__c || "N/A";
  }

  get industryDbt() {
    return this.experianBusinessRecords.Industry_DBT__c || "N/A";
  }
}
