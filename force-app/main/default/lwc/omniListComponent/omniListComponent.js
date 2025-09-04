import { LightningElement, api } from 'lwc';
import { OmniscriptBaseMixin } from 'omnistudio/omniscriptBaseMixin';

export default class OmniListComponent extends OmniscriptBaseMixin(LightningElement) {
    _accountId;
    _contactId;
    _options = [];

    @api
    get accountId() {
        return this._accountId;
    }
    set accountId(value) {
        this._accountId = value;
        this.loadContacts(this._accountId);
    }

    get contactId() {
        return this._contactId;
    }
    set contactId(value) {
        this._contactId = value;
    }

    get options() {
        return this._options;
    }
    set options(value) {
        this._options = value;
    }

    get placeholder() {
        return this.accountId ? "Select a contact" : "An account must be selected first";
    }

    async loadContacts(accountId) {
        if (accountId) {
            const params = {
                input: {'accountId': accountId},
                sClassName: 'GetPicklistValueByContact',
                sMethodName: 'ContactNames',
                options: {}
            }
            this.omniRemoteCall(params, true).then(response => {
                this.options = response.result.options;
                console.log(response);
            }).catch(error => {
                console.log(error);
            });
        }
    }

    handleContactChange(event) {
        this.contactId = event.detail.value;
        this.omniUpdateDataJson(this.contactId);
    }

}