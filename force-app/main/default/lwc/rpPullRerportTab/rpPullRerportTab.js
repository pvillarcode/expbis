import { LightningElement, track } from 'lwc';

export default class RpPullReportTab extends LightningElement {
  @track currentPage = 'rp-business-search';
  @track businessId;
  @track reportType;
  @track scoringModel;

  get isBussinessSearch() {
    return this.currentPage === 'rp-business-search';
  }

  get isReportSelection() {
    return this.currentPage === 'rp-report-selection';
  }

  get isReportDisplay() {
    return this.currentPage === 'rp-report-display';
  }

  handleBusinessSelect(event) {
    this.businessId = event.detail;
    this.currentPage = 'rp-report-selection';
  }

  handleBusinessSearchedXXXX(event) {
    console.log('on handle business search');
    this.businessId = event.detail;
    this.currentPage = 'rp-report-selection';
  }

  handleReportSelected(event) {
    this.reportType = event.detail.reportType;
    this.scoringModel = event.detail.scoringModel;
    this.currentPage = 'rp-report-display';
  }

  handlePullReport() {
    this.currentPage = 'rp-report-display';
  }
}
