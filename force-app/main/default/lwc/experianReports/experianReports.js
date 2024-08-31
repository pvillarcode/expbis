import { LightningElement, wire, track } from "lwc";
import { CurrentPageReference } from "lightning/navigation";
import { NavigationMixin } from "lightning/navigation";
import getExperianReports from "@salesforce/apex/ExperianBusinessController.getExperianReports";

const columns = [
  { label: "Title", fieldName: "Title", type: "text" },
  { label: "Date", fieldName: "CreatedDate", type: "text" },
  { label: "Size", fieldName: "ContentSize", type: "text" },
  {
    label: "Action",
    type: "button",
    typeAttributes: {
      label: "View Report",
      name: "view_download",
      title: "Click to View/Download",
      disabled: false,
      value: "view_download"
    }
  }
];

export default class ExperianReports extends NavigationMixin(LightningElement) {
  @track accountId;
  @track files;
  @track error;
  @track currentPage = 1;
  @track pageSize = 5;
  columns = columns;

  @wire(CurrentPageReference)
  getStateParameters(currentPageReference) {
    console.log("Getting Reports");

    if (currentPageReference && currentPageReference.attributes.recordId) {
      this.accountId = currentPageReference.attributes.recordId;
      console.log("Getting Reports Account Id: ", this.accountId);
      this.wiredFiles();
    } else {
      console.error("No Account Id provided");
    }
  }

  wiredFiles() {
    if (!this.accountId) {
      console.error("No Account Id provided in WiredFiles");
      return;
    }
    getExperianReports({
      accountId: this.accountId,
      pageSize: this.pageSize,
      pageNumber: this.currentPage
    })
      .then((data) => {
        console.log("WiredFiles: ", this.accountId);
        if (data) {
          console.log("Data: ", data);
          this.files = data.map((file) => ({
            Id: file.ContentDocumentId,
            Title: file.ContentDocument.Title,
            CreatedDate: this.formatFriendlyDate(
              file.ContentDocument.CreatedDate
            ),
            ContentSize: this.formatFileSize(file.ContentDocument.ContentSize)
          }));
          console.log(this.files);
          this.error = undefined;
        }
      })
      .catch((error) => {
        console.error("Error getting files: ", error);
        this.error = error;
        this.files = undefined;
      });
  }

  formatFriendlyDate(dateString) {
    const options = {
      year: "numeric",
      month: "long",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit"
    };
    return new Intl.DateTimeFormat("en-US", options).format(
      new Date(dateString)
    );
  }

  handleRowAction(event) {
    const action = event.detail.action;
    const row = event.detail.row;
    switch (action.name) {
      case "view_download":
        this.viewFile(row.Id);
        break;
      default:
        break;
    }
  }

  get paginatedFiles() {
    return this.files;
  }

  get isFirstPage() {
    return this.currentPage === 1;
  }

  get isLastPage() {
    return this.files.length < this.pageSize;
  }

  handlePrevious() {
    if (this.currentPage > 1) {
      this.currentPage -= 1;
      this.wiredFiles();
    }
  }

  handleNext() {
    if (!this.isLastPage) {
      this.currentPage += 1;
      this.wiredFiles();
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
}
