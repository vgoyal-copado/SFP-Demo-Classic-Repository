import { LightningElement, api } from 'lwc';
import pubsub from 'vlocity_cmt/pubsub';

export default class DemoConsoleLayoutFacade extends LightningElement {
    @api recordId;
    
    HOME_CATEGORY = 'home';
    STATEMENT_CATEGORY = 'statement';
    ASSETS_CATEGORY = 'asset';
    CASES_CATEGORY = 'case';
    ORDERS_CATEGORY = 'order';
    CHANNEL_NAME = 'CiConsoleMC';
    message = { category: this.HOME_CATEGORY, id: '' };

    connectedCallback() {
        pubsub.register(this.CHANNEL_NAME, {
            setvalues: (evt) => { this.message = this.setMessage(evt); }
        });
    }

    setMessage(evt) {

        //if (evt) console.log("Console Event Recieved-> " + JSON.stringify(evt));
        if (evt && evt.category) return { category: evt.category, id: evt.id };
        return this.message;
    }

    get isHomeActive() {
        return this.isActive(this.HOME_CATEGORY);
    }

    get isStatementsActive(){
        return this.isActive(this.STATEMENT_CATEGORY);
    }

    get isAssetsActive(){
        return this.isActive(this.ASSETS_CATEGORY);
    }

    get isCasesActive() {
        return this.isActive(this.CASES_CATEGORY);
    }

    get isOrdersActive() {
        return this.isActive(this.ORDERS_CATEGORY);
    }

    isActive(category) {
        return this.message && this.message.category === category;
    }
}