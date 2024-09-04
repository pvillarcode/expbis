public class Experian_QueueAMSRegistration implements Queueable {
  private List<Id> accountIds;

  public Experian_QueueAMSRegistration(List<Id> accountIds) {
    this.accountIds = accountIds;
    ExperianLogger.log(
      'Experian_QueueAMSRegistration initialized with accountIds: ' +
      accountIds,
      ExperianLogger.LogLevel.INFO
    );
  }

  public void execute(QueueableContext context) {
    ExperianLogger.log(
      'Executing Experian_QueueAMSRegistration with accountIds: ' + accountIds,
      ExperianLogger.LogLevel.INFO
    );

    List<Account> accountsToProcess = [
      SELECT
        Id,
        Name,
        BillingStreet,
        BillingCity,
        BillingState,
        BillingPostalCode
      FROM Account
      WHERE Id IN :accountIds
    ];

    List<Account> accountsToUpdate = new List<Account>();
    for (Account acc : accountsToProcess) {
      String payload = buildAPIPayload(acc);
      Map<String, Object> apiResponse = mockAPICall(acc.Id, payload);
      Boolean isSuccess = (Boolean) apiResponse.get('success');

      if (isSuccess) {
        accountsToUpdate.add(
          new Account(
            Id = acc.Id,
            Experian_AMS_Registration_status__c = 'Registered'
          )
        );
        ExperianLogger.log(
          'API call successful for account: ' + acc.Id,
          ExperianLogger.LogLevel.INFO
        );
      } else {
        ExperianLogger.log(
          'API call failed for account: ' + acc.Id,
          ExperianLogger.LogLevel.WARN
        );
      }
    }

    if (!accountsToUpdate.isEmpty()) {
      try {
        update accountsToUpdate;
        ExperianLogger.log(
          'Successfully updated ' + accountsToUpdate.size() + ' accounts',
          ExperianLogger.LogLevel.INFO
        );
      } catch (Exception e) {
        ExperianLogger.log(
          'Error updating accounts: ' +
            e.getMessage() +
            '\n' +
            e.getStackTraceString(),
          ExperianLogger.LogLevel.ERROR
        );
      }
    } else {
      ExperianLogger.log('No accounts to update', ExperianLogger.LogLevel.WARN);
    }
  }

  private String buildAPIPayload(Account acc) {
    String formattedZip = formatZipCode(acc.BillingPostalCode);

    Map<String, Object> payloadMap = new Map<String, Object>{
      'userTrackingId' => acc.Id,
      'name' => acc.Name,
      'street' => acc.BillingStreet != null
        ? acc.BillingStreet.split('\n')[0]
        : '',
      'street2' => acc.BillingStreet != null &&
        acc.BillingStreet.split('\n').size() > 1
        ? acc.BillingStreet.split('\n')[1]
        : '',
      'city' => acc.BillingCity,
      'state' => acc.BillingState,
      'zip' => formattedZip,
      'comments' => 'API Registration'
    };

    String payload = JSON.serialize(payloadMap);
    ExperianLogger.log(
      'Built API payload for account ' + acc.Id + ': ' + payload,
      ExperianLogger.LogLevel.DEBUG
    );
    return payload;
  }

  private String formatZipCode(String zipCode) {
    if (String.isBlank(zipCode)) {
      return '00000'; // Default value if zip code is blank
    }

    // Remove any non-numeric characters
    String numericZip = zipCode.replaceAll('[^0-9]', '');

    // Take the first 5 digits, or pad with zeros if less than 5 digits
    String formattedZip = numericZip.left(5).rightPad(5, '0');

    ExperianLogger.log(
      'Formatted zip code: ' + formattedZip + ' (original: ' + zipCode + ')',
      ExperianLogger.LogLevel.DEBUG
    );
    return formattedZip;
  }

  private Map<String, Object> mockAPICall(Id accountId, String payload) {
    // Simulate API call delay
    Long startTime = System.now().getTime();
    while (System.now().getTime() - startTime < 1000) {
      // Simulate processing time
    }

    // Mock API response
    Map<String, Object> response = new Map<String, Object>{
      'success' => true,
      'message' => 'Registration successful',
      'accountId' => accountId,
      'timestamp' => System.now()
    };

    ExperianLogger.log(
      'Mock API call for account ' + accountId + ' with payload: ' + payload,
      ExperianLogger.LogLevel.INFO
    );
    ExperianLogger.log(
      'Mock API response for account ' +
        accountId +
        ': ' +
        JSON.serialize(response),
      ExperianLogger.LogLevel.DEBUG
    );
    return response;
  }
}
