import { LightningElement, api } from 'lwc';
import searchExperian from '@salesforce/apex/ExperianApiService.search';

export default class RpBusinessSearch extends LightningElement {
  @api businessid;

  searchOptions = [
    { label: 'Business', value: 'business' },
    { label: 'Business & Owner (Blended)', value: 'blended' },
  ];
  searchType = 'business';
  bin = '';
  businessName = '';
  address = '';
  city = '';
  state = '';
  zip = '';
  country = 'US';
  phone = '';
  taxId = '';
  reference = '';

  handleSearchTypeChange(event) {
    this.searchType = event.detail.value;
  }

  handleInputChange(event) {
    const field = event.target.dataset.id;
    this[field] = event.target.value;
  }

  handleSearch() {
    console.log(
      'Handle Business Search:',
      this.bin,
      this.businessName,
      this.address,
      this.city,
      this.state,
      this.zip,
      this.country,
      this.phone,
      this.taxId,
      this.reference
    );
    searchExperian({
      name: this.name,
      street: this.street,
      city: this.city,
      state: this.state,
      zip: this.zip,
      phone: this.phone,
      taxId: this.taxId,
    })
      .then((result) => {
        console.log(result);
        // Maneja la respuesta según sea necesario
      })
      .catch((error) => {
        console.error(error);
        // Maneja el error según sea necesario
      });
    // Add your search logic here

    const businessId = 'someBusinessId';
    this.dispatchEvent(
      new CustomEvent('onbusinesssearch', {
        detail: businessId,
      })
    );
  }
}
