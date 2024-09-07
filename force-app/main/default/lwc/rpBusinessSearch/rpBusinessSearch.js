import { LightningElement, api, track } from "lwc";
import getLOS from "@salesforce/apex/BusinessSearch.getLOS";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class RpBusinessSearch extends LightningElement {
  @api businessid;
  @track _searchCriteria = {
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
  isLoading = false;

  stateOptions = [
    { label: "Alabama", value: "AL" },
    { label: "Alaska", value: "AK" },
    { label: "Arizona", value: "AZ" },
    { label: "Arkansas", value: "AR" },
    { label: "California", value: "CA" },
    { label: "Colorado", value: "CO" },
    { label: "Connecticut", value: "CT" },
    { label: "Delaware", value: "DE" },
    { label: "Florida", value: "FL" },
    { label: "Georgia", value: "GA" },
    { label: "Hawaii", value: "HI" },
    { label: "Idaho", value: "ID" },
    { label: "Illinois", value: "IL" },
    { label: "Indiana", value: "IN" },
    { label: "Iowa", value: "IA" },
    { label: "Kansas", value: "KS" },
    { label: "Kentucky", value: "KY" },
    { label: "Louisiana", value: "LA" },
    { label: "Maine", value: "ME" },
    { label: "Maryland", value: "MD" },
    { label: "Massachusetts", value: "MA" },
    { label: "Michigan", value: "MI" },
    { label: "Minnesota", value: "MN" },
    { label: "Mississippi", value: "MS" },
    { label: "Missouri", value: "MO" },
    { label: "Montana", value: "MT" },
    { label: "Nebraska", value: "NE" },
    { label: "Nevada", value: "NV" },
    { label: "New Hampshire", value: "NH" },
    { label: "New Jersey", value: "NJ" },
    { label: "New Mexico", value: "NM" },
    { label: "New York", value: "NY" },
    { label: "North Carolina", value: "NC" },
    { label: "North Dakota", value: "ND" },
    { label: "Ohio", value: "OH" },
    { label: "Oklahoma", value: "OK" },
    { label: "Oregon", value: "OR" },
    { label: "Pennsylvania", value: "PA" },
    { label: "Rhode Island", value: "RI" },
    { label: "South Carolina", value: "SC" },
    { label: "South Dakota", value: "SD" },
    { label: "Tennessee", value: "TN" },
    { label: "Texas", value: "TX" },
    { label: "Utah", value: "UT" },
    { label: "Vermont", value: "VT" },
    { label: "Virginia", value: "VA" },
    { label: "Washington", value: "WA" },
    { label: "West Virginia", value: "WV" },
    { label: "Wisconsin", value: "WI" },
    { label: "Wyoming", value: "WY" }
  ];

  searchOptions = [
    { label: "Business", value: "business" },
    { label: "Business & Owner (Blended)", value: "blended" }
  ];

  @api
  get searchCriteria() {
    return this._searchCriteria;
  }
  set searchCriteria(value) {
    this._searchCriteria = { ...value };
    this.updateInputFields();
  }

  updateInputFields() {
    Object.keys(this._searchCriteria).forEach((key) => {
      const input = this.template.querySelector(
        `lightning-input[data-id="${key}"]`
      );
      if (input) {
        input.value = this._searchCriteria[key];
      }
    });
  }

  handleSearchTypeChange(event) {
    this.searchType = event.detail.value;
  }

  handleInputChange(event) {
    const { name, value } = event.target;
    this._searchCriteria = { ...this._searchCriteria, [name]: value };
    if (name === "bin") {
      this.toggleRequiredFields(value);
    }
  }

  handleSearch() {
    if (this.validateFields()) {
      this.isLoading = true;
      getLOS({
        searchCriteria: this._searchCriteria
      })
        .then((result) => {
          const processedResults = this.processSearchResults(result);
          console.log("Raw result:", result);
          if (result.length === 0) {
            this.showToast(
              "Information",
              "Experian's extensive database does not show any records that match your inquiry.",
              "info"
            );
          } else {
            console.log("Processed result:", processedResults);
          }
          this.dispatchEvent(
            new CustomEvent("businesssearched", {
              detail: processedResults
            })
          );
        })
        .catch((error) => {
          this.showToast(
            "Error on search results response",
            error.body.message,
            "error"
          );
          console.error(error);
        })
        .finally(() => {
          this.isLoading = false;
        });
    }
  }

  validateFields() {
    const allValid = [
      ...this.template.querySelectorAll("lightning-input, lightning-combobox")
    ].reduce((validSoFar, inputCmp) => {
      inputCmp.reportValidity();
      return validSoFar && inputCmp.checkValidity();
    }, true);

    const binValid = this.validateBin();
    const zipValid = this.validateZip();
    if (!allValid || !binValid || !zipValid) {
      console.log("Please fill out all required fields correctly.");
      return false;
    }

    return true;
  }

  validateBin() {
    const binInput = this.template.querySelector(
      'lightning-input[data-id="bin"]'
    );
    const binValue = binInput.value;

    if (binValue && !/^\d+$/.test(binValue)) {
      binInput.setCustomValidity("BIN must be numeric.");
      binInput.reportValidity();
      return false;
    }

    binInput.setCustomValidity("");
    binInput.reportValidity();
    return true;
  }

  validateZip() {
    const zipInput = this.template.querySelector(
      'lightning-input[data-id="zip"]'
    );
    const zipValue = zipInput.value;

    if (zipValue && !/^\d{5}$/.test(zipValue)) {
      zipInput.setCustomValidity("ZIP code must be 5 digits.");
      zipInput.reportValidity();
      return false;
    }
    zipInput.setCustomValidity("");
    zipInput.reportValidity();
    return true;
  }

  processSearchResults(results) {
    return results.map((group) => {
      const business = group; // Assuming only one business per group
      console.log("Processing Business:", business);
      return {
        BIN: business.bin,
        name: business.name,
        address: business.address,
        city: business.city,
        state: business.state,
        zip: business.zip,
        tradelines: business.numberOfTradelines,
        contact: business.phone,
        bankDataIndicator: business.bankDataIndicator,
        executiveSummaryIndicator: business.executiveSummaryIndicator,
        financialStatementIndicator: business.financialStatementIndicator,
        governmentDataIndicator: business.governmentDataIndicator,
        inquiryIndicator: business.inquiryIndicator,
        keyFactsIndicator: business.keyFactsIndicator,
        reliabilityCode: business.reliabilityCode,
        uccIndicator: business.uccIndicator
      };
    });
  }

  handleClearSearch() {
    const event = new CustomEvent("clearsearch");
    this.dispatchEvent(event);
  }

  toggleRequiredFields(binValue) {
    const requiredFields = this.template.querySelectorAll("[data-required]");
    requiredFields.forEach((field) => {
      field.required = !binValue;
    });
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
