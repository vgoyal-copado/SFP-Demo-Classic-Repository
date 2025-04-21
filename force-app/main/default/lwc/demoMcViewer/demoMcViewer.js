import { LightningElement } from 'lwc';
import pubsub from 'vlocity_cmt/pubsub';

export default class DemoMcViewer extends LightningElement {
    channel;
    category;
    id;


    connectedCallback() {
        this.channel = 'CiConsoleMC';
        this.category = 'home';

        pubsub.register(this.channel, {
            setvalues: (e) => this.setVariables(e)
        });
    }

    setVariables(e) {
        if (e) {
            this.category = e.category;
            this.id = e.id;
        }
    }

    disconnectedCallback() {
        pubsub.unregisterAllListeners(this);
    }
}