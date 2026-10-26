trigger FSC_LoanApplicationAssetTrigger on LoanApplicationAsset(before insert, before update, before delete, after insert, after update, after delete) {
	if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
		FSC_CapturaOperacionesService.compartirRelacionados(Trigger.new, 'LoanApplicationAssetShare');
	}

	if (Trigger.isBefore) {
		if (Trigger.isDelete) {
			FSC_CreditoAprobadoLockService.validarActivosSolicitud(Trigger.old);
		} else {
			FSC_CreditoAprobadoLockService.validarActivosSolicitud(Trigger.new, Trigger.oldMap);
		}
	}

	if (Trigger.isInsert) {
		FSC_TipoGarantiaService.publishForRelatedRecords(Trigger.new, 'LoanApplicationId');
	} else if (Trigger.isUpdate) {
		FSC_TipoGarantiaService.publishForRelatedRecords(Trigger.new, Trigger.old, 'LoanApplicationId');
	} else if (Trigger.isDelete) {
		FSC_TipoGarantiaService.publishForRelatedRecords(Trigger.old, 'LoanApplicationId');
	}
}