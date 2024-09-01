import { LightningElement, track, api } from "lwc";

export default class RpReportSelection extends LightningElement {
  @track value = "premier";
  @track selectedModel = "intelliscore";
  @track selectedDefaultOptions = ["useScoringModelDefault"];
  @track reportDescription = "";
  @api loading = false;
  @api business;

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

  scoringModelOptions = [
    { label: "INTELLISCORE PLUS V2", value: "intelliscore" },
    { label: "IPV3", value: "ipv3" },
    { label: "IPV3ML", value: "ipv3ml" }
  ];

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
  }

  handleReportChange(event) {
    this.value = event.detail.value;
    this.updateReportDescription(this.value);
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
