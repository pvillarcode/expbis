import { LightningElement, api } from "lwc";

export default class RpSearchResults extends LightningElement {
  @api businessid;

  @api businesses = [];
  selectedBusiness = null;

  get searchResultsCount() {
    return this.businesses.length;
  }

  handleSelectBusiness(event) {
    const selectedBin = event.currentTarget.dataset.bin;
    this.selectedBusiness = this.businesses.find(
      (business) => business.BIN === selectedBin
    );
    console.log("Selected Business:", this.selectedBusiness);
    this.dispatchEvent(
      new CustomEvent("businessselected", {
        detail: this.selectedBusiness
      })
    );
  }
}
