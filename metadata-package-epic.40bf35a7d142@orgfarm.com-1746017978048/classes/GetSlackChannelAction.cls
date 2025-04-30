/**
* GetSlackChannelAction
* 
* This class provides a Flow-invocable action to search for a Slack channel by name within a specific workspace
* in a Slack Enterprise Grid environment. It handles the pagination of results and provides detailed channel information.
* 
* The process:
* 1. Takes a workspace name and channel name as input
* 2. Queries auth.teams.list to find the workspace ID from the name
* 3. Uses the workspace ID to search for the channel using conversations.list
* 4. Returns channel details if found
*/
public class GetSlackChannelAction {
               
    /**
    * Output class containing channel details or error information
    * Returns basic channel information including ID, name, member count, and topic
    */
    public class ChannelSearchOutput {
        @InvocableVariable(description='Channel ID')
        public String channel_id;
              
        @InvocableVariable(description='Channel Name')
        public String channel_name;
              
        @InvocableVariable(description='Number of members in the channel')
        public Integer num_members;
              
        @InvocableVariable(description='Channel topic')
        public String topic;
              
        @InvocableVariable(description='Error message if search failed')
        public String error_message;
    }
    
        
    /**
    * Invocable method input class
    */
    public class MessageInput {       
              
        @InvocableVariable(required=true description='Message text to send')
        public String text;
    }
          
    /**
    * Invokable method output class returned to Flow/Process Builder
    * Provides message send status, timestamp for reference, and any error details
    * Message timestamp (ts) can be used as a message identifier for later updates/deletion
    */
    public class MessageOutput {
        @InvocableVariable(description='True if message was sent successfully')
        public Boolean is_success;
              
        @InvocableVariable(description='Timestamp of sent message')
        public String message_ts;
              
        @InvocableVariable(description='Error message if send failed')
        public String error_message;
    }
          
    // ------------------------
    // API Response Structures
    // ------------------------
          
    /**
    * Response structure for auth.teams.list endpoint
    * Used to find workspace/team ID from workspace name
    */
    private class TeamsListResponse {
        public Boolean ok;
        public List<Team> teams;
        public ResponseMetadata response_metadata;
        public String error;
    }
          
    /**
    * Structure representing a Slack workspace/team
    */
    private class Team {
        public String id;
        public String name;
    }
          
    /**
    * Response structure for conversations.list endpoint
    * Contains list of channels and pagination metadata
    */
    private class SlackResponse {
        public Boolean ok;
        public List<Channel> channels;
        public ResponseMetadata response_metadata;
        public String error;
    }
          
    /**
    * Metadata structure containing pagination information
    */
    private class ResponseMetadata {
        public String next_cursor;
    }
          
    /**
    * Structure representing a Slack channel
    * Contains only the fields we need for our output
    */
    private class Channel {
        public String id;
        public String name;
        public Integer num_members;
        public Topic topic;
    }
          
    /**
    * Structure representing a channel's topic
    */
    private class Topic {
        public String value;
    }
          
    /**
    * Main invocable method for the Flow action
    * Processes a list of inputs (bulk processing support) and returns corresponding outputs
    */
    public static List<ChannelSearchOutput> searchChannel() {
        List<ChannelSearchOutput> outputs = new List<ChannelSearchOutput>();
              
        // Process each input in the list (supporting bulk operations)
            ChannelSearchOutput output = new ChannelSearchOutput();
                  
            try {
                // Step 1: Get the workspace ID from the workspace name
                String teamId = getWorkspaceId(System.label.Workspace_Name);
                      
                if (teamId == null) {
                    output.error_message = 'Workspace "' + System.label.Channel_Name + '" not found';
                    outputs.add(output);
                    return outputs;
                }
                      
                // Step 2: Search for the channel in the identified workspace
                Channel foundChannel = searchAllChannels(System.label.Channel_Name, teamId);
                      
                // Step 3: Process results
                if (foundChannel != null) {
                    // Channel found - populate output with channel details
                    output.channel_id = foundChannel.id;
                    output.channel_name = foundChannel.name;
                    output.num_members = foundChannel.num_members;
                          
                    if (foundChannel.topic != null) {
                        output.topic = foundChannel.topic.value;
                    }
                } else {
                    // Channel not found
                    output.error_message = 'Channel not found';
                }
                      
            } catch(Exception e) {
                // Handle any errors that occur during processing
                output.error_message = 'Error: ' + e.getMessage();
                System.debug('Error details: ' + e.getStackTraceString());
            }
                  
            outputs.add(output);

              
        return outputs;
    }
          
    /**
    * Gets the workspace ID for a given workspace name using auth.teams.list
    * This method handles the Enterprise Grid workspace lookup
    * 
    * @param workspaceName The name of the workspace to find
    * @return The workspace ID if found, null if not found
    */
    private static String getWorkspaceId(String workspaceName) {
        // Initialize HTTP request
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:Slack_API/auth.teams.list');
        request.setMethod('GET');
              
        // Make the API call
        HttpResponse response = http.send(request);
              
        // Check for successful response
        if (response.getStatusCode() != 200) {
            throw new CalloutException('Teams list failed with status code: ' + response.getStatusCode());
        }
              
        // Parse the response
        TeamsListResponse teamsResponse = (TeamsListResponse)JSON.deserialize(
            response.getBody(), 
            TeamsListResponse.class
        );
              
        if (!teamsResponse.ok) {
            throw new CalloutException('Teams list not OK: ' + teamsResponse.error);
        }
              
        // Search for matching workspace name
        for (Team team : teamsResponse.teams) {
            if (team.name.equalsIgnoreCase(workspaceName)) {
                return team.id;
            }
        }
              
        // No matching workspace found
        return null;
    }
          
    /**
    * Searches for a channel by name within a specific workspace
    * Handles pagination to search through all available channels
    * 
    * @param channelName The name of the channel to find
    * @param teamId The ID of the workspace to search in
    * @return Channel object if found, null if not found
    */
    private static Channel searchAllChannels(String channelName, String teamId) {
        String cursor = null;
              
        do {
            // Construct endpoint URL with team_id and pagination cursor
            String endpoint = 'callout:Slack_API/conversations.list?team_id=' + teamId;
            if (String.isNotBlank(cursor)) {
                endpoint += '&cursor=' + EncodingUtil.urlEncode(cursor, 'UTF-8');
            }
                  
            // Initialize HTTP request
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setMethod('GET');
                  
            // Make the API call
            HttpResponse response = http.send(request);
                  
            // Check for successful response
            if (response.getStatusCode() != 200) {
                throw new CalloutException('Failed with status code: ' + response.getStatusCode());
            }
                  
            // Parse the response
            SlackResponse slackResponse = (SlackResponse)JSON.deserialize(
                response.getBody(), 
                SlackResponse.class
            );
                  
            if (!slackResponse.ok) {
                throw new CalloutException('Slack API response not OK: ' + slackResponse.error);
            }
                  
            // Search through current page of channels
            for (Channel channel : slackResponse.channels) {
                if (channel.name.equalsIgnoreCase(channelName)) {
                    return channel;
                }
            }
                  
            // Get cursor for next page of results
            cursor = (slackResponse.response_metadata != null) ? 
                    slackResponse.response_metadata.next_cursor : null;
                          
        } while (String.isNotBlank(cursor)); // Continue while there are more pages
              
        // Channel not found after searching all pages
        return null;
    }
          
    /**
    * Main invocable method to send a message to Slack
    * Handles a list of inputs for bulk processing but typically receives one input
    * Returns a corresponding list of outputs with success/failure details
    * 
    * @param inputs List of MessageInput objects containing message details
    * @return List<MessageOutput> Results of the message send operation(s)
    */
    @InvocableMethod(label='Send Slack Message To Channel')
    public static List<MessageOutput> sendMessage(List<MessageInput> inputs) {
        List<MessageOutput> outputs = new List<MessageOutput>();
        String channelId = '';
		//Get Channel ID first
		 List<GetSlackChannelAction.ChannelSearchOutput> results = GetSlackChannelAction.searchChannel();

        // Print results
        GetSlackChannelAction.ChannelSearchOutput result = results[0];
        if(String.isNotBlank(result.error_message)) {
            MessageOutput output = new MessageOutput();
            output.error_message = 'API Error: ' + result.error_message;
            outputs.add(output);
            return outputs;
        } else {
            channelId = result.channel_id;
        }              
        // Process each input (usually just one)
        for(MessageInput input : inputs) {
            MessageOutput output = new MessageOutput();
            output.is_success = false; // Default to false until success confirmed
                  
            try {
                // Setup HTTP request to Slack API
                Http http = new Http();
                HttpRequest request = new HttpRequest();
                request.setEndpoint('callout:Slack_API/chat.postMessage');
                request.setMethod('POST');
                request.setHeader('Content-Type', 'application/json');
                      
                // Construct message payload
                Map<String, String> body = new Map<String, String>{
                    'channel' => channelId,
                    'text' => input.text,
                    'team_id' => getWorkspaceId(system.Label.Workspace_Name)
                };
                      
                request.setBody(JSON.serialize(body));
                      
                // Send message to Slack
                HttpResponse response = http.send(request);
                      
                // Parse the JSON response
                Map<String, Object> responseBody = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                      
                // Check for success and process results
                if(response.getStatusCode() == 200 && responseBody.get('ok') == true) {
                    output.is_success = true;
                    output.message_ts = (String)responseBody.get('ts');
                } else {
                    // Capture API error message if present
                    output.error_message = 'API Error: ' + responseBody.get('error');
                }
                      
            } catch(Exception e) {
                // Handle any exceptions (callout errors, parsing errors, etc)
                output.error_message = 'Error: ' + e.getMessage();
                System.debug('Error details: ' + e.getStackTraceString());
            }
                  
            outputs.add(output);
        }
              
        return outputs;
    }
    
}