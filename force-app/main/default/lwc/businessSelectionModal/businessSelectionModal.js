import { api } from "lwc";
import LightningModal from "lightning/modal";

export default class BusinessSelectionModal extends LightningModal {
  @api businessResults;

  columns = [
    { label: "Business Name", fieldName: "name", type: "text" },
    { label: "BIN", fieldName: "bin", type: "text" },
    { label: "Address", fieldName: "fullAddress", type: "text" },
    { label: "Phone", fieldName: "phone", type: "phone" },
    {
      label: "Reliability Code",
      fieldName: "reliabilityCode",
      type: "number",
      cellAttributes: { alignment: "left" }
    },
    {
      type: "button",
      typeAttributes: {
        label: "Select",
        name: "select",
        title: "Select",
        disabled: false,
        value: "select",
        iconPosition: "left"
      }
    }
  ];

  handleRowAction(event) {
    const selectedBusiness = this.businessResults.find(
      (business) => business.bin === event.detail.row.bin
    );
    this.close(selectedBusiness);
  }

  handleCancel() {
    this.close();
  }
}
