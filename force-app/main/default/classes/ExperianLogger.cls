public without sharing class ExperianLogger {
  public enum LogLevel {
    DISABLED,
    ERROR,
    WARN,
    INFO,
    DEBUG
  }

  private static LogLevel currentLogLevel;

  static {
    initializeLogLevel();
  }

  private static void initializeLogLevel() {
    try {
      Experian_Configuration__c settings = [
        SELECT Log_Level__c
        FROM Experian_Configuration__c
        LIMIT 1
      ];
      if (settings != null && String.isNotBlank(settings.Log_Level__c)) {
        currentLogLevel = LogLevel.valueOf(settings.Log_Level__c);
        System.debug('currentLogLevel: ' + currentLogLevel);
      } else {
        currentLogLevel = LogLevel.ERROR; // Default log level
      }
    } catch (Exception e) {
      System.debug('Failed to initialize log level: ' + e.getMessage());
      currentLogLevel = LogLevel.ERROR; // Fallback to ERROR level
    }
  }

  public static void log(String message, LogLevel logLevel) {
    if (shouldLog(logLevel)) {
      // Truncate the message if it's longer than 255 characters
      String truncatedMessage = message.length() > 254
        ? message.substring(0, 248) + '...'
        : message;

      Experian_Logs__c logEntry = new Experian_Logs__c(
        Message__c = truncatedMessage,
        Log_Level__c = logLevel.name()
      );

      try {
        insert logEntry;
      } catch (Exception e) {
        throw e;
        // handleLoggingError(e, truncatedMessage, logLevel);
      }
    }
  }

  private static Boolean shouldLog(LogLevel logLevel) {
    if (currentLogLevel == null) {
      initializeLogLevel();
    }
    return logLevel.ordinal() > ExperianLogger.LogLevel.DISABLED.ordinal() &&
      logLevel.ordinal() <= currentLogLevel.ordinal();
  }

  private static void handleLoggingError(
    Exception e,
    String originalMessage,
    LogLevel originalLogLevel
  ) {
    String errorMessage =
      'Failed to log message. Original message: ' +
      originalMessage +
      '. Original log level: ' +
      originalLogLevel +
      '. Error: ' +
      e.getMessage();
    System.debug(LoggingLevel.ERROR, errorMessage);
    // Consider implementing additional error handling here, such as sending an email alert
  }
}
