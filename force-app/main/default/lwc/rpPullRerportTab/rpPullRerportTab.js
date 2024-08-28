import { LightningElement, track } from "lwc";
import getPDFReport from "@salesforce/apex/PullReport.getPDFReport";
import getJSONReport from "@salesforce/apex/PullReport.getJSONReport";
import savePDFToSalesforce from "@salesforce/apex/PullReport.savePDFToSalesforce";
import saveExperianInformation from "@salesforce/apex/PullReport.saveExperianInformation";

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
    this.handleGetReport();
  }

  async handleGetReport() {
    try {
      // Fetch the report using the existing getReport method

      const [pdfResult, jsonResult] = await Promise.all([
        getPDFReport(),
        getJSONReport()
      ]);

      const result = await getPDFReport();
      console.log("reportData:", result);

      // Assuming the result is JSON containing a base64 encoded PDF
      const jsonPDF = JSON.parse(pdfResult);
      const base64PDF = jsonPDF.results;

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

      const experianBusinessId = await saveExperianInformation({
        jsonData: jsonResult
      });

      console.log("Saved to Salesforce with ID: ", experianBusinessId);
    } catch (error) {
      console.error("Error handling PDF:", error);
    }
  }

  fetchReport() {
    getPDFReport()
      .then((result) => {
        console.log("reportHtml:", result);
        this.report = result;
      })
      .catch((error) => {
        console.error("Error fetching report:", error);
      });
  }
}
