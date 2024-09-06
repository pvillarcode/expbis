import { LightningElement, track, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getAccountDetails from "@salesforce/apex/BusinessSearch.getAccountDetails";
import getScoringModels from "@salesforce/apex/PullReport.getScoringModels";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import pullAndProcessReport from "@salesforce/apex/PullReport.pullAndProcessReport";
import { CurrentPageReference } from "lightning/navigation";

export default class RpPullReportTab extends NavigationMixin(LightningElement) {
  accountId;
  @track currentPage = "rp-business-search";
  @track businessId;
  @track reportType;
  @track scoringModel;
  @track scoringModels = [];
  @track businesses = [];
  @track selectedBusiness;
  @track report;
  @track isLoading;
  @track accountData;
  @track searchCriteria = {
    bin: "",
    businessName: "",
    address: "",
    city: "",
    state: "",
    zip: "",
    country: "US",
    phone: "",
    taxId: "",
    reference: ""
  };

  @wire(CurrentPageReference)
  getStateParameters(currentPageReference) {
    if (currentPageReference && currentPageReference.state.c__recordId) {
      this.accountId = currentPageReference.state.c__recordId;
      this.loadAccountData();
    }
    this.loadScoringModels();
  }

  loadScoringModels() {
    getScoringModels()
      .then((result) => {
        this.scoringModels = result;
        console.log("Scoring Models:", this.scoringModels);
      })
      .catch((error) => {
        console.error("Error loading scoring models", error);
        this.showToast("Error", "Failed to load scoring models", "error");
      });
  }

  connectedCallback() {
    this.loadAccountData();
  }

  loadAccountData() {
    let accountId = this.accountId;
    if (accountId === undefined || accountId === null || accountId === "") {
      console.log("accountId is null or undefined");
      return;
    }

    console.log("loadAccountData(accountId: " + accountId + ")");
    this.handleClearSearch();
    getAccountDetails({ accountId: accountId })
      .then((result) => {
        this.accountData = result;
        this.populateBusinessSearch();
      })
      .catch((error) => {
        console.error("Error loading account data", error);
        this.showToast("Error", "Failed to load account data", "error");
      });
  }

  populateBusinessSearch() {
    if (this.accountData) {
      this.searchCriteria = {
        businessName: this.accountData.Name,
        address: this.accountData.BillingStreet,
        city: this.accountData.BillingCity,
        state: this.accountData.BillingState,
        zip: this.accountData.BillingPostalCode,
        country: this.accountData.BillingCountry || "US",
        phone: this.accountData.Phone,
        bin: "",
        taxId: "",
        reference: ""
      };
    }
  }

  get isBussinessSearch() {
    return this.currentPage === "rp-business-search";
  }

  get isReportSelection() {
    return this.currentPage === "rp-report-selection";
  }

  get isReportDisplay() {
    return this.currentPage === "rp-report-display";
  }

  handleClearSearch() {
    this.currentPage = "rp-business-search";
    this.searchCriteria = {};
    this.businesses = [];
    console.log("handle Clear Search");
    // Reset other variables as needed
  }

  handleBusinessSelect(event) {
    this.selectedBusiness = event.detail;
    console.log("selectedBusiness in reportab js:", this.selectedBusiness);
    this.currentPage = "rp-report-selection";
  }

  handleBusinessSearched(event) {
    console.log("on handle business search");
    this.businesses = event.detail;
    console.log("businesses:", this.businesses);
  }

  handleReportSelected(event) {
    this.reportType = event.detail.reportType;
    this.scoringModel = event.detail.scoringModel;
    this.currentPage = "rp-report-display";
  }

  handlePullReport() {
    this.isLoading = true;
    console.log("Pulling report for businessId:", this.selectedBusiness);
    pullAndProcessReport({
      jsonData: JSON.stringify(this.selectedBusiness),
      accountId: this.accountId
    })
      .then((result) => {
        console.log("Report generated and saved successfully:", result);
        this.showToast(
          "Success",
          "Report generated and saved successfully",
          "success"
        );
        this.navigateToRecord(result.accountId);
      })
      .catch((error) => {
        console.log("Error pulling the report:", error);
        this.showToast(
          "Error",
          "Failed to generate or save report: " + error.body.message,
          "error"
        );
      })
      .finally(() => {
        this.isLoading = false;
        this.handleClearSearch();
      });
  }

  /*
  async handleGetReport(jsonBusiness) {
    try {
      this.isLoading = true;
      const [pdfResult, jsonResult] = await Promise.all([
        getPDFReport(jsonBusiness),
        getJSONReport(jsonBusiness)
      ]);

      const jsonPDF = JSON.parse(pdfResult);
      const base64PDF = jsonPDF.results;

      const byteCharacters = atob(base64PDF);
      const byteNumbers = new Array(byteCharacters.length);
      for (let i = 0; i < byteCharacters.length; i++) {
        byteNumbers[i] = byteCharacters.charCodeAt(i);
      }
      const byteArray = new Uint8Array(byteNumbers);
      const blob = new Blob([byteArray], { type: "application/pdf" });

      const url = window.URL.createObjectURL(blob);
      window.open(url, "_blank");

      const accountId = await saveExperianInformation({
        jsonData: jsonResult
      });
      console.log("Saved to Salesforce with for account ID: ", accountId);

      if (accountId) {
        const fileName = "PremierProfile_" + new Date().getTime();
        try {
          const contentDocumentId = await savePDFToSalesforce({
            base64Data: base64PDF,
            fileName: fileName,
            accountId: accountId
          });
          console.log("Saved to Salesforce with ID: ", contentDocumentId);
        } catch (error) {
          console.error("Error saving PDF to Salesforce:", error);
          this.showToast("Error", "Failed to save PDF to Salesforce", "error");
        }
      }
      this.isLoading = false;

      this.showToast(
        "Success",
        "Report generated and saved successfully",
        "success"
      );
      this.handleClearSearch();

      // Redirect to the experianBusinessId record page
      this[NavigationMixin.Navigate]({
        type: "standard__recordPage",
        attributes: {
          recordId: accountId,
          objectApiName: "ExperianBusiness__c", // Replace with the actual API name of the object
          actionName: "view"
        }
      });
    } catch (error) {
      this.showToast("Error", "Failed to generate or save report", "error");
      console.error("Error handling PDF:", error);
      this.isLoading = false;
    }
  }*/

  navigateToRecord(accountId) {
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: accountId,
        objectApiName: "Account",
        actionName: "view"
      }
    });
  }
  showToast(title, message, variant) {
    const event = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant
    });
    this.dispatchEvent(event);
  }
}
