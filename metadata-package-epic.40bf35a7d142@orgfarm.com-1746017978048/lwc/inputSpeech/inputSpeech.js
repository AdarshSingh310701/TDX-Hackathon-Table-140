import { LightningElement, wire,api,track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import usermessage from '@salesforce/apex/callAgent.invokeServiceAgent';

export default class InputSpeech extends LightningElement {

   testvalue = "Press Enter hear it.";
   @track searchKey = "Speak Something";
   @track voiceInputs = [];
   @track agentResponses = [];
   @track chatHistory=[];
   /*preferredLanguage = '';
   @track languagelist = ["english","hindi","bangali","russian","japanese"];
   @track languageBCL = {"english":"en-US",
                        "hindi":"hi-IN",
                        "bangali":"bn-IN",
                        "russian":"ru-RU",
                        "japanese":"ja-JP"};
   onceDone = false;*/
   
    _speechDBResults = [];
    _speechDBAcc = [];
    _speechDBCon = [];
    _speechDBOpp = [];
    _speechDBLead = [];
    _showSpinner = false;
    _recognition;
 
   handleInputChange(event){
      this.userInput=event.detail.value;
   }
 
 
   connectedCallback() {
 
       //https://developer.mozilla.org/en-US/docs/Web/API/SpeechRecognition
       //https://developer.mozilla.org/en-US/docs/Web/API/Web_Speech_API/Using_the_Web_Speech_API
       //Browsers currently support speech recognition with prefixed properties. Therefore at the start of our code we include these lines to allow for both prefixed properties and unprefixed versions that may be supported in future:
       window.SpeechRecognition = window.webkitSpeechRecognition || window.SpeechRecognition;
       if ("SpeechRecognition" in window) {
          this._recognition = new webkitSpeechRecognition() || new SpeechRecognition();
          this._recognition.lang = 'en-US';
          //  this._recognition.continuous = true;
      }

      //this.handleClick('');
   }

   /*renderedCallback(){
      var utterance = new SpeechSynthesisUtterance("Hello, Please choose your preferred language, the options are english,hindi,bangali,russian,japanese.");
         window.speechSynthesis.cancel();
         window.speechSynthesis.speak(utterance);
         utterance.onstart = function (event) {
            console.log('The utterance started to be spoken.')
      };
   }*/


 
    get speechToTextDataFound() {
       return this._speechDBResults.length > 0 ? true : false;
    }
 
 
 
    handleClick(event) {

      /*if(this.onceDone == false) {
            var utterance = new SpeechSynthesisUtterance("Hello, Please choose your preferred language, the options are english,hindi,bangali,russian,japanese.");
            window.speechSynthesis.cancel();
            window.speechSynthesis.speak(utterance);
            utterance.onstart = function (event) {
               console.log('The utterance started to be spoken.')
         }; 
         this.onceDone = true;
      }*/

      

      
       this._recognition.start();
       //When a result has been successfully recognized, the result event fires
       this._recognition.onresult = (event) => {
          const msg = event.results[0][0].transcript;
          this.handleSpeechRecognized(msg);
       }
    }
 
    //Extract the text results and add it to the Chatter.
    handleSpeechRecognized(msg) {
 
       let createAccount = 'Create Account';
       let createContact = 'Create Contact';
       this.searchKey = msg;
       this.voiceInputs=[...this.voiceInputs, {id:Date.now()+Math.random(), text:msg}];
       this.chatHistory=[...this.chatHistory, {id:Date.now()+Math.random(), sender:'User', message: msg, isUser:true}];
       console.log('@@msg BEFORE:'+this.searchKey);
       this.handleKeyChange(msg);

    }
 
    handleKeyChange(msg) {
      console.log('@@msg:'+msg);

      /*if(msg.length() == 1 && ( msg.toLowerCase() == "english" || msg.toLowerCase() == "hindi" || msg.toLowerCase() == "bangali" || msg.toLowerCase() == "russian" || msg.toLowerCase() == "japanese")) {
         preferredLanguage = languageBCL[msg.toLowerCase()].substring(0,2);
         this._recognition.lang = languageBCL[msg.toLowerCase()];
      } 
      else */
      if(msg.toLowerCase().includes('end session') || msg.toLowerCase().includes('terminate session') || msg.toLowerCase().includes('close session')){

         console.log('@@ SESSION ENDED');
         console.log('@@ localStorage: '+JSON.stringify(localStorage));
         localStorage.clear();

         usermessage({ usermessage: msg,sessionId: '', prefLang : 'en'})
            .then(result => {
               console.log('@@Session Ending:'+result.agentResponse);
               this.testvalue = result.agentResponse;
               this.agentResponses=[...this.agentResponses, {id:Date.now()+Math.random(), text:result.agentResponse}];
               this.chatHistory=[...this.chatHistory, {id:Date.now()+Math.random(), sender:'Agent', message: result.agentResponse, isUser:false}];
               this.handleEnter()
               //localStorage.setItem('sessionId',result.currentSessionId);
            })
            .catch(error => {
               this.error = error;
               console.log('@@error:'+error);
            })

         this.searchKey = '';
         this.testvalue = '';

      } else {

         if(localStorage.getItem('sessionId') == undefined || localStorage.getItem('sessionId') == ''){

            console.log('@@ MY FRIST TIME');
            console.log('@@ localStorage: '+JSON.stringify(localStorage));

            usermessage({ usermessage: msg,sessionId: '',prefLang : 'en' })
            .then(result => {
               console.log('@@Response:'+result.agentResponse);
               this.testvalue = result.agentResponse;
               this.agentResponses=[...this.agentResponses, {id:Date.now()+Math.random(), text:result.agentResponse}];
               this.chatHistory=[...this.chatHistory, {id:Date.now()+Math.random(), sender:'Agent', message: result.agentResponse, isUser:false}];
               this.handleEnter()
               localStorage.setItem('sessionId',result.currentSessionId);
            })
            .catch(error => {
               this.error = error;
               console.log('@@error:'+error);
            })
         } else {

            console.log('@@ CONTINUE SESSION');
            console.log('@@ localStorage: '+JSON.stringify(localStorage));

            usermessage({ usermessage: msg,sessionId: localStorage.getItem('sessionId'),prefLang : 'en' })
            .then(result => {
               console.log('@@Response:'+result.agentResponse);
               this.testvalue = result.agentResponse;
               this.agentResponses=[...this.agentResponses, {id:Date.now()+Math.random(), text:result.agentResponse}];
               this.chatHistory=[...this.chatHistory, {id:Date.now()+Math.random(), sender:'Agent', message: result.agentResponse, isUser:false}];
               this.handleEnter()
               localStorage.setItem('sessionId',result.currentSessionId);
            })
            .catch(error => {
               this.error = error;
               console.log('@@error:'+error);
            })
         }
      }
    }

    handleEnter() {
      // on press of enter synthesis should start
      //if (event.keyCode === 13) {
      console.log('INSIDE HANDLE ENTER');
         var utterance = new SpeechSynthesisUtterance(this.testvalue);
         window.speechSynthesis.cancel();
         window.speechSynthesis.speak(utterance);
         utterance.onstart = function (event) {
            console.log('The utterance started to be spoken.')
         };
      //}

   }
 
    handleClickToStop(event) {
 
       this._recognition.abort();
       console.log("Speech recognition has stopped.");
    }
 
 
    get showAccounts() {
       return this._speechDBAcc.length > 0 ? true : false;
    }
 
    handleAccClick(event) {
       console.log(event.currentTarget.dataset.accid);
       this.handleNavigation('Account', event.currentTarget.dataset.accid);
    }
 
    get showContacts() {
       return this._speechDBCon.length > 0 ? true : false;
    }
 
    handleContactClick(event) {
       console.log(event.currentTarget.dataset.conid);
       this.handleNavigation('Contact', event.currentTarget.dataset.conid);
 
    }
 
    get showOpportunities() {
       return this._speechDBOpp.length > 0 ? true : false;
    }
    handleOpportunityClick(event) {
       console.log(event.currentTarget.dataset.oppid);
       this.handleNavigation('Opportunity', event.currentTarget.dataset.oppid);
    }
 
    get showLeads() {
       return this._speechDBLead.length > 0 ? true : false;
    }
 
    handleLeadClick(event) {
       console.log(event.currentTarget.dataset.leadid);
       this.handleNavigation('Lead', event.currentTarget.dataset.leadid);
    }
 
    handleNavigation(soBjectName, recId) {
       this[NavigationMixin.Navigate]({
          type: 'standard__recordPage',
          attributes: {
             recordId: recId,
             objectApiName: soBjectName,
             actionName: 'view'
          }
       });
    }
    handleCardAction(event) {
       console.log(event.currentTarget.dataset.buttonname);
       switch (event.currentTarget.dataset.buttonname) {
          case 'Account':
             this.navigateToCreatePage('Account');
             break;
          case 'Contact':
             this.navigateToCreatePage('Contact');
             break;
          case 'Opportunity':
             this.navigateToCreatePage('Opportunity');
             break;
          case 'Lead':
             this.navigateToCreatePage('Lead');
             break;
          default:
          // code block
       }
    }
 
    
 
    // Navigate to New Account Page
    navigateToCreatePage(sObjectName) {
       this[NavigationMixin.Navigate]({
          type: 'standard__objectPage',
          attributes: {
             objectApiName: sObjectName,
             actionName: 'new'
          },
       });
    }


}