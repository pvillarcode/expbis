import { LightningElement, track } from "lwc";
import getReport from "@salesforce/apex/PullReport.getReport";
import savePDFToSalesforce from "@salesforce/apex/PullReport.savePDFToSalesforce";

export default class RpPullReportTab extends LightningElement {
  @track currentPage = "rp-business-search";
  @track businessId;
  @track reportType;
  @track scoringModel;
  @track businesses = [];
  @track selectedBusiness;
  @track report;

  get isBussinessSearch() {
    return this.currentPage === "rp-business-search";
  }

  get isReportSelection() {
    return this.currentPage === "rp-report-selection";
  }

  get isReportDisplay() {
    return this.currentPage === "rp-report-display";
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
    //this.currentPage = 'rp-report-selection';
  }

  handleReportSelected(event) {
    this.reportType = event.detail.reportType;
    this.scoringModel = event.detail.scoringModel;
    this.currentPage = "rp-report-display";
    this.fetchReport();
  }

  handlePullReport() {
    this.currentPage = "rp-report-display";
    this.handleGetPDF();
  }

  async handleGetPDF() {
    try {
      // Fetch the report using the existing getReport method
      const result = await getReport();
      console.log("reportData:", result);

      // Assuming the result is JSON containing a base64 encoded PDF
      const jsonResult = JSON.parse(result);
      const base64PDF = jsonResult.results; // Adjust this if the key is different

      // Create a Blob from the Base64 encoded string
      const byteCharacters = atob(base64PDF);
      const byteNumbers = new Array(byteCharacters.length);
      for (let i = 0; i < byteCharacters.length; i++) {
        byteNumbers[i] = byteCharacters.charCodeAt(i);
      }
      const byteArray = new Uint8Array(byteNumbers);
      const blob = new Blob([byteArray], { type: "application/pdf" });

      // Create a URL for the Blob
      const url = window.URL.createObjectURL(blob);

      // Open the PDF in a new tab
      window.open(url, "_blank");

      // Save to Salesforce and link to Custom Object
      const fileName = "PremierProfile_" + new Date().getTime();
      const contentDocumentId = await savePDFToSalesforce({
        base64Data: base64PDF,
        fileName: fileName,
        customObjectId: this.recordId
      });
      console.log("Saved to Salesforce with ID: ", contentDocumentId);
    } catch (error) {
      console.error("Error handling PDF:", error);
    }
  }

  fetchReport() {
    getReport()
      .then((result) => {
        console.log("reportHtml:", result);
        this.report = result;
      })
      .catch((error) => {
        console.error("Error fetching report:", error);
      });
  }
}
