trigger FSC_LoanApplicantTrigger on LoanApplicant(before insert, before update, before delete, after insert, after update, after delete) {
	if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
		FSC_CapturaOperacionesService.compartirRelacionados(Trigger.new, 'LoanApplicantShare');
	}

	if (Trigger.isBefore) {
		if (Trigger.isDelete) {
			FSC_CreditoAprobadoLockService.validarParticipantes(Trigger.old);
		} else {
			FSC_CreditoAprobadoLockService.validarParticipantes(Trigger.new);
		}
	}

	if (Trigger.isAfter) {
		if (Trigger.isInsert) {
			FSC_RegenerarSolicitudCreditoService.enqueueRegenerationForRelatedRecords(Trigger.new);
			FSC_TipoGarantiaService.publishForRelatedRecords(Trigger.new, 'LoanApplicationId');
		} else if (Trigger.isUpdate) {
			FSC_RegenerarSolicitudCreditoService.enqueueRegenerationForRelatedRecords(Trigger.new, Trigger.oldMap);
			FSC_TipoGarantiaService.publishForRelatedRecords(Trigger.new, Trigger.old, 'LoanApplicationId');
		} else if (Trigger.isDelete) {
			FSC_RegenerarSolicitudCreditoService.enqueueRegenerationForRelatedRecords(Trigger.old);
			FSC_TipoGarantiaService.publishForRelatedRecords(Trigger.old, 'LoanApplicationId');
		}
	}
}