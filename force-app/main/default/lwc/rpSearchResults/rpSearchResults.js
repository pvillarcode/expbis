import { LightningElement, api } from 'lwc';

export default class RpSearchResults extends LightningElement {
  @api businessid;

  businesses = [
    {
      BIN: '798304266',
      name: 'EXPERIAN SERVICES CORP',
      address: '475 Anton Blvd, Costa Mesa, CA 926267037',
      matchingName: '',
      matchingAddress: '',
      contact: '(714) 830-7000',
      dataDepth: '15',
    },
    {
      BIN: '796744203',
      name: 'EXPERIAN INFORMATION SOLUTIONS, INC',
      address: '475 Anton Blvd, Costa Mesa, CA 926267037',
      matchingName: 'Experian',
      matchingAddress: '3160 Airway Ave, Costa Mesa, CA 92626-4608',
      contact: '(714) 830-7000',
      dataDepth: '50',
    },
    {
      BIN: '421298504',
      name: 'EXPERIAN MARKETING SOLUTIONS, LLC',
      address: '475 Anton Blvd Bldg D, Costa Mesa, CA 926267037',
      matchingName: '',
      matchingAddress: '',
      contact: '(714) 830-7000',
      dataDepth: '3',
    },
  ];

  handleSelectBusiness(event) {
    console.log(event.currentTarget.dataset.bin);
    const business = event.currentTarget.dataset.bin;
    this.dispatchEvent(
      new CustomEvent('businessselected', {
        detail: business,
      })
    );
  }
}
