import { LightningElement, api } from 'lwc';

export default class RpReportDisplay extends LightningElement {
  @api businessId;
  @api reportType;
  @api scoringModel;

  // Si necesitas botones para alguna acción adicional, puedes agregarlos aquí.
}
