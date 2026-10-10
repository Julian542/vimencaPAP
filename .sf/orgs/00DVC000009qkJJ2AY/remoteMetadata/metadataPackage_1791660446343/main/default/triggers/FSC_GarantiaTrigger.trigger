trigger FSC_GarantiaTrigger on FSC_Garantia__c(before insert, before update, before delete, after insert, after update, after delete) {
	if (Trigger.isBefore) {
		if (!Trigger.isDelete) {
			// Los codigos solo cambian si cambio su texto, por lo que no alteran el bloqueo de creditos aprobados.
			FSC_CatalogoGarantiaService.resolverCodigos(Trigger.new, Trigger.isUpdate ? Trigger.oldMap : null);
		}
		if (Trigger.isUpdate) {
			FSC_CreditoAprobadoLockService.validarGarantias(Trigger.new, Trigger.oldMap, true);
		} else if (Trigger.isDelete) {
			FSC_CreditoAprobadoLockService.validarGarantias(Trigger.old, null, false);
		} else {
			FSC_CreditoAprobadoLockService.validarGarantias(Trigger.new, null, false);
		}
	}

	if (Trigger.isAfter) {
		if (Trigger.isInsert) {
			FSC_RegenerarSolicitudCreditoService.enqueueRegenerationForRelatedRecords(Trigger.new);
			FSC_TipoGarantiaService.publishForRelatedRecords(Trigger.new, 'FSC_Residential_Loan_Application__c');
		} else if (Trigger.isUpdate) {
			FSC_RegenerarSolicitudCreditoService.enqueueRegenerationForRelatedRecords(Trigger.new, Trigger.oldMap);
			FSC_TipoGarantiaService.publishForRelatedRecords(
				Trigger.new,
				Trigger.old,
				'FSC_Residential_Loan_Application__c'
			);
		} else if (Trigger.isDelete) {
			FSC_RegenerarSolicitudCreditoService.enqueueRegenerationForRelatedRecords(Trigger.old);
			FSC_TipoGarantiaService.publishForRelatedRecords(Trigger.old, 'FSC_Residential_Loan_Application__c');
		}
	}
}