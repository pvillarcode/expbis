import { LightningElement, api, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getPDFReport from "@salesforce/apex/ExperianBOPController.pullAndSaveBOPReport";
import { CloseActionScreenEvent } from "lightning/actions";
import { NavigationMixin } from "lightning/navigation";

export default class ExperianBOP extends NavigationMixin(LightningElement) {
  @api recordId; // To store the Account Id
  @track formData = {
    ownerLastName: "",
    ownerFirstName: "",
    ownerMiddleName: "",
    ownerGenerationCode: "",
    ssn: "",
    street: "",
    city: "",
    state: "",
    zip: ""
  };
  isLoading = false;

  handleSubmit(event) {
    event.preventDefault();
    this.isLoading = true;
    console.log("Form submitted", JSON.stringify(this.formData));
    getPDFReport({
      formData: JSON.stringify(this.formData),
      accountId: this.recordId
    })
      .then((result) => {
        console.log("Result:", result);

        // Download the PDF in a new tab
        //this.openPdfInNewTab(result);
        this.openPdfInViewer(result);

        // Show success toast
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Success",
            message: "BOP Report pulled successfully",
            variant: "success"
          })
        );
      })
      .catch((error) => {
        console.error("Error:", error);
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Error",
            message: "An error occurred while pulling the BOP Report",
            variant: "error"
          })
        );
      })
      .finally(() => {
        this.isLoading = false;
      });
  }

  openPdfInNewTab(contentDocumentId) {
    window.open(
      `/sfc/servlet.shepherd/document/download/${contentDocumentId}`,
      "_blank"
    );
  }

  openPdfInViewer(contentDocumentId) {
    this[NavigationMixin.Navigate](
      {
        type: "standard__namedPage",
        attributes: {
          pageName: "filePreview"
        },
        state: {
          selectedRecordId: contentDocumentId
        }
      },
      true
    ); // Set true to open in a new tab
  }

  handleInputChange(event) {
    this.formData[event.target.name] = event.target.value;
  }

  handleCancel() {
    this.closeModal();
  }

  closeModal() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }
}
