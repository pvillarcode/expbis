import { LightningElement, api, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { CloseActionScreenEvent } from "lightning/actions";

export default class ExperianBOP extends LightningElement {
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

  handleSubmit(event) {
    event.preventDefault();
    // Here you would typically call an Apex method to save the data
    console.log("Form submitted", this.formData);
    // Show a success toast
    this.dispatchEvent(
      new ShowToastEvent({
        title: "Success",
        message: "Form submitted successfully",
        variant: "success"
      })
    );
    // Close the modal
    this.closeModal();
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
