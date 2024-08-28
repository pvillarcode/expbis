import { LightningElement, api, track } from "lwc";

export default class RpReportDisplay extends LightningElement {
  @api businessId;
  @api reportType;
  @api scoringModel;
  @api
  get report() {
    return this._report;
  }
  set report(value) {
    this._report = value;
    if (value) {
      this.processAndDisplayReport();
    }
  }

  @track isReportLoaded = false;

  processAndDisplayReport() {
    if (this._report) {
      // Process the HTML content
      let processedHtml = this.processHtmlContent(this._report);
      console.log("processedHtml:", processedHtml);
      // Replace image URLs if needed
      processedHtml = this.replaceImageUrls(processedHtml);

      // Render the HTML content
      this.renderHtml(processedHtml);

      this.isReportLoaded = true;
    } else {
      this.isReportLoaded = false;
    }
  }

  processHtmlContent(htmlContent) {
    // Implement any necessary processing of the HTML content
    // For example, you might want to remove certain elements or modify the structure
    // This is a placeholder - implement your specific logic here
    return htmlContent;
  }

  replaceImageUrls(htmlContent) {
    // Replace image URLs if needed
    // This is a placeholder - implement your specific logic here
    return htmlContent.replace(
      /<img src="(https?:\/\/[^"]+)"/g,
      '<img src="/your-proxy-endpoint?url=$1"'
    );
  }

  renderHtml(htmlContent) {
    console.log("htmlContent:", htmlContent);
  }
}
