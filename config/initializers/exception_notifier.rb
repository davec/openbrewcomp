ExceptionNotifier.exception_recipients = %w(brewcomp_admin@example.com)
ExceptionNotifier.sender_address = %Q(#{APP_CONFIG[:competition_name]} Error <#{APP_CONFIG[:account_mgmt_email]}>)
