import { LightningElement, track, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getPDFReport from "@salesforce/apex/PullReport.getPDFReport";
import getJSONReport from "@salesforce/apex/PullReport.getJSONReport";
import savePDFToSalesforce from "@salesforce/apex/PullReport.savePDFToSalesforce";
import saveExperianInformation from "@salesforce/apex/PullReport.saveExperianInformation";
import getAccountDetails from "@salesforce/apex/BusinessSearch.getAccountDetails";
import getScoringModels from "@salesforce/apex/PullReport.getScoringModels";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { CurrentPageReference } from "lightning/navigation";

export default class RpPullReportTab extends NavigationMixin(LightningElement) {
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

  loadAccountData() {
    this.handleClearSearch();
    getAccountDetails({ accountId: this.accountId })
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
    console.log("Pulling report for businessId:", this.selectedBusiness);
    const jsonBusiness = { jsonData: JSON.stringify(this.selectedBusiness) };
    this.handleGetReport(jsonBusiness);
  }

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

      const experianBusinessId = await saveExperianInformation({
        jsonData: jsonResult
      });
      console.log("Saved to Salesforce with ID: ", experianBusinessId);

      if (experianBusinessId) {
        const fileName = "PremierProfile_" + new Date().getTime();
        try {
          const contentDocumentId = await savePDFToSalesforce({
            base64Data: base64PDF,
            fileName: fileName,
            customObjectId: experianBusinessId
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
          recordId: experianBusinessId,
          objectApiName: "ExperianBusiness__c", // Replace with the actual API name of the object
          actionName: "view"
        }
      });
    } catch (error) {
      this.showToast("Error", "Failed to generate or save report", "error");
      console.error("Error handling PDF:", error);
      this.isLoading = false;
    }
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
