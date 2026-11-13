// El flujo FSC_ProcesoAprobacionComite obtiene el monto por aquí: una referencia directa a FSC_Monto__c
// desde un flujo impide cambiar el tipo del campo.
public without sharing class FSC_MontoComiteAction {
    public class Input {
        @InvocableVariable(required=true)
        public Id solicitudId;
    }

    public class Output {
        @InvocableVariable
        public Decimal monto;
    }

    @InvocableMethod(
        label='FSC - Obtener monto para comité'
        description='Devuelve el monto solicitado que se compara contra los umbrales de cada nivel de comité.'
    )
    public static List<Output> run(List<Input> inputs) {
        List<Output> outputs = new List<Output>();

        if (inputs == null) {
            return outputs;
        }

        Set<Id> solicitudIds = new Set<Id>();
        for (Input inputItem : inputs) {
            if (inputItem?.solicitudId != null) {
                solicitudIds.add(inputItem.solicitudId);
            }
        }

        Map<Id, ResidentialLoanApplication> solicitudesPorId = new Map<Id, ResidentialLoanApplication>(
            [SELECT Id, FSC_Monto__c FROM ResidentialLoanApplication WHERE Id IN :solicitudIds WITH SYSTEM_MODE]
        );

        for (Input inputItem : inputs) {
            Output outputItem = new Output();
            outputItem.monto = solicitudesPorId.get(inputItem?.solicitudId)?.FSC_Monto__c;
            outputs.add(outputItem);
        }

        return outputs;
    }
}