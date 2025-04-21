import { LightningElement } from "lwc";

export default class DemoAccountStatementBalanceBarChart extends LightningElement {
    get title() {
        return 'Balance over the last 12 months';
    }
    get yLabel(){
        return 'Balance Due';
    }
    get xLabel(){
        return 'Month';
    }
}