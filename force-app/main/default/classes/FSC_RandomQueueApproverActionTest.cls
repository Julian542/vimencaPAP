@IsTest
private class FSC_RandomQueueApproverActionTest {

    private static final String SUBESTADO_ANALISIS = 'An\u00E1lisis de cr\u00E9dito';

    private static Account createNeutralAccount(String name) {
        Account acc = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Juridica').getRecordTypeId(),
            Name = name,
            ACC_RNC__c = String.valueOf(Math.abs(Crypto.getRandomInteger())).leftPad(9, '0').substring(0, 9),
            ACC_Condicion__c = 'PROSPECTO',
            ACC_Estado__c = 'INICIADO',
            ACC_TipoIdentificacion__c = 'RNC'
        );
        insert acc;
        return acc;
    }

    private static User createUser(String uniqueKey) {
        Profile profileRecord = [
            SELECT Id
            FROM Profile
            WHERE Id = :UserInfo.getProfileId()
            LIMIT 1
        ];

        User userRecord = new User(
            FirstName = 'Test',
            LastName = uniqueKey,
            Alias = uniqueKey.length() > 8 ? uniqueKey.substring(0, 8) : uniqueKey,
            Email = uniqueKey + '@test.com',
            Username = uniqueKey + '.' + System.now().getTime() + '@test.com',
            CommunityNickname = uniqueKey + String.valueOf(Math.mod(System.now().getTime(), 100000)),
            TimeZoneSidKey = 'America/Argentina/Buenos_Aires',
            LocaleSidKey = 'es_AR',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'es',
            ProfileId = profileRecord.Id
        );
        insert userRecord;
        return userRecord;
    }

    @IsTest
    static void run_returnsRandomActiveUserFromNestedGroups() {
        User approverOne = createUser('aprobador1');
        User approverTwo = createUser('aprobador2');

        Group queueGroup = new Group(Name = 'Cola Test Aprobacion', DeveloperName = 'Cola_Test_Aprobacion', Type = 'Queue');
        insert queueGroup;

        Group publicGroup = new Group(Name = 'Public Group Test', DeveloperName = 'Public_Group_Test', Type = 'Regular');
        insert publicGroup;

        insert new GroupMember(GroupId = queueGroup.Id, UserOrGroupId = publicGroup.Id);
        insert new GroupMember(GroupId = publicGroup.Id, UserOrGroupId = approverOne.Id);
        insert new GroupMember(GroupId = publicGroup.Id, UserOrGroupId = approverTwo.Id);

        FSC_RandomQueueApproverAction.Input inputItem = new FSC_RandomQueueApproverAction.Input();
        inputItem.groupId = queueGroup.Id;
        inputItem.assignedUserFieldApiName = null;

        Test.startTest();
        List<FSC_RandomQueueApproverAction.Output> outputs =
            FSC_RandomQueueApproverAction.run(new List<FSC_RandomQueueApproverAction.Input>{ inputItem });
        Test.stopTest();

        System.assertEquals(1, outputs.size());
        System.assert(
            new Set<Id>{ approverOne.Id, approverTwo.Id }.contains(outputs[0].userId),
            'Debe devolver un usuario activo perteneciente a la cola.'
        );
    }

    @IsTest
    static void run_returnsLeastLoadedUser() {
        User leastLoadedUser = createUser('analistaMin');
        User busiestUser = createUser('analistaMax');

        Group queueGroup = new Group(Name = 'Cola Menor Carga', DeveloperName = 'Cola_Menor_Carga', Type = 'Queue');
        insert queueGroup;

        Group publicGroup = new Group(Name = 'Public Group Menor Carga', DeveloperName = 'Public_Group_Menor_Carga', Type = 'Regular');
        insert publicGroup;

        insert new GroupMember(GroupId = queueGroup.Id, UserOrGroupId = publicGroup.Id);
        insert new GroupMember(GroupId = publicGroup.Id, UserOrGroupId = leastLoadedUser.Id);
        insert new GroupMember(GroupId = publicGroup.Id, UserOrGroupId = busiestUser.Id);

        System.runAs(leastLoadedUser) {
            Account acc = createNeutralAccount('Cuenta test menor carga');

            insert new List<ResidentialLoanApplication>{
                new ResidentialLoanApplication(
                    Name = 'RLA 1',
                    AccountId = acc.Id,
                    Status = 'En proceso',
                    FSC_Subestado__c = SUBESTADO_ANALISIS,
                    FSC_UsuarioAnalista__c = busiestUser.Id
                ),
                new ResidentialLoanApplication(
                    Name = 'RLA 2',
                    AccountId = acc.Id,
                    Status = 'En proceso',
                    FSC_Subestado__c = SUBESTADO_ANALISIS,
                    FSC_UsuarioAnalista__c = busiestUser.Id
                )
            };
        }

        FSC_RandomQueueApproverAction.Input inputItem = new FSC_RandomQueueApproverAction.Input();
        inputItem.groupId = queueGroup.Id;
        inputItem.assignedUserFieldApiName = 'FSC_UsuarioAnalista__c';

        Test.startTest();
        List<FSC_RandomQueueApproverAction.Output> outputs =
            FSC_RandomQueueApproverAction.run(new List<FSC_RandomQueueApproverAction.Input>{ inputItem });
        Test.stopTest();

        System.assertEquals(1, outputs.size());
        System.assertEquals(leastLoadedUser.Id, outputs[0].userId);
    }

    @IsTest
    static void run_returnsLeastLoadedUserForComiteField() {
        User leastLoadedUser = createUser('comiteMin');
        User busiestUser = createUser('comiteMax');

        Group queueGroup = new Group(Name = 'Cola Comite Menor Carga', DeveloperName = 'Cola_Comite_Menor_Carga', Type = 'Queue');
        insert queueGroup;

        Group publicGroup = new Group(Name = 'Public Group Comite Menor Carga', DeveloperName = 'Public_Group_Comite_Menor_Carga', Type = 'Regular');
        insert publicGroup;

        insert new GroupMember(GroupId = queueGroup.Id, UserOrGroupId = publicGroup.Id);
        insert new GroupMember(GroupId = publicGroup.Id, UserOrGroupId = leastLoadedUser.Id);
        insert new GroupMember(GroupId = publicGroup.Id, UserOrGroupId = busiestUser.Id);

        System.runAs(leastLoadedUser) {
            Account acc = createNeutralAccount('Cuenta test menor carga comite');

            insert new List<ResidentialLoanApplication>{
                new ResidentialLoanApplication(
                    Name = 'RLA comite 1',
                    AccountId = acc.Id,
                    Status = 'En proceso',
                    FSC_Subestado__c = SUBESTADO_ANALISIS,
                    FSC_UsuarioComite__c = busiestUser.Id
                ),
                new ResidentialLoanApplication(
                    Name = 'RLA comite 2',
                    AccountId = acc.Id,
                    Status = 'En proceso',
                    FSC_Subestado__c = SUBESTADO_ANALISIS,
                    FSC_UsuarioComite__c = busiestUser.Id
                )
            };
        }

        FSC_RandomQueueApproverAction.Input inputItem = new FSC_RandomQueueApproverAction.Input();
        inputItem.groupId = queueGroup.Id;
        inputItem.assignedUserFieldApiName = 'FSC_UsuarioComite__c';

        Test.startTest();
        List<FSC_RandomQueueApproverAction.Output> outputs =
            FSC_RandomQueueApproverAction.run(new List<FSC_RandomQueueApproverAction.Input>{ inputItem });
        Test.stopTest();

        System.assertEquals(1, outputs.size());
        System.assertEquals(leastLoadedUser.Id, outputs[0].userId);
    }

    @IsTest
    static void run_returnsNullWhenGroupHasNoUsers() {
        Group queueGroup = new Group(Name = 'Cola Sin Usuarios', DeveloperName = 'Cola_Sin_Usuarios', Type = 'Queue');
        insert queueGroup;

        FSC_RandomQueueApproverAction.Input inputItem = new FSC_RandomQueueApproverAction.Input();
        inputItem.groupId = queueGroup.Id;
        inputItem.assignedUserFieldApiName = 'Campo_No_Soportado__c';

        Test.startTest();
        List<FSC_RandomQueueApproverAction.Output> outputs =
            FSC_RandomQueueApproverAction.run(new List<FSC_RandomQueueApproverAction.Input>{ inputItem });
        Test.stopTest();

        System.assertEquals(1, outputs.size());
        System.assertEquals(null, outputs[0].userId);
    }

    @IsTest
    static void helpers_coverNullAndRecursiveCollection() {
        Group parentGroup = new Group(Name = 'Parent Group Test', DeveloperName = 'Parent_Group_Test', Type = 'Regular');
        insert parentGroup;

        Group childGroup = new Group(Name = 'Child Group Test', DeveloperName = 'Child_Group_Test', Type = 'Regular');
        insert childGroup;

        insert new GroupMember(GroupId = childGroup.Id, UserOrGroupId = UserInfo.getUserId());
        insert new GroupMember(GroupId = parentGroup.Id, UserOrGroupId = childGroup.Id);

        System.assertEquals(null, FSC_RandomQueueApproverAction.selectApproverId(null, 'FSC_UsuarioAnalista__c'));
        System.assert(FSC_RandomQueueApproverAction.collectCandidatePrincipalIds(parentGroup.Id).contains(UserInfo.getUserId()));
        System.assertEquals(
            new List<Id>{ UserInfo.getUserId() },
            FSC_RandomQueueApproverAction.extractUserIds(
                new List<User>{ new User(Id = UserInfo.getUserId()) }
            )
        );
        System.assertEquals(null, FSC_RandomQueueApproverAction.selectRandomUserId(new List<Id>()));
        System.assertEquals(UserInfo.getUserId(), FSC_RandomQueueApproverAction.selectRandomUserId(new List<Id>{ UserInfo.getUserId() }));
    }
}
