public with sharing class FSC_OmniSearchablePicklistController {
	public class OptionDTO {
		@AuraEnabled
		public String label { get; set; }
		@AuraEnabled
		public String value { get; set; }

		public OptionDTO(String label, String value) {
			this.label = label;
			this.value = value;
		}
	}

	@AuraEnabled(cacheable=true)
	public static List<OptionDTO> getReferidorOptions() {
		List<OptionDTO> options = new List<OptionDTO>();
		for (FSC_Referidor__mdt referidor : [
			SELECT MasterLabel, FSC_NombreReferidor__c
			FROM FSC_Referidor__mdt
			ORDER BY FSC_NombreReferidor__c ASC, MasterLabel ASC
		]) {
			String referidorName = String.isBlank(referidor.FSC_NombreReferidor__c) ? referidor.MasterLabel : referidor.FSC_NombreReferidor__c;
			if (!String.isBlank(referidorName)) {
				options.add(new OptionDTO(referidorName, referidorName));
			}
		}
		return options;
	}
}