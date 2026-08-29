trigger ContactPointEmailTrigger on ContactPointEmail (
  after insert,
  after update,
  after delete,
  after undelete
) {
  System.debug('ContactPointEmailTrigger inicio. isInsert=' + Trigger.isInsert + ', isUpdate=' + Trigger.isUpdate + ', isDelete=' + Trigger.isDelete + ', isUndelete=' + Trigger.isUndelete);

  Set<Id> parentIds = new Set<Id>();

  if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
    for (ContactPointEmail cpe : Trigger.new) {
      if (cpe.ParentId != null) {
        parentIds.add(cpe.ParentId);
      }
    }
  }

  if (Trigger.isUpdate || Trigger.isDelete) {
    for (ContactPointEmail cpeOld : Trigger.old) {
      if (cpeOld.ParentId != null) {
        parentIds.add(cpeOld.ParentId);
      }
    }
  }

  if (!parentIds.isEmpty()) {
    ContactPointAccountSyncService.syncEmails(parentIds);
  }
}