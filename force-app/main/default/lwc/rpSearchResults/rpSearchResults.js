import { LightningElement, api } from "lwc";

export default class RpSearchResults extends LightningElement {
  @api businessid;

  @api businesses = [];

  get searchResultsCount() {
    return this.businesses.length;
  }

  handleSelectBusiness(event) {
    console.log(event.currentTarget.dataset.bin);
    const business = event.currentTarget.dataset.bin;
    this.dispatchEvent(
      new CustomEvent("businessselected", {
        detail: business
      })
    );
  }
}
