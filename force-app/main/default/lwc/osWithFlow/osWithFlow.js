import { LightningElement, api} from 'lwc';

export default class DeAutoWCAddDriverFlowWrapper extends LightningElement {

    @api layout;
    @api recordId;
    @api prefill;

    connectedCallback()
    {
        this.prefill = {"ContextId": this.recordId};
        console.log('Layout:'+this.layout);
        console.log('Record Id:'+this.recordId);
        console.log('Prefill:'+this.prefill);
    }

    
}