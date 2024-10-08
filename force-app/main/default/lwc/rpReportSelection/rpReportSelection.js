import { LightningElement, track, api } from "lwc";

export default class RpReportSelection extends LightningElement {
  @track value = "premier";
  @track selectedModel = "intelliscore";
  @track selectedDefaultOptions = ["useScoringModelDefault"];
  @track reportDescription = "";
  @api loading = false;
  @api business;
  @api scoringModels = [];

  reportOptions = [
    { label: "Premier Profile", value: "premier" },
    { label: "DecisionIQ Credit", value: "decisionIQ" }
  ];

  reportDescriptions = {
    premier:
      "The Premier Profile Report is our most comprehensive business report providing views of business payment performance, public record history, fraud check, and company background information.",
    decisionIQ:
      "The DecisionIQ Credit report provides detailed credit analysis and risk assessment to make informed business decisions."
  };

  get scoringModelOptions() {
    return this.scoringModels.map((model) => ({
      label: model.Name,
      value: model.Model_Code__c
    }));
  }

  defaultOptions = [
    {
      label: "Use selected scoring model as default",
      value: "useScoringModelDefault"
    },
    { label: "Use selected report as default", value: "useReportDefault" }
  ];

  connectedCallback() {
    console.log(this.business);
    this.updateReportDescription(this.value);
    if (this.scoringModels.length > 0) {
      this.selectedModel = this.scoringModels[0].Model_Code__c;
    }
  }

  handleReportChange(event) {
    this.value = event.detail.value;
    this.updateReportDescription(this.value);
  }

  handleScoringModelChange(event) {
    this.selectedModel = event.detail.value;
    console.log(this.selectedModel);
    // Force refresh if needed
    this.template.querySelector("lightning-radio-group").value =
      this.selectedModel;
  }

  updateReportDescription(reportKey) {
    this.reportDescription =
      this.reportDescriptions[reportKey] ||
      "No description available for this report.";
  }

  handlePullReportClick() {
    const event = new CustomEvent("pullreport");
    this.dispatchEvent(event);
  }

  handleClearSearch() {
    const event = new CustomEvent("clearsearch");
    this.dispatchEvent(event);
  }
}
