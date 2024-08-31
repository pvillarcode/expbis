import { LightningElement, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";

export default class ExperianSearch extends NavigationMixin(LightningElement) {
  @api recordId;

  handleClick() {
    this[NavigationMixin.Navigate]({
      type: "standard__navItemPage",
      attributes: {
        apiName: "Experian_Search"
      },
      state: {
        c__recordId: this.recordId
      }
    });
  }
}
