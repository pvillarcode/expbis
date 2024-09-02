import { LightningElement, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getAccountLists from "@salesforce/apex/AlertRegistrationController.getAccountLists";
import getAccounts from "@salesforce/apex/AlertRegistrationController.getAccounts";
import getTotalAccountsInList from "@salesforce/apex/AlertRegistrationController.getTotalAccountsInList";
import registerAMS from "@salesforce/apex/AlertRegistrationController.registerAMS";
import unregisterAMS from "@salesforce/apex/AlertRegistrationController.unregisterAMS";

const ACCOUNTS_PER_LOAD = 50;

export default class AmsAlertRegistration extends LightningElement {
  @track accountLists = [];
  @track accounts = [];
  @track totalAccounts = 0;
  @track selectAllValue = [];
  @track selectedList;
  @track selectedAccounts = [];
  @track isLoading = false;
  @track isModalOpen = false;
  @track modalMessage = "";
  @track loadMoreStatus;

  columns = [
    { label: "Account Name", fieldName: "Name", type: "text" },
    { label: "Account Number", fieldName: "AccountNumber", type: "text" }
  ];

  selectAllOptions = [{ label: "Select All", value: "selectAll" }];

  pendingAction = null;
  offset = 0;
  enableInfiniteLoading = true;
  loadMoreOffset = 5;

  @wire(getAccountLists)
  wiredAccountLists({ error, data }) {
    if (data) {
      this.accountLists = data.map((list) => ({
        label: list.Name,
        value: list.Id
      }));
    } else if (error) {
      this.showToast(
        "Error",
        "Error fetching account lists: " + error.body.message,
        "error"
      );
    }
  }

  get isActionDisabled() {
    return (
      (this.selectedAccounts.length === 0 &&
        this.selectAllValue.length === 0) ||
      this.isLoading
    );
  }

  handleListChange(event) {
    this.selectedList = event.detail.value;
    this.resetList();
    this.fetchAccounts();
    this.fetchTotalAccounts();
  }

  resetList() {
    this.accounts = [];
    this.offset = 0;
    this.enableInfiniteLoading = true;
    this.loadMoreStatus = null;
    this.selectedAccounts = [];
    this.selectAllValue = [];
  }

  async fetchAccounts() {
    if (!this.selectedList || this.isLoading) return;

    this.isLoading = true;
    try {
      const newAccounts = await getAccounts({
        listViewId: this.selectedList,
        offset: this.offset,
        recordLimit: ACCOUNTS_PER_LOAD
      });
      this.accounts = [...this.accounts, ...newAccounts];
      this.offset += newAccounts.length;

      if (newAccounts.length < ACCOUNTS_PER_LOAD) {
        this.enableInfiniteLoading = false;
      }

      this.loadMoreStatus = null;
    } catch (error) {
      this.showToast(
        "Error",
        "Error fetching accounts: " + error.body.message,
        "error"
      );
      this.loadMoreStatus = "Error loading more accounts. Please try again.";
    } finally {
      this.isLoading = false;
    }
  }

  async fetchTotalAccounts() {
    if (!this.selectedList) return;

    try {
      this.totalAccounts = await getTotalAccountsInList({
        listViewId: this.selectedList
      });
    } catch (error) {
      this.showToast(
        "Error",
        "Error fetching total accounts: " + error.body.message,
        "error"
      );
    }
  }

  handleRowSelection(event) {
    this.selectedAccounts = event.detail.selectedRows.map((row) => row.Id);
    this.updateSelectAllCheckbox();
  }

  handleSelectAllChange(event) {
    this.selectAllValue = event.detail.value;
    const selectAll = this.selectAllValue.includes("selectAll");

    if (selectAll) {
      this.selectedAccounts = this.accounts.map((account) => account.Id);
    } else {
      this.selectedAccounts = [];
    }

    const datatable = this.template.querySelector("lightning-datatable");
    if (datatable) {
      datatable.selectedRows = this.selectedAccounts;
    }
  }

  updateSelectAllCheckbox() {
    this.selectAllValue =
      this.selectedAccounts.length === this.accounts.length
        ? ["selectAll"]
        : [];
  }

  handleRefresh() {
    this.resetList();
    this.fetchAccounts();
    this.fetchTotalAccounts();
  }

  handleLoadMore() {
    if (this.enableInfiniteLoading && !this.isLoading) {
      this.fetchAccounts();
    }
  }

  closeModal() {
    this.isModalOpen = false;
    this.pendingAction = null;
  }

  confirmModal() {
    if (this.pendingAction) {
      this.pendingAction();
    }
    this.closeModal();
  }

  handleRegisterAMS() {
    const accountCount = this.getAccountCountForAction();
    this.modalMessage = `Are you sure you want to REGISTER ${accountCount} account${accountCount !== 1 ? "s" : ""} for AMS?`;
    this.pendingAction = this.performRegisterAMS;
    this.isModalOpen = true;
  }

  handleUnregisterAMS() {
    const accountCount = this.getAccountCountForAction();
    this.modalMessage = `Are you sure you want to UNREGISTER ${accountCount} account${accountCount !== 1 ? "s" : ""} from AMS?`;
    this.pendingAction = this.performUnregisterAMS;
    this.isModalOpen = true;
  }

  async performRegisterAMS() {
    await this.performAction(registerAMS, "AMS registration successful");
  }

  async performUnregisterAMS() {
    await this.performAction(unregisterAMS, "AMS unregistration successful");
  }

  async performAction(action, successMessage) {
    if (
      this.selectedAccounts.length === 0 &&
      this.selectAllValue.length === 0
    ) {
      this.showToast("Error", "Please select at least one account", "error");
      return;
    }

    this.isLoading = true;
    try {
      await action({
        accountIds: this.selectAllValue.includes("selectAll")
          ? null
          : this.selectedAccounts,
        listViewId: this.selectAllValue.includes("selectAll")
          ? this.selectedList
          : null
      });
      this.showToast("Success", successMessage, "success");
      this.fetchAccounts();
      this.fetchTotalAccounts();
    } catch (error) {
      this.showToast(
        "Error",
        "Error performing action: " + error.body.message,
        "error"
      );
    } finally {
      this.isLoading = false;
    }
  }

  getAccountCountForAction() {
    return this.selectAllValue.includes("selectAll")
      ? this.totalAccounts
      : this.selectedAccounts.length;
  }

  showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }
}
