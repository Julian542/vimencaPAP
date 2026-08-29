@IsTest
private class DocVencNotificationBatchTest {
    @IsTest
    static void handlesEmptyBatchLifecycle() {
        DocumentosVencimientoNotificationBatch batch =
            new DocumentosVencimientoNotificationBatch();

        Test.startTest();
        Iterable<DocumentosVencimientoNotificationBatch.WorkItem> items = batch.start(null);
        batch.execute(null, new List<DocumentosVencimientoNotificationBatch.WorkItem>());
        batch.execute(null, new List<DocumentosVencimientoNotificationBatch.WorkItem>{
            new DocumentosVencimientoNotificationBatch.WorkItem(
                null, 'Documentacion_Legal__c', 'Documento próximo', 'Cliente',
                Date.today().addDays(5), true, false
            ),
            new DocumentosVencimientoNotificationBatch.WorkItem(
                null, 'DocumentChecklistItem', 'Documento vencido', 'Cliente',
                Date.today().addDays(-2), false, true
            )
        });
        batch.finish(null);
        Test.stopTest();

        System.assertNotEquals(null, items);
        Integer itemCount = 0;
        for (DocumentosVencimientoNotificationBatch.WorkItem item : items) {
            itemCount++;
        }
        System.assertEquals(0, itemCount);
    }

    @IsTest
    static void sendsNotificationAndUpdatesChecklistFlag() {
        Group queue = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = 'FSC_Legal'
            LIMIT 1
        ];
        if ([
            SELECT COUNT()
            FROM GroupMember
            WHERE GroupId = :queue.Id AND UserOrGroupId = :UserInfo.getUserId()
        ] == 0) {
            System.runAs(new User(Id = UserInfo.getUserId())) {
                insert new GroupMember(GroupId = queue.Id, UserOrGroupId = UserInfo.getUserId());
            }
        }

        insert new Bypass_Trigger__c(
            Name = 'Batch test bypass',
            Usernames_Allowed__c = UserInfo.getUserName()
        );
        Account parent = new Account(Name = 'Document batch parent');
        insert parent;
        DocumentChecklistItem checklist = new DocumentChecklistItem(
            Name = 'Documento próximo a vencer',
            ParentRecordId = parent.Id,
            DCI_Fecha_Vencimiento__c = Date.today().addDays(5),
            DCI_Notificacion_15_Dias_Enviada__c = false,
            DCI_Notificacion_Vencido_Enviada__c = false
        );
        insert checklist;

        Iterable<DocumentosVencimientoNotificationBatch.WorkItem> startItems =
            new DocumentosVencimientoNotificationBatch().start(null);
        Integer startItemCount = 0;
        for (DocumentosVencimientoNotificationBatch.WorkItem item : startItems) {
            startItemCount++;
        }
        System.assertEquals(1, startItemCount);

        Test.startTest();
        new DocumentosVencimientoNotificationBatch().execute(
            null,
            new List<DocumentosVencimientoNotificationBatch.WorkItem>{
                new DocumentosVencimientoNotificationBatch.WorkItem(
                    checklist.Id,
                    'DocumentChecklistItem',
                    checklist.Name,
                    String.valueOf(parent.Id),
                    checklist.DCI_Fecha_Vencimiento__c,
                    true,
                    false
                )
            }
        );
        Test.stopTest();

        DocumentChecklistItem updated = [
            SELECT DCI_Notificacion_15_Dias_Enviada__c
            FROM DocumentChecklistItem
            WHERE Id = :checklist.Id
        ];
        System.assertEquals(true, updated.DCI_Notificacion_15_Dias_Enviada__c);
    }

    @IsTest
    static void sendsNotificationAndUpdatesExpiredLegalDocumentFlag() {
        Group queue = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = 'FSC_Legal'
            LIMIT 1
        ];
        if ([
            SELECT COUNT()
            FROM GroupMember
            WHERE GroupId = :queue.Id AND UserOrGroupId = :UserInfo.getUserId()
        ] == 0) {
            System.runAs(new User(Id = UserInfo.getUserId())) {
                insert new GroupMember(GroupId = queue.Id, UserOrGroupId = UserInfo.getUserId());
            }
        }

        Datos_Maestros__c activity = new Datos_Maestros__c(
            Name = 'Expired legal document activity',
            DM_Direccion__c = 'EXP-DOC-001'
        );
        insert activity;
        Lead candidate = new Lead(
            FirstName = 'Expired',
            LastName = 'Legal Document',
            Company = 'Expired legal document coverage',
            Status = 'Iniciado',
            LEA_NumIdentificacion__c = '00108803124',
            LEA_TipoIdentificacion__c = 'Cédula',
            LEA_Nacionalidad__c = 'REPUBLICA DOMINICANA',
            LEA_PersonBirthdate__c = Date.today().addYears(-30),
            LEA_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO',
            LEA_Actividad_Economica__c = activity.Id,
            LEA_Tipo_Sector__c = 'PRIVADO'
        );
        insert candidate;
        Documentacion_Legal__c document = new Documentacion_Legal__c(
            DOC_Candidato__c = candidate.Id,
            DOC_Codigo_Documento__c = 'EXPIRED-LEGAL',
            DOC_Fecha_Vencimiento__c = Date.today().addDays(-1)
        );
        insert document;

        Test.startTest();
        new DocumentosVencimientoNotificationBatch().execute(
            null,
            new List<DocumentosVencimientoNotificationBatch.WorkItem>{
                new DocumentosVencimientoNotificationBatch.WorkItem(
                    document.Id,
                    'Documentacion_Legal__c',
                    'Documento EXPIRED-LEGAL',
                    candidate.Name,
                    document.DOC_Fecha_Vencimiento__c,
                    false,
                    true
                )
            }
        );
        Test.stopTest();

        Documentacion_Legal__c updated = [
            SELECT DOC_Notificacion_Vencido_Enviada__c
            FROM Documentacion_Legal__c
            WHERE Id = :document.Id
        ];
        System.assertEquals(true, updated.DOC_Notificacion_Vencido_Enviada__c);
    }
}
