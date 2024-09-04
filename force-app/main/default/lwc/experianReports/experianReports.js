import { LightningElement, api, wire, track } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getExperianReports from "@salesforce/apex/ExperianReportsController.getExperianReports";

const COLUMNS = [
  {
    label: "FILE NAME",
    fieldName: "Name",
    type: "button",
    typeAttributes: {
      label: { fieldName: "Name" },
      name: "view_file",
      title: "Click to View File",
      variant: "base"
    },
    cellAttributes: {
      class: { fieldName: "titleClass" }
    }
  },
  {
    label: "DATE",
    fieldName: "CreatedDate",
    type: "date",
    sortable: true,
    typeAttributes: {
      year: "numeric",
      month: "long",
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit"
    }
  },
  {
    label: "REPORT PULLED BY",
    fieldName: "CreatedByName",
    type: "text",
    sortable: true
  }
];

export default class ExperianReports extends NavigationMixin(LightningElement) {
  @api recordId;
  @track reports = [];
  @track error;
  @track currentPage = 1;
  @track pageSize = 5;
  @track totalRecords = 0;
  @track sortBy;
  @track sortDirection;

  columns = COLUMNS;
  isLoading = true;

  wiredReportsResult;

  @wire(getExperianReports, {
    accountId: "$recordId",
    pageSize: "$pageSize",
    pageNumber: "$currentPage"
  })
  wiredReports(result) {
    console.log("wiredReports called");
    console.log(this.accountId);
    this.wiredReportsResult = result;
    this.isLoading = true;
    const { data, error } = result;
    if (data) {
      console.log("Received data:", data);
      this.reports = this.transformData(data.records);
      this.totalRecords = data.totalRecords;
      this.error = undefined;
    } else if (error) {
      console.error("Error loading reports:", error);
      this.handleError(error);
    }
    this.isLoading = false;
  }

  transformData(data) {
    if (!Array.isArray(data)) {
      console.error("transformData received non-array data:", data);
      return [];
    }
    return data.map((report) => ({
      Id: report.Id,
      Name: report.Name,
      CreatedDate: report.CreatedDate,
      CreatedByName: report.CreatedBy.Name,
      ContentDocumentId:
        report.ContentDocumentLinks && report.ContentDocumentLinks.length > 0
          ? report.ContentDocumentLinks[0].ContentDocumentId
          : null,
      FileType:
        report.ContentDocumentLinks && report.ContentDocumentLinks.length > 0
          ? report.ContentDocumentLinks[0].ContentDocument.FileType
          : null,
      titleClass: "slds-text-link"
    }));
  }

  handleRowAction(event) {
    const actionName = event.detail.action.name;
    const row = event.detail.row;

    if (actionName === "view_file") {
      this.viewFile(row.ContentDocumentId);
    }
  }

  viewFile(contentDocumentId) {
    if (contentDocumentId) {
      this[NavigationMixin.Navigate]({
        type: "standard__namedPage",
        attributes: {
          pageName: "filePreview"
        },
        state: {
          selectedRecordId: contentDocumentId
        }
      });
    } else {
      this.showToast("Error", "No file associated with this report", "error");
    }
  }

  handleError(error) {
    console.error("Error:", error);
    this.error = error.body?.message || "Unknown error occurred";
    this.reports = undefined;
    this.showToast("Error", this.error, "error");
  }

  showToast(title, message, variant) {
    const evt = new ShowToastEvent({ title, message, variant });
    this.dispatchEvent(evt);
  }

  // Pagination methods
  get totalPages() {
    return Math.ceil(this.totalRecords / this.pageSize);
  }

  get isFirstPage() {
    return this.currentPage === 1;
  }

  get isLastPage() {
    return this.currentPage === this.totalPages || this.totalPages === 0;
  }

  previousPage() {
    if (!this.isFirstPage) {
      this.currentPage -= 1;
    }
  }

  nextPage() {
    if (!this.isLastPage) {
      this.currentPage += 1;
    }
  }

  get pageInfo() {
    if (this.totalRecords === 0) return "0-0 of 0";
    const start = (this.currentPage - 1) * this.pageSize + 1;
    const end = Math.min(start + this.pageSize - 1, this.totalRecords);
    return `${start}-${end} of ${this.totalRecords}`;
  }
}
