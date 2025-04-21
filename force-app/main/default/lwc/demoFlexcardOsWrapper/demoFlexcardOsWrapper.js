import { LightningElement } from 'lwc';
import pubsub from 'vlocity_cmt/pubsub';

export default class DemoFlexcardOsWrapper extends LightningElement {
    channel;
    statementId;

    connectedCallback() {
        this.channel = 'StatementMC';

        pubsub.register(this.channel, {
            setvalues: (e) => this.setVariables(e)
        });
    }

    setVariables(e) {
        if (e) {
            this.statementId = e.statementId;
        }
    }

    get isLoaded(){
        return !!this.statementId;
    }

    get prefill(){
        return {"recordId": this.statementId}
    }

    disconnectedCallback() {
        pubsub.unregisterAllListeners(this);
    }
}