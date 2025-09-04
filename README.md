![Salesforce Logo](/force-app/main/default/staticresources/logo.png)

## **Salesforce Omniscripts:** **Dynamically calling Apex from a custom Lightning Web Component** 


The process of embedding a Lightning Web Component (LWC) connected to Apex inside an OmniScript to populate Select components provides several key benefits including, but not limited to:

1. **Better User Experience** – Select lists can be updated dynamically based on prior user input (e.g., cascading picklists), creating a guided and responsive flow without forcing full OmniScript refreshes.  
2. **Reusability & Modularity** – The LWC encapsulates both UI logic and data access. It can be reused across different OmniScripts or FlexCards, providing consistency and reducing maintenance overhead.  
3. **Dynamic Data Retrieval** – The LWC can call Apex to query Salesforce or external systems in real time, ensuring Select options are always up to date (e.g., account types, product lists, regions).  
4. **Performance & Scalability** – Apex allows server-side filtering and business logic execution before data reaches the OmniScript, reducing payload size and improving performance for complex datasets.

This example will utilize the scenario of dynamically loading contacts from Apex into a Lightning Web Combobox component whenever an account is selected from a standard Omniscript select component. 

---

1. #### **Build custom Apex class**

   1. Create a new Apex class using VS Code or Salesforce Developer Console.  For this example, we have given the name of `GetPicklistValueByContact` to the class.

   2. Within the `GetPicklistValueByContact.cls` file, implement the ‘Callable’ interface to the `GetPicklistValueByContact` class.  Note that implementing this interface will require implementing the `call(String action, Map\<String, Object\> args)` method. The completed `omniListComponent.js` file should look like below:



**GetPicklistValueByContact class**

    global class GetPicklistValueByContact implements Callable {
        public Object call(String action, Map<String, Object> args) {
            Map<String, Object> input = (Map<String, Object>)args.get('input');
            Map<String, Object> output = (Map<String, Object>)args.get('output');
            Map<String, Object> options = (Map<String, Object>)args.get('options');
            return invokeMethod(action, input, output, options);
        }

        private Object invokeMethod(String methodName, Map<String,Object> input, Map<String,Object> output, Map<String,Object> option) {
            System.debug(LoggingLevel.DEBUG,'***input**** ' + input);
            // MethodName Will be same as the value that we have mentioned while calling
            if (methodName == 'AccountNames') {
                List< Map <String, String>> UIoptions = new List< Map <String, String>>();
                for (Account acc : [Select Id, Name FROM Account ORDER BY Name LIMIT 200]) {
                    Map<String,String> tempMap = new Map<String,String>();
                    tempMap.put('name', acc.Id);
                    tempMap.put('value', acc.Name);
                    UIoptions.add(tempMap);
                }
                output.put('options', UIoptions);
            }

            if (methodName == 'ContactNames') {
                String accountId = (String) input.get('accountId');
                List< Map <String, String>> UIoptions = new List< Map <String, String>>();
                for (Contact con : [Select Id, Name FROM Contact WHERE AccountId = :accountId ORDER BY Name LIMIT 200]) {
                    Map<String,String> tempMap = new Map<String,String>();
                    tempMap.put('value', con.Id);
                    tempMap.put('label', con.Name);
                    UIoptions.add(tempMap);
                }
                output.put('options', UIoptions);
            }
            return true;
        }
    }



#### 

   3. Deploy this source to org (if using VS Code).

2. #### **Build custom Lightning Web Component (LWC)**

   1. Create a new Lightning Web Component using VS Code or Salesforce Developer Console.  For this example, we have named the component `omniListComponent`.

   2. Within the `omniListComponent.html` file, define the UI with a simple `<lightning-combobox\>` component. The completed `omniListComponent.html` file should look like below.  Be sure to notice the binding declarations.

**omniListComponent.html**

    <template>
        <lightning-layout horizontal-align="spread" multiple-rows>
            <lightning-layout-item size="12">
                <lightning-combobox
                    name="progress"
                    label="Contacts"
                    value={contactId}
                    placeholder={placeholder}
                    options={options}
                    onchange={handleContactChange}
                >
                </lightning-combobox>
            </lightning-layout-item>
        </lightning-layout>
    </template>

   3. Within the `omniListComponent.js` file, `import OmniscriptBaseMixin` to interact with an Omniscript by extending the `OmniScriptBaseMixin` component. The `OmniScriptBaseMixin` includes methods to read/update an Omniscript's data JSON, pass parameters, and more.

    import { OmniscriptBaseMixin } from 'omnistudio/omniscriptBaseMixin';

   4. On the class definition file, extend the OmniScriptBaseMixin component to wrap a Salesforce Lightning component:

    export default class OmniListComponent extends OmniscriptBaseMixin(LightningElement) {


   5. Map all binding definitions within the omniListComponent.js file to the ones declared above in the omniListComponent.html page. Notice the @api directive attached to the accountId getter/setter.  This enables external access by the Omniscript when the user selects an account from the account Select component.

    @api
    get accountId() {
        return this._accountId;
    }
    set accountId(value) {
        this._accountId = value;
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

   6. Add a loadContacts() method enabling the Lightning Web Component to make a remote call to your custom Apex class.  Embedded Lightning Web Components must proxy through the Omniscript using the omniRemoteCall() method as they’re unable to directly connect to the Apex class.

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


   7. Update the accountId setter to call the loadContacts() method whenever the account Id value is updated:

    set accountId(value) {
        this._accountId = value;
        this.loadContacts(this._accountId);
    }


   8. Add an event handler to update the Omniscript’s data JSON when a user selects a contact.  Notice this implements the omniUpdateDataJson() method.

    handleContactChange(event) {
        this.contactId = event.detail.value;
        this.omniUpdateDataJson(this.contactId);
    }


   9. The completed omniListComponent.js file should look like below:

**omniListComponent.js**

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


   10. For reference, the omniListComponent.js-meta.xml should look like below:

**omniListComponent.js-meta.xml**

    <?xml version="1.0" encoding="UTF-8"?>
    <LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">
        <apiVersion>64.0</apiVersion>
        <isExposed>true</isExposed>
        <runtimeNamespace>omnistudio</runtimeNamespace>
    </LightningComponentBundle>

   11. Deploy this source to org (if using VS Code).

3. #### **Build Omniscript & embed custom LWC**

   1. Add a Select component to the desired step element. Bind this component to the Omniscript’s context variable which will with a list of accounts from the designated data mapper.  
    ![Add select component](/force-app/main/default/staticresources/ss1.png)

   2.  Add a Custom LWC component underneath the Account Select component.  Configure the component with the following properties:  
    - Name: 	`Contact`
    - Field Label: 	`Contacts`
    - \*Lightning Web Component Name: `omniListComponent`.  
    ![Add LWC component](/force-app/main/default/staticresources/ss2.png)

   3. Expand the Custom Lightning Web Component Properties section and add the following property:  
    - Property Name:	accountId
    - Property Source:	%Step1:Account%  
    ![COnfigure LWC component](/force-app/main/default/staticresources/ss3.png)

   4. Preview your component.  The list of contacts should dynamically change now with respect to the account selection.  Selecting a contact should also update the Omniscript’s data JSON.  
    ![Preview component](/force-app/main/default/staticresources/ss4.png)

4. #### **Resources**

   1. [Make Remote Calls Within Omniscripts from Lightning Web Components](https://help.salesforce.com/s/articleView?id=xcloud.os_make_remote_calls_from_lightning_web_components_using_the_omniscript_action_framework_18348.htm&type=5)  
   2. [Import Apex Methods](https://developer.salesforce.com/docs/platform/lwc/guide/apex-import-method.html)  
   3. [Extend the Component](https://help.salesforce.com/s/articleView?id=xcloud.os_extend_omniscriptbasemixin_component_vlocity.htm&type=5)  
   4. [Extend the OmniScriptBaseMixin Component](https://help.salesforce.com/s/articleView?id=xcloud.os_extend_the_omniscriptbasemixin_component.htm&type=5)  
   5. [Make Remote Calls from Lightning Web Components using the LWC Omniscript Action Framework](https://help.salesforce.com/s/articleView?id=xcloud.os_make_remote_calls_from_lightning_web_components_using_the_lwc_omniscript_action_framework.htm&type=5)  
   6. [Controlling OmniScript from Lightning Web Components (LWCs)](https://www.salesforceben.com/controlling-omniscript-from-lightning-web-components-lwcs/#:~:text=Step%202:%20Adding%20Custom%20LWC%20to%20the,list%20of%20available%20components:%20That%20is%20it.)  
   7. [Call Apex from Omniscript (Remote Action)](https://www.youtube.com/watch?v=OT8Xy94DpVY&t=1441s)  
   8. [How to Call Apex Method In Lightning Web Component | How to use Omniscript json data in lwc](https://www.youtube.com/watch?v=vbk6lM5TH-Q)  
   9. [Calling Apex from Omniscripts with the Remote Action](https://help.salesforce.com/s/articleView?id=xcloud.os_remote_action_13618.htm&type=5)
