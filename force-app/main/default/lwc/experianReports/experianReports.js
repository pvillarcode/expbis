import { LightningElement, api, wire, track } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getExperianReports from "@salesforce/apex/ExperianBusinessController.getExperianReports";

const COLUMNS = [
  {
    label: "FILE NAME",
    fieldName: "Title",
    type: "button",
    typeAttributes: {
      label: { fieldName: "Title" },
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
    fieldName: "CreatedBy",
    type: "text",
    sortable: true
  }
];

export default class ExperianReports extends NavigationMixin(LightningElement) {
  @api recordId;
  @track files = [];
  @track error;
  @track currentPage = 1;
  @track pageSize = 3;
  @track totalRecords = 0;
  @track sortBy;
  @track sortDirection;

  columns = COLUMNS;
  isLoading = true;

  wiredFilesResult;

  @wire(getExperianReports, {
    accountId: "$recordId",
    pageSize: "$pageSize",
    pageNumber: "$currentPage"
  })
  wiredFiles(result) {
    this.wiredFilesResult = result;
    this.isLoading = true;
    const { data, error } = result;
    if (data) {
      console.log("Received data:", data);
      this.files = this.transformData(data.records);
      this.totalRecords = data.totalRecords;
      this.error = undefined;
    } else if (error) {
      this.handleError(error);
    }
    this.isLoading = false;
  }

  transformData(data) {
    if (!Array.isArray(data)) {
      console.error("transformData received non-array data:", data);
      return [];
    }
    return data.map((file) => ({
      Id: file.ContentDocumentId,
      Title: file.ContentDocument.Title,
      CreatedDate: file.ContentDocument.CreatedDate,
      CreatedBy: file.ContentDocument.CreatedBy.Name,
      titleClass: "slds-text-link"
    }));
  }

  handleRowAction(event) {
    const actionName = event.detail.action.name;
    const row = event.detail.row;

    if (actionName === "view_file") {
      this.viewFile(row.Id);
    }
  }

  viewFile(contentDocumentId) {
    this[NavigationMixin.Navigate]({
      type: "standard__namedPage",
      attributes: {
        pageName: "filePreview"
      },
      state: {
        selectedRecordId: contentDocumentId
      }
    });
  }

  formatFileSize(bytes) {
    if (bytes === 0) return "0 Bytes";
    const k = 1024;
    const sizes = ["Bytes", "KB", "MB", "GB", "TB"];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + " " + sizes[i];
  }

  handleError(error) {
    console.error("Error:", error);
    this.error = error.body?.message || "Unknown error occurred";
    this.files = undefined;
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
