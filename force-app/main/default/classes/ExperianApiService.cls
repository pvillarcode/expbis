public inherited sharing class ExperianApiService {
  public class ExperianEndpoints {
    public String tokenUrl;
    public String amsGetAlertDetailUrl;
    public String amsGetAlertListUrl;
    public String amsRegisterUrl;
    public String amsUnregisterUrl;
    public String decisionBasicUrl;
    public String premierProfileJsonUrl;
    public String premierProfilePdfUrl;
    public String searchUrl;
    public String bopPdfUrl;
  }

  public static ExperianConfigWrapper getBIQConfig() {
    Experian_Configuration__c config = [
      SELECT
        Id,
        Name,
        Experian_Environment__c,
        Default_Subcode__c,
        Experian_Access_Token__c,
        Experian_API_Client_id__c,
        Experian_Api_Client_Secret__c,
        Experian_API_Password__c,
        Experian_API_User_Name__c,
        Experian_Token_URL__c,
        Token_URL__c,
        AMS_Get_Alert_Detail_URL__c,
        AMS_Get_Alert_List_URL__c,
        AMS_Register_URL__c,
        AMS_Unregister_URL__c,
        AMS_Subcode__c,
        AMS_Subscriber_Code__c,
        Decision_Basic_URL__c,
        DecisionIQ_Default_Policy_ID__c,
        Decision_IQ_Subcode__c,
        DIQ_user_id__c,
        Premier_Profile_JSON_URL__c,
        Premier_Profile_PDF_URL__c,
        Search_URL__c,
        BOP_PDF_URL__c
      FROM Experian_Configuration__c
      LIMIT 1
    ];

    Experian_API_host__mdt hostUrl = [
      SELECT Id, DeveloperName, Endpoint_URL__c
      FROM Experian_API_host__mdt
      WHERE DeveloperName = :config.Experian_Environment__c
      LIMIT 1
    ];

    ExperianEndpoints endpoints = new ExperianEndpoints();

    // Populate endpoints object with concatenated URLs
    endpoints.tokenUrl = hostUrl.Endpoint_URL__c + config.Token_URL__c;
    endpoints.amsGetAlertDetailUrl =
      hostUrl.Endpoint_URL__c + config.AMS_Get_Alert_Detail_URL__c;
    endpoints.amsGetAlertListUrl =
      hostUrl.Endpoint_URL__c + config.AMS_Get_Alert_List_URL__c;
    endpoints.amsRegisterUrl =
      hostUrl.Endpoint_URL__c + config.AMS_Register_URL__c;
    endpoints.amsUnregisterUrl =
      hostUrl.Endpoint_URL__c + config.AMS_Unregister_URL__c;
    endpoints.decisionBasicUrl =
      hostUrl.Endpoint_URL__c + config.Decision_Basic_URL__c;
    endpoints.premierProfileJsonUrl =
      hostUrl.Endpoint_URL__c + config.Premier_Profile_JSON_URL__c;
    endpoints.premierProfilePdfUrl =
      hostUrl.Endpoint_URL__c + config.Premier_Profile_PDF_URL__c;
    endpoints.searchUrl = hostUrl.Endpoint_URL__c + config.Search_URL__c;
    endpoints.bopPdfUrl = hostUrl.Endpoint_URL__c + config.BOP_PDF_URL__c;

    System.debug('hostUrl: ' + hostUrl.Endpoint_URL__c);
    System.debug('token URL: ' + endpoints.tokenUrl);

    return new ExperianConfigWrapper(config, endpoints);
  }

  public class ExperianConfigWrapper {
    public Experian_Configuration__c config;
    public ExperianEndpoints endpoints;

    public ExperianConfigWrapper(
      Experian_Configuration__c config,
      ExperianEndpoints endpoints
    ) {
      this.config = config;
      this.endpoints = endpoints;
    }
  }
}
