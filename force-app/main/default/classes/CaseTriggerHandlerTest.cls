/**
 * @description       :
 * @author            : Kevin Vega H
 * @group             :
 * @last modified on  : 02-03-2023
 * @last modified by  : Kevin Vega H
 **/
@isTest
public class CaseTriggerHandlerTest {
  @TestSetup
  static void prepareData() {
    TestDataFactory.createTestData();

    List<Asset> assetToUpdate = new List<Asset>();
    List<Case> lstCase = new List<Case>();

    List<Asset> cuentasFinancieras = [
      SELECT Id, CreatedDate, Accountid
      FROM Asset
      LIMIT 2
    ];

    for (Integer i = 0; i < cuentasFinancieras.size(); i++) {
      cuentasFinancieras[i].ASE_Fecha_de_apertura__c = null;
      cuentasFinancieras[i].ASE_Estado__c = 'PTE. APERTURA';

      Test.setCreatedDate(cuentasFinancieras[i].Id, System.today() - 1);
      assetToUpdate.add(cuentasFinancieras[i]);
      Case c = new Case();
      c.AssetId = cuentasFinancieras[i].Id;
      c.AccountId = cuentasFinancieras[i].AccountId;
      c.Type = 'S25';
      c.Type__c = null;
      c.Description = (i == 0)
        ? ' Maxime mollitia,   molestiae. \n quas \n\n\n vel. '
        : null;
      c.CAS_Solucion_de_Reclamacion__c = (i == 0)
        ? ' Maxime mollitia,   molestiae. \n quas \n\n\n vel. '
        : null;
      lstCase.add(c);
    }

    update assetToUpdate;
    insert lstCase;
  }

  @isTest
  static void testFormatFields() {
    Test.startTest();
    Case[] cases = [
      SELECT Id, Description, CAS_Solucion_de_Reclamacion__c
      FROM Case
    ];
    Test.stopTest();

    System.assertEquals(
      'Maxime mollitia, molestiae. quas vel.',
      cases[0].Description,
      'Description is formated.'
    );
    System.assertEquals(
      'Maxime mollitia, molestiae. quas vel.',
      cases[0].CAS_Solucion_de_Reclamacion__c,
      'CAS_Solucion_de_Reclamacion__c is formated.'
    );
  }

  @IsTest
  static void setLabelToTypeField() {
    Case caseRecord = [
      SELECT Id, Type, Type__c
      FROM Case
      LIMIT 1
    ];

    Schema.PicklistEntry typeEntry = Case.Type.getDescribe().getPicklistValues()[0];
    caseRecord.Type = typeEntry.getValue();

    Test.startTest();
    CaseTriggerHandler.setLabelToTypeField(caseRecord);
    System.assertEquals(
      typeEntry.getLabel(),
      caseRecord.Type__c,
      'Should save the Type-label.'
    );
    Test.stopTest();
  }

  @IsTest
  static void coversFormattingRoutingGuardsAndSubject() {
    String longText = '';
    for (Integer i = 0; i < 180; i++) {
      longText += 'D';
    }
    String longSolution = '';
    for (Integer i = 0; i < 180; i++) {
      longSolution += 'S';
    }
    Case record = new Case(
      Description = '  Texto   con espacios y saltos\n\n',
      CAS_Solucion_de_Reclamacion__c = '  Solucion   normalizada  '
    );
    Case longRecord = new Case(
      Description = longText,
      CAS_Solucion_de_Reclamacion__c = longSolution
    );

    CaseTriggerHandler.formatFields(record);
    CaseTriggerHandler.formatFields(longRecord);
    CaseTriggerHandler.formatFields(new Case());
    CaseTriggerHandler.formatFields(null);

    System.assertEquals('Texto con espacios y saltos', record.Description);
    System.assertEquals(180, longRecord.Description.length());
    System.assertEquals(150, longRecord.TXT_Descripcion_corta__c.length());
    System.assertEquals(150, longRecord.TXT_Resultado_de_la_Reclamacion_corta__c.length());

    Case.Type.getDescribe().getPicklistValues();
    Case subjectRecord = new Case();
    CaseTriggerHandler.setSubjectFromTypeLabel(null);
    CaseTriggerHandler.setSubjectFromTypeLabel(subjectRecord);
    CaseTriggerHandler.setSubjectFromTypeLabel(new Case(Type = 'INVALID_TYPE'));
    Schema.PicklistEntry firstType = Case.Type.getDescribe().getPicklistValues()[0];
    Case validSubjectRecord = new Case(Type = firstType.getValue());
    CaseTriggerHandler.setSubjectFromTypeLabel(validSubjectRecord);
    CaseTriggerHandler.setLabelToTypeField(null);

    CaseTriggerHandler.routeSolicitudesBeforeInsert(null);
    CaseTriggerHandler.routeSolicitudesBeforeInsert(new List<Case>());
    CaseTriggerHandler.routeSolicitudesBeforeInsert(new List<Case>{ new Case() });
    CaseTriggerHandler.routeReclamacionesBeforeInsert(null);
    CaseTriggerHandler.routeReclamacionesBeforeInsert(new List<Case>());
    CaseTriggerHandler.routeReclamacionesBeforeInsert(new List<Case>{ new Case() });
    Case existingCase = [SELECT Id FROM Case LIMIT 1];
    CaseTriggerHandler.routeSolicitudesBeforeUpdate(null, null);
    CaseTriggerHandler.routeSolicitudesBeforeUpdate(new List<Case>(), new Map<Id, Case>());
    CaseTriggerHandler.routeSolicitudesBeforeUpdate(
      new List<Case>{ new Case(Id = existingCase.Id) },
      new Map<Id, Case>()
    );
    CaseTriggerHandler.routeReclamacionesBeforeUpdate(null, null);
    CaseTriggerHandler.routeReclamacionesBeforeUpdate(new List<Case>(), new Map<Id, Case>());
    CaseTriggerHandler.routeReclamacionesBeforeUpdate(
      new List<Case>{ new Case(Id = existingCase.Id) },
      new Map<Id, Case>()
    );
    CaseTriggerHandler.assignBranchAndQueue(new List<Case>(), null, true, false);
    Account existingAccount = [SELECT Id FROM Account LIMIT 1];
    Case unassignedCase = new Case(AccountId = existingAccount.Id);
    CaseTriggerHandler.assignBranchAndQueue(
      new List<Case>{ unassignedCase },
      null,
      true,
      false
    );

    System.assertEquals(null, subjectRecord.Subject);
    System.assertNotEquals(null, validSubjectRecord.Subject);
  }

  @IsTest
  static void assignsTheAccountBranchAndConfiguredQueueInMemory() {
    List<Group> legalQueues = [
      SELECT Id, DeveloperName
      FROM Group
      WHERE Type = 'Queue' AND DeveloperName = 'FSC_Legal'
      LIMIT 1
    ];
    String queueDeveloperName = legalQueues.isEmpty()
      ? 'QUEUE_NOT_PRESENT'
      : legalQueues[0].DeveloperName;
    Sucursal__c branch = new Sucursal__c(
      Name = 'Coverage Branch',
      External_ID__c = 'BR' + String.valueOf(System.now().getTime()).right(8),
      SUC_Active__c = true,
      SUC_BranchType__c = 'Sucursal',
      SUC_Country__c = 'República Dominicana',
      SUC_Province__c = 'Santo Domingo',
      SUC_City__c = 'Santo Domingo',
      SUC_Street__c = 'Calle Coverage',
      SUC_Neighborhood__c = 'Centro',
      SUC_Address__c = 'Calle Coverage 1',
      SUC_Queue__c = queueDeveloperName
    );
    insert branch;

    Account account = new Account(
      RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('Candidato_Persona_Juridica').getRecordTypeId(),
      Name = 'Coverage branch account',
      ACC_RNC__c = '131' + String.valueOf(Math.abs(Crypto.getRandomInteger())).left(6),
      ACC_TipoIdentificacion__c = 'RNC',
      ACC_Condicion__c = 'PROSPECTO',
      ACC_Estado__c = 'INICIADO',
      ACC_Branch__c = branch.Id
    );
    insert account;

    Case request = new Case(AccountId = account.Id);
    String casePrefix = Case.SObjectType.getDescribe().getKeyPrefix();
    Id updateCaseId = Id.valueOf(casePrefix + '000000000008');
    Case updatedRequest = new Case(Id = updateCaseId, AccountId = account.Id);
    Case oldRequest = new Case(Id = updateCaseId);
    Test.startTest();
    CaseTriggerHandler.assignBranchAndQueue(
      new List<Case>{ request }, null, true, false
    );
    CaseTriggerHandler.assignBranchAndQueue(
      new List<Case>{ updatedRequest },
      new Map<Id, Case>{ updateCaseId => oldRequest },
      false,
      true
    );
    Test.stopTest();

    System.assertEquals(branch.Id, request.CAS_Branch__c);
    System.assertEquals(branch.Id, updatedRequest.CAS_Branch__c);
    if (!legalQueues.isEmpty()) {
      System.assertEquals(legalQueues[0].Id, request.OwnerId);
      System.assertEquals(legalQueues[0].Id, updatedRequest.OwnerId);
    }
  }

  @IsTest
  static void coversNonAssignmentBranchesInMemory() {
    Sucursal__c branchWithoutQueue = new Sucursal__c(
      Name = 'Coverage branch without queue',
      External_ID__c = 'BN' + String.valueOf(System.now().getTime()).right(8),
      SUC_Active__c = true,
      SUC_BranchType__c = 'Sucursal',
      SUC_Country__c = 'República Dominicana',
      SUC_Province__c = 'Santo Domingo',
      SUC_City__c = 'Santo Domingo',
      SUC_Street__c = 'Calle Coverage',
      SUC_Neighborhood__c = 'Centro',
      SUC_Address__c = 'Calle Coverage 2'
    );
    insert branchWithoutQueue;

    Account account = new Account(
      RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('Candidato_Persona_Juridica').getRecordTypeId(),
      Name = 'Coverage no assignment account',
      ACC_RNC__c = '131' + String.valueOf(Math.abs(Crypto.getRandomInteger())).left(6),
      ACC_TipoIdentificacion__c = 'RNC',
      ACC_Condicion__c = 'PROSPECTO',
      ACC_Estado__c = 'INICIADO',
      ACC_Branch__c = branchWithoutQueue.Id
    );
    insert account;

    String casePrefix = Case.SObjectType.getDescribe().getKeyPrefix();
    Id unchangedCaseId = Id.valueOf(casePrefix + '000000000009');
    Case unchangedRequest = new Case(
      Id = unchangedCaseId,
      AccountId = account.Id,
      CAS_Branch__c = branchWithoutQueue.Id,
      OwnerId = UserInfo.getUserId()
    );
    Case oldUnchangedRequest = new Case(
      Id = unchangedCaseId,
      AccountId = account.Id,
      CAS_Branch__c = branchWithoutQueue.Id,
      OwnerId = UserInfo.getUserId()
    );

    Test.startTest();
    CaseTriggerHandler.assignBranchAndQueue(
      new List<Case>{ unchangedRequest, new Case() },
      new Map<Id, Case>{ unchangedCaseId => oldUnchangedRequest },
      false,
      true
    );
    CaseTriggerHandler.assignBranchAndQueue(
      new List<Case>{ new Case(AccountId = account.Id) },
      null,
      true,
      false
    );

    List<RecordType> solicitudTypes = [
      SELECT Id
      FROM RecordType
      WHERE SObjectType = 'Case' AND DeveloperName = 'Solicitudes'
      LIMIT 1
    ];
    if (!solicitudTypes.isEmpty()) {
      CaseTriggerHandler.assignBranchAndQueue(
        new List<Case>{
          new Case(AccountId = account.Id, RecordTypeId = solicitudTypes[0].Id)
        },
        null,
        true,
        false
      );
    }
    Test.stopTest();

    System.assertEquals(UserInfo.getUserId(), unchangedRequest.OwnerId);
    System.assertEquals(branchWithoutQueue.Id, unchangedRequest.CAS_Branch__c);
  }
}
