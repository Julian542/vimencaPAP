@IsTest
private class FSC_RandomQueueApproverActionTest {

    private static final String SUBESTADO_ANALISIS = 'An\u00E1lisis de cr\u00E9dito';

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
        completarCamposObligatoriosUsuario(userRecord);
        insert userRecord;
        return userRecord;
    }

    // La org exige Oficina, Codigo y Canal de Atencion en todo usuario (regla Validar_Campos_Obligatorios_Usuario).
    private static void completarCamposObligatoriosUsuario(User usuario) {
        Map<String, Schema.SObjectField> campos = Schema.SObjectType.User.fields.getMap();
        for (String campo : new List<String>{ 'USE_Oficina__c', 'Canal_Atencion__c' }) {
            if (!campos.containsKey(campo)) {
                continue;
            }
            for (Schema.PicklistEntry valor : campos.get(campo).getDescribe().getPicklistValues()) {
                if (valor.isActive()) {
                    usuario.put(campo, valor.getValue());
                    break;
                }
            }
        }
        if (campos.containsKey('USE_Codigo__c')) {
            usuario.put('USE_Codigo__c', 'TEST');
        }
        if (campos.containsKey('USE_Oficina__c')) {
            asegurarOficinaEnDatosMaestros((String) usuario.get('USE_Oficina__c'));
        }
    }

    // El flow "Información usuario" busca la oficina del usuario en Datos_Maestros__c y falla si no existe.
    private static void asegurarOficinaEnDatosMaestros(String oficina) {
        if (String.isBlank(oficina) || [SELECT COUNT() FROM Datos_Maestros__c WHERE DM_Codigo_Oficina__c = :oficina AND DM_Tipo__c = 'Oficina'] > 0) {
            return;
        }
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert new Datos_Maestros__c(Name = 'Oficina test ' + oficina, DM_Codigo_Oficina__c = oficina, DM_Tipo__c = 'Oficina');
        }
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
            Account acc = new Account(Name = 'Cuenta test menor carga');
            insert acc;

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
            Account acc = new Account(Name = 'Cuenta test menor carga comite');
            insert acc;

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