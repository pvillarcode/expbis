import { LightningElement, api } from 'lwc';

export default class RpReportSelection extends LightningElement {
  @api businessId;

  business = {
    BIN: '798304266',
    name: 'EXPERIAN SERVICES CORP',
    address: '475 ANTON BLVD, COSTA MESA, CA',
  };

  reportOptions = [{ label: 'DecisionIQ Credit', value: 'DecisionIQ Credit' }];

  scoringModelOptions = [
    { label: 'Intelliscore Plus', value: 'Intelliscore Plus' },
    { label: 'Intelliscore Plus Blended', value: 'Intelliscore Plus Blended' },
  ];

  decisionPolicyOptions = [
    { label: 'Policy 1', value: 'Policy1' },
    { label: 'Policy 2', value: 'Policy2' },
  ];

  handlePullReport() {
    const event = new CustomEvent('reportselected', {
      detail: {
        reportType: 'exampleReportType',
        scoringModel: 'exampleScoringModel',
      },
    });
    this.dispatchEvent(event);
  }
}
