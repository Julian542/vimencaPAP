trigger ContactPointPhoneTrigger on ContactPointPhone (
  after insert,
  after update,
  after delete,
  after undelete
) {
  System.debug('ContactPointPhoneTrigger inicio. isInsert=' + Trigger.isInsert + ', isUpdate=' + Trigger.isUpdate + ', isDelete=' + Trigger.isDelete + ', isUndelete=' + Trigger.isUndelete);

  Set<Id> parentIds = new Set<Id>();

  if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
    for (ContactPointPhone cpp : Trigger.new) {
      if (cpp.ParentId != null) {
        parentIds.add(cpp.ParentId);
      }
    }
  }

  if (Trigger.isUpdate || Trigger.isDelete) {
    for (ContactPointPhone cppOld : Trigger.old) {
      if (cppOld.ParentId != null) {
        parentIds.add(cppOld.ParentId);
      }
    }
  }

  if (!parentIds.isEmpty()) {
    ContactPointAccountSyncService.syncPhones(parentIds);
  }
}