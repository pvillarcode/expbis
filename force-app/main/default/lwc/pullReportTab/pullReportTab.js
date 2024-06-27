import { LightningElement } from 'lwc';

export default class PullReportTab extends LightningElement {
    loading = false; 
    error = false;

    steps = [
        {label:"Search Business", value: "1"},
        {label:"Business Results", value: "2"},
        {label:"Select Report Type", value: "3"},
        {label:"View Report", value: "4"}
    ];

    current = "1";
    currentIndex = 0;

    get businessFormStep() {
        return this.current === this.steps[0].value;
    }

    get searchResultsStep() {
        return this.current === this.steps[1].value;
    }

    get selectReportStep() {
        return this.current === this.steps[2].value;
    }

    get viewReportStep() {
        return this.current === this.steps[3].value;
    }
}