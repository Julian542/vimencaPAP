trigger AccountTrigger on Account(after insert, before update) {
  FSCClientsHelper helper = new FSCClientsHelper();
  String username = UserInfo.getUserName();
  Bypass_Trigger__c btInstance = Bypass_Trigger__c.getInstance();
  List<String> listUsersBypass = (btInstance.Usernames_Allowed__c != null) ? btInstance.Usernames_Allowed__c.split(';') : new List<String>();

  for (Account account : Trigger.New) {
    if (Trigger.isAfter && Trigger.isInsert) {
      if (!listUsersBypass.contains(username)) {
        helper.createCIF(account);
      }
    }
    if (Trigger.isBefore && Trigger.isUpdate) {
      if (!listUsersBypass.contains(username)) {
        helper.updateCIF(account);
      }
    }
  }
}