trigger ContactPointAddressTrigger on ContactPointAddress (
  after insert,
  after update,
  after delete,
  after undelete
) {
  System.debug('ContactPointAddressTrigger inicio. isInsert=' + Trigger.isInsert + ', isUpdate=' + Trigger.isUpdate + ', isDelete=' + Trigger.isDelete + ', isUndelete=' + Trigger.isUndelete);

  Set<Id> parentIds = new Set<Id>();

  if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
    for (ContactPointAddress cpa : Trigger.new) {
      if (cpa.ParentId != null) {
        parentIds.add(cpa.ParentId);
      }
    }
  }

  if (Trigger.isUpdate || Trigger.isDelete) {
    for (ContactPointAddress cpaOld : Trigger.old) {
      if (cpaOld.ParentId != null) {
        parentIds.add(cpaOld.ParentId);
      }
    }
  }

  if (!parentIds.isEmpty()) {
    ContactPointAccountSyncService.syncAddresses(parentIds);
  }
}