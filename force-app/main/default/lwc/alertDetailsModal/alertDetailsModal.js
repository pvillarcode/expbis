import { api } from "lwc";
import LightningModal from "lightning/modal";

export default class AlertDetailsModal extends LightningModal {
  @api content;

  get results() {
    return this.content?.results || {};
  }

  get monitoredBusiness() {
    return this.results.monitoredBusiness || {};
  }

  get endCustomerData() {
    return this.results.endCustomerData || {};
  }

  get accountTotals() {
    return this.results.t44to47Details?.accountTotals || {};
  }

  get formattedDate() {
    return this.results.date
      ? new Date(this.results.date).toLocaleDateString()
      : "";
  }

  connectedCallback() {
    console.log("AlertDetailsModal connected");
    console.log("Content received:", JSON.stringify(this.content, null, 2));
  }

  renderedCallback() {
    console.log("AlertDetailsModal rendered");
  }

  handleClose() {
    console.log("Close button clicked");
    this.close();
  }
}
