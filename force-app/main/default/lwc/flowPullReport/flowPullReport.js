import { LightningElement, api } from "lwc";

export default class FlowPullReport extends LightningElement {
  @api accountId;
  @api businessName;
  @api address;
  @api city;
  @api state;
  @api zip;

  @api
  validate() {
    // Perform any necessary validation
    return { isValid: true };
  }
}
