import { LightningElement } from "lwc";

export default class ExperianSearchForm extends LightningElement {
  searchOptions = [
    { label: "Business", value: "business" },
    { label: "Business & Owner (Blended)", value: "blended" }
  ];
  searchType = "business";
  bin = "";
  businessName = "";
  address = "";
  city = "";
  state = "";
  zip = "";
  country = "US";
  phone = "";
  taxId = "";
  reference = "";

  handleSearchTypeChange(event) {
    this.searchType = event.detail.value;
  }

  handleInputChange(event) {
    const field = event.target.dataset.id;
    this[field] = event.target.value;
  }

  handleSearch() {
    // Add your search logic here
    console.log(
      "Searching with:",
      this.bin,
      this.businessName,
      this.address,
      this.city,
      this.state,
      this.zip,
      this.country,
      this.phone,
      this.taxId,
      this.reference
    );
  }

  handleClear() {
    this.bin = "";
    this.businessName = "";
    this.address = "";
    this.city = "";
    this.state = "";
    this.zip = "";
    this.country = "US";
    this.phone = "";
    this.taxId = "";
    this.reference = "";
  }
}
