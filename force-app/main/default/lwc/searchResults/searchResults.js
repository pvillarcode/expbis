import { LightningElement, track } from "lwc";

export default class SearchResultsComponent extends LightningElement {
  @track searchResults = [
    {
      id: "1",
      bin: "798304266",
      businessName: "Experian Services Corp",
      address: "475 Anton Blvd, Costa Mesa, CA 926267037",
      matchingName: "Experian",
      matchingAddress: "475 Anton Blvd, Costa Mesa, CA 926267037",
      contact: "(714) 830-7000",
      dataDepth: 15
    },
    {
      id: "2",
      bin: "796744203",
      businessName: "Experian Information Solutions, Inc",
      address: "475 Anton Blvd, Costa Mesa, CA 926267037",
      matchingName: "Experian",
      matchingAddress: "3160 Airway Ave, Costa Mesa, CA 92626-4608",
      contact: "(714) 830-7000",
      dataDepth: 50
    },
    {
      id: "3",
      bin: "421298504",
      businessName: "Experian Marketing Solutions, LLC",
      address: "475 Anton Blvd Bldg D, Costa Mesa, CA 926267037",
      matchingName: "Experian",
      matchingAddress: "475 Anton Blvd Bldg D, Costa Mesa, CA 926267037",
      contact: "(714) 830-7000",
      dataDepth: 3
    }
  ];

  handleCloseSearch() {
    // Implement close search functionality
    console.log("Close search clicked");
  }
}
