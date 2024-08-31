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
      ...this.template.querySelectorAll("lightning-input")
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
