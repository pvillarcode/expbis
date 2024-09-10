/*
// Schedule the Experian_ScheduleBISToken class to run immediately
 String jobId = System.schedule('Test Experian Schedule 11', System.now().addMinutes(1).format('s m H d M \'?\' yyyy'), new Experian_ScheduleBISToken());
 System.debug('Scheduled Job ID: ' + jobId);
*/

/* Schedule the job to run every 20 minutes 
System.schedule('Experian_ScheduleBISToken1', '0 0 * * * ?', new Experian_ScheduleBISToken());
System.schedule('Experian_ScheduleBISToken2', '0 20 * * * ?', new Experian_ScheduleBISToken());
System.schedule('Experian_ScheduleBISToken3', '0 40 * * * ?', new Experian_ScheduleBISToken());
*/

global without sharing class Experian_ScheduleBISToken implements Schedulable {
  global void execute(SchedulableContext sc) {
    getBISToken();
  }

  @future(callout=true)
  public static void getBISToken() {
    ExperianApiService.ExperianConfigWrapper wrapper = ExperianApiService.getBIQConfig();
    Experian_Configuration__c setting = wrapper.config;
    ExperianApiService.ExperianEndpoints endpoints = wrapper.endpoints;

    try {
      String body =
        '{"username": "' +
        setting.Experian_API_User_Name__c +
        '", "password": "' +
        setting.Experian_API_Password__c +
        '", "client_id": "' +
        setting.Experian_API_Client_id__c +
        '", "client_secret": "' +
        setting.Experian_Api_Client_Secret__c +
        '"}';

      Http http = new Http();

      HttpRequest request = new HttpRequest();
      request.setEndpoint(endpoints.tokenUrl); // Use the new endpoints object
      request.setMethod('POST');
      request.setHeader('Content-type', 'application/json');
      request.setHeader('Accept', 'application/json');
      request.setHeader('Grant_type', 'password');

      request.setBody(body);

      HttpResponse response = http.send(request);
      // Parse the JSON response
      if (response.getStatusCode() != 200) {
        ExperianLogger.log(
          'An error occurred in Experian_ScheduleBISToken getBISToken: ' +
            response.getStatusCode() +
            ' ' +
            response.getStatus(),
          ExperianLogger.LogLevel.ERROR
        );
      } else {
        Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(
          response.getBody()
        );
        String token = (String) results.get('access_token');
        setting.Experian_Access_Token__c = token;
        update setting;

        ExperianLogger.log(
          'Experian_ScheduleBISToken Token has been updated',
          ExperianLogger.LogLevel.INFO
        );
      }
    } catch (Exception e) {
      ExperianLogger.log(
        'ERROR Experian_ScheduleBISToken getBISToken ' +
          e.getMessage() +
          '\n' +
          e.getStackTraceString(),
        ExperianLogger.LogLevel.ERROR
      );
      System.debug('ERROR:' + e.getMessage() + '\n' + e.getStackTraceString());
    }
  }
}
