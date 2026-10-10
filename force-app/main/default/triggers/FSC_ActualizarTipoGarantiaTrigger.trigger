trigger FSC_ActualizarTipoGarantiaTrigger on FSC_Actualizar_Tipo_Garantia__e(after insert) {
	Set<Id> residentialLoanApplicationIds = new Set<Id>();
	for (FSC_Actualizar_Tipo_Garantia__e eventRecord : Trigger.new) {
		if (!String.isBlank(eventRecord.FSC_ResidentialLoanApplicationId__c)) {
			residentialLoanApplicationIds.add((Id) eventRecord.FSC_ResidentialLoanApplicationId__c);
		}
	}

	FSC_TipoGarantiaService.recalculate(residentialLoanApplicationIds);
}