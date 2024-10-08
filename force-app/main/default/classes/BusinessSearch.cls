public with sharing class BusinessSearch {
  private static final String DEFAULT_SUBCODE = '0517614';
  private static final String ENDPOINT_URL = 'https://sandbox-us-api.experian.com/businessinformation/businesses/v1/search';
  private static final Integer TIMEOUT = 120000;

  private static final String KEY_BUSINESS_NAME = 'businessName';
  private static final String KEY_ADDRESS = 'address';
  private static final String KEY_CITY = 'city';
  private static final String KEY_STATE = 'state';
  private static final String KEY_ZIPCODE = 'zipcode';
  private static final String KEY_SUBCODE = 'subcode';
  private static final String KEY_GEO = 'geo';

  @AuraEnabled(cacheable=true)
  public static List<BusinessResult> getLOS(
    Map<String, String> searchCriteria
  ) {
    List<BusinessResult> results = new List<BusinessResult>();
    ExperianApiService.ExperianConfigWrapper wrapper = ExperianApiService.getBIQConfig();
    Experian_Configuration__c setting = wrapper.config;
    ExperianApiService.ExperianEndpoints endpoints = wrapper.endpoints;
    SearchBusinessReqWrapper reqWrapper = new SearchBusinessReqWrapper();

    try {
      // Set values from searchCriteria
      reqWrapper.name = searchCriteria.get(KEY_BUSINESS_NAME);
      reqWrapper.street = searchCriteria.get(KEY_ADDRESS);
      reqWrapper.city = searchCriteria.get(KEY_CITY);
      reqWrapper.state = searchCriteria.get(KEY_STATE);
      reqWrapper.zip = searchCriteria.get(KEY_ZIPCODE);

      // Set default values for subcode and geo if they're not in searchCriteria
      reqWrapper.subcode = searchCriteria.containsKey(KEY_SUBCODE)
        ? searchCriteria.get(KEY_SUBCODE)
        : setting.Default_Subcode__c;
      reqWrapper.geo = searchCriteria.containsKey(KEY_GEO)
        ? Boolean.valueOf(searchCriteria.get(KEY_GEO))
        : false;

      HttpRequest req = new HttpRequest();
      req.setMethod('POST');
      req.setTimeout(TIMEOUT);
      req.setEndpoint(endpoints.searchUrl);
      req.setHeader('Accept', 'application/json');
      req.setHeader('Content-type', 'application/json');
      req.setHeader(
        'Authorization',
        'Bearer ' + setting.Experian_Access_Token__c
      );
      String reqBody = JSON.serialize(reqWrapper, true);
      req.setBody(reqBody);

      Http http = new Http();
      HttpResponse res = http.send(req);

      if (res.getStatusCode() == 200) {
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(
          res.getBody()
        );
        if (
          responseMap.containsKey('results') &&
          responseMap.get('results') instanceof List<Object>
        ) {
          List<Object> businesses = (List<Object>) responseMap.get('results');
          for (Object business : businesses) {
            Map<String, Object> businessMap = (Map<String, Object>) business;
            BusinessResult businessResult = new BusinessResult();
            businessResult.bin = (String) businessMap.get('bin');
            businessResult.name = (String) businessMap.get('businessName');
            businessResult.phone = (String) businessMap.get('phone');
            businessResult.reliabilityCode = (Decimal) businessMap.get(
              'reliabilityCode'
            );

            Map<String, Object> addressMap = (Map<String, Object>) businessMap.get(
              'address'
            );
            if (addressMap != null) {
              businessResult.street = (String) addressMap.get('street');
              businessResult.city = (String) addressMap.get('city');
              businessResult.state = (String) addressMap.get('state');
              businessResult.zip = (String) addressMap.get('zip');
              businessResult.address =
                businessResult.street +
                ', ' +
                businessResult.city +
                ', ' +
                businessResult.state +
                ' ' +
                businessResult.zip;
            }

            businessResult.numberOfTradelines = (Integer) businessMap.get(
              'numberOfTradelines'
            );
            businessResult.financialStatementIndicator = (Boolean) businessMap.get(
              'financialStatementIndicator'
            );
            businessResult.keyFactsIndicator = (Boolean) businessMap.get(
              'keyFactsIndicator'
            );
            businessResult.inquiryIndicator = (Boolean) businessMap.get(
              'inquiryIndicator'
            );
            businessResult.bankDataIndicator = (Boolean) businessMap.get(
              'bankDataIndicator'
            );
            businessResult.governmentDataIndicator = (Boolean) businessMap.get(
              'governmentDataIndicator'
            );
            businessResult.executiveSummaryIndicator = (Boolean) businessMap.get(
              'executiveSummaryIndicator'
            );
            businessResult.uccIndicator = (Boolean) businessMap.get(
              'uccIndicator'
            );

            Map<String, Object> geocodeMap = (Map<String, Object>) businessMap.get(
              'businessGeocode'
            );
            if (geocodeMap != null) {
              businessResult.latitude = (Decimal) geocodeMap.get('latitude');
              businessResult.longitude = (Decimal) geocodeMap.get('longitude');
            }

            results.add(businessResult);
          }
          System.debug('Results: ' + results);
        }
      } else {
        System.debug(
          'Error response: ' +
            res.getStatus() +
            ' ' +
            res.getStatusCode() +
            ' ' +
            res.getBody()
        );
        throw new CalloutException(
          'Error response: ' +
            res.getStatus() +
            ' ' +
            res.getStatusCode() +
            ' ' +
            res.getBody()
        );
      }
    } catch (Exception e) {
      System.debug('Exception: ' + e.getMessage());
      throw new CalloutException('Exception: ' + e.getMessage());
    }
    return results;
  }

  @AuraEnabled
  public static Experian_Business__c createExperianBusinessFromAccount(
    Id accountId
  ) {
    try {
      // Get account details
      Account acc = getAccountDetails(accountId);

      // Create a placeholder Experian_Business__c record
      Experian_Business__c experianBusiness = new Experian_Business__c(
        Name = acc.Name,
        Account__c = accountId,
        Street_Address__c = acc.BillingStreet,
        City__c = acc.BillingCity,
        State__c = acc.BillingState,
        Zip__c = acc.BillingPostalCode
      );

      insert experianBusiness;

      // Call the future method to update the record with Experian data
      updateExperianBusinessAsync(
        experianBusiness.Id,
        acc.Name,
        acc.BillingStreet,
        acc.BillingCity,
        acc.BillingState,
        acc.BillingPostalCode
      );

      return experianBusiness;
    } catch (Exception e) {
      System.debug(
        'Error in createExperianBusinessFromAccount: ' + e.getMessage()
      );
      return null;
    }
  }

  @future(callout=true)
  public static void updateExperianBusinessAsync(
    Id experianBusinessId,
    String name,
    String street,
    String city,
    String state,
    String zipCode
  ) {
    System.debug('updateExperianBusinessAsync called with parameters:');
    System.debug('experianBusinessId: ' + experianBusinessId);
    System.debug('name: ' + name);
    System.debug('street: ' + street);
    System.debug('city: ' + city);
    System.debug('state: ' + state);
    System.debug('zipCode: ' + zipCode);

    try {
      // Prepare search criteria
      Map<String, String> searchCriteria = new Map<String, String>{
        KEY_BUSINESS_NAME => name,
        KEY_ADDRESS => street,
        KEY_CITY => city,
        KEY_STATE => state,
        KEY_ZIPCODE => zipCode
      };
      System.debug('Search criteria: ' + searchCriteria);

      // Perform the search
      List<BusinessResult> results = getLOS(searchCriteria);
      System.debug('Search results: ' + results);

      if (!results.isEmpty()) {
        // Take the first result
        BusinessResult firstResult = results[0];
        System.debug('First search result: ' + firstResult);

        // Update the Experian_Business__c record
        Experian_Business__c experianBusiness = [
          SELECT Id
          FROM Experian_Business__c
          WHERE Id = :experianBusinessId
        ];
        System.debug(
          'Queried Experian_Business__c record: ' + experianBusiness
        );

        experianBusiness.BIN__c = firstResult.bin;
        System.debug('Updated BIN__c: ' + experianBusiness.BIN__c);
        // Update other fields as necessary

        update experianBusiness;
        System.debug('Experian_Business__c record updated successfully.');
      } else {
        System.debug('No search results found.');
      }
    } catch (Exception e) {
      System.debug('Error in updateExperianBusinessAsync: ' + e.getMessage());
    }
  }

  @AuraEnabled(cacheable=true)
  public static Account getAccountDetails(Id accountId) {
    return [
      SELECT
        Id,
        Name,
        BillingStreet,
        BillingCity,
        BillingState,
        BillingPostalCode,
        BillingCountry,
        Phone
      FROM Account
      WHERE Id = :accountId
    ];
  }
  public class BusinessResult {
    @AuraEnabled
    public String bin;
    @AuraEnabled
    public String name;
    @AuraEnabled
    public String phone;
    @AuraEnabled
    public String address;
    @AuraEnabled
    public String street;
    @AuraEnabled
    public String city;
    @AuraEnabled
    public String state;
    @AuraEnabled
    public String zip;
    @AuraEnabled
    public Decimal reliabilityCode;
    @AuraEnabled
    public Integer numberOfTradelines;
    @AuraEnabled
    public Boolean financialStatementIndicator;
    @AuraEnabled
    public Boolean keyFactsIndicator;
    @AuraEnabled
    public Boolean inquiryIndicator;
    @AuraEnabled
    public Boolean bankDataIndicator;
    @AuraEnabled
    public Boolean governmentDataIndicator;
    @AuraEnabled
    public Boolean executiveSummaryIndicator;
    @AuraEnabled
    public Boolean uccIndicator;
    @AuraEnabled
    public Decimal latitude;
    @AuraEnabled
    public Decimal longitude;
  }

  public class CalloutException extends Exception {
  }
}
