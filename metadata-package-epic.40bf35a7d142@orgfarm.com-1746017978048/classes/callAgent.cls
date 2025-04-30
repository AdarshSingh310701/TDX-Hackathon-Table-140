public class callAgent {
    
    @AuraEnabled
    public static outputResponseWrapper invokeServiceAgent (String usermessage, String sessionId, String prefLang) {
        
        outputResponseWrapper outputResponse = new outputResponseWrapper();
        String translatedText = '';
        
        String response = '';
        try {
            
            // Create an instance of the invocable action with type ‘generateAiAgentResponse’ and name ‘Agentforce_Service_Agent_new’
            Invocable.Action action = Invocable.Action.createCustomAction('generateAiAgentResponse', 'Agentforce_Service_Agent');
            
            translatedText = (prefLang != NULL && prefLang != 'en') ? translateText(prefLang,'en',usermessage) : usermessage;
            
            action.setInvocationParameter('userMessage', translatedText);
            
            if(sessionId != NULL && sessionId != ''){
                action.setInvocationParameter('sessionId', sessionId);
            }
            
            // Execute the action
            List<Invocable.Action.Result> results = action.invoke();
            Invocable.Action.Result result = results[0];
            
            // Handle the response
            if (result.isSuccess()) {
                // Retrieve the Session id and Agent Response
                System.debug('Output Session Id: ' + result.getOutputParameters().get('sessionId'));
                System.debug('Output Agent Response: ' + result.getOutputParameters().get('agentResponse'));
                
                String jsonresult = (String)result.getOutputParameters().get('agentResponse');
                Object jsonresult2 = JSON.deserializeUntyped(jsonresult);
                Map<String, Object> resultMap = (Map<String, Object>) jsonresult2;
                String tempResponse = (String) resultMap.get('value');
                
                tempResponse = tempResponse.replaceAll('[^a-zA-Z0-9\\s+]', '');
                outputResponse.agentResponse = (prefLang != NULL && prefLang != 'en') ? translateText('en', prefLang, tempResponse) : tempResponse;
                outputResponse.currentSessionId = (String) result.getOutputParameters().get('sessionId');
                
                System.debug('@@outputResponse: '+outputResponse);
                
            } else {
                System.debug('Java action execution failed: ' + result.getErrors());
                //response = 'ERROR';
            }
        } catch (Exception e) {
            System.debug('Error invoking Java action: ' + e.getMessage());
        }
        
        return outputResponse;
    }
    
    public class outputResponseWrapper {
        
        @AuraEnabled public String agentResponse;
        @AuraEnabled public String currentSessionId;
    }
    
    @AuraEnabled
    public static string translateText (String sourceLang, String targetLang, String sourceText) {
        
        String translatedText = '';
        
        try{
            //String sourceText = 'Hi How are you ?';
            //String sourceValue = 'en';
            //String targetValue = 'hi';
            
            HttpRequest req = new HttpRequest();
            HttpResponse res = new HttpResponse();
            Http http = new Http();
            req.setEndpoint('https://google-translate113.p.rapidapi.com/api/v1/translator/text');
            req.setMethod('POST');
            // Your API key
            req.setHeader('X-RapidAPI-Key', 'e3936228c5msh4601ffa9d78f77bp1adb21jsn6f016767d2bc');
            req.setHeader('X-RapidAPI-Host', 'google-translate113.p.rapidapi.com');
            req.setHeader('content-type', 'application/json');
            String body = '{"from": "'+ sourceLang +'","to":"'+ targetLang + '","text":"'+sourceText+'"}';
            req.setBody(body);
            res = http.send(req);
            
            Map<string, object> responseMap = (Map<string, object>) JSON.deserializeUntyped(res.getbody());
            System.debug('@res.getbody(): '+res.getbody());
            System.debug('@responseMap: '+responseMap);
            
            translatedText = (String) responseMap.get('trans');
            System.debug('@translatedText: '+translatedText);
            
        } catch (Exception ex) {
            System.debug('Error invoking Java action: ' + ex.getMessage());
        }
        
        return translatedText;
    }
    
}