/**
 * @description       : Controlador para grilla de casos asignados al usuario logueado.
 *                      Consulta los casos donde el usuario logueado está en el campo Asignado_a__c.
 * @author            : Jhonny Peroza
 * @last modified on  : 04-06-2026
 * @last modified by  : Jhonny Peroza
 **/
public with sharing class MyAssignedCasesGridController {

    public class CaseRow {
        @AuraEnabled public Id caseId;
        @AuraEnabled public String caseNumber;
        @AuraEnabled public String tipoCaso;
        @AuraEnabled public String subject;
        @AuraEnabled public String status;
        @AuraEnabled public Datetime createdDate;
        @AuraEnabled public String ownerName;
        @AuraEnabled public String assignedToName;
    }

    @AuraEnabled(cacheable=true)
    public static List<CaseRow> getMyAssignedCases() {
        System.debug(LoggingLevel.DEBUG, 'MyAssignedCasesGridController.getMyAssignedCases()');

        List<CaseRow> rows = new List<CaseRow>();

        try {
            Id currentUserId = UserInfo.getUserId();

            System.debug(
                LoggingLevel.DEBUG,
                'Query Case en getMyAssignedCases(). currentUserId=' + currentUserId
            );

            List<Case> cases = [
                SELECT Id,
                       CaseNumber,
                       CAS_Tipo_Caso__c,
                       Subject,
                       Status,
                       CreatedDate,
                       OwnerId,
                       Owner.Name,
                       Asignado_a__c,
                       Asignado_a__r.Name
                FROM Case
                WHERE Asignado_a__c = :currentUserId
                AND IsClosed = false
                ORDER BY CreatedDate ASC
                LIMIT 200
            ];

            System.debug(
                LoggingLevel.DEBUG,
                'MyAssignedCasesGridController.getMyAssignedCases() cases.size()=' + cases.size()
            );

            for (Case c : cases) {
                System.debug(
                    LoggingLevel.DEBUG,
                    'Caso encontrado para grilla: CaseNumber=' + c.CaseNumber +
                    ', Status=' + c.Status +
                    ', OwnerId=' + c.OwnerId +
                    ', Owner.Name=' + c.Owner.Name +
                    ', Asignado_a__c=' + c.Asignado_a__c +
                    ', Asignado_a__r.Name=' + (c.Asignado_a__r != null ? c.Asignado_a__r.Name : null) +
                    ', CreatedDate=' + c.CreatedDate
                );

                CaseRow row = new CaseRow();
                row.caseId = c.Id;
                row.caseNumber = c.CaseNumber;
                row.tipoCaso = c.CAS_Tipo_Caso__c;
                row.subject = c.Subject;
                row.status = c.Status;
                row.createdDate = c.CreatedDate;
                row.ownerName = c.Owner.Name;
                row.assignedToName = c.Asignado_a__r != null ? c.Asignado_a__r.Name : null;

                rows.add(row);
            }

        } catch (Exception e) {
            System.debug(
                LoggingLevel.ERROR,
                'Error en MyAssignedCasesGridController.getMyAssignedCases(): ' + e.getMessage()
            );

            throw new AuraHandledException(
                'Ocurrió un error al consultar los casos asignados: ' + e.getMessage()
            );
        }

        return rows;
    }
}