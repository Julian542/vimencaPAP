/*************************
* @Class Name:- FSCWlthUpdateProfileFlowHelperClass
* @Description:- Update Profile process case creation email flow helper class
**************************/
public class FSCWlthUpdateProfileFlowHelperClass {
    
    public class FlowInputs{
        @InvocableVariable(label='Service Catalog Request Id' required=true)
        public String inputRecordId;
    }
    
    //Invocable method used in the flow to get the address list
    @InvocableMethod(label='Get Addresses to replace' description='Process all extended attribute records')
    public static List<String> getAddressesList(List<FlowInputs> flowInput) {
        String svcRecordId = flowInput[0].inputRecordId;

        List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrVals = [SELECT Id, SvcCtlgItemAttrDeveloperName, GroupNumber, TextValue FROM SvcCatalogReqExtdAttrVal WHERE SvcCatalogRequestId = :svcRecordId WITH SECURITY_ENFORCED ORDER BY GroupNumber ASC NULLS FIRST];
        map<String, String> addressDetailsMap = new map<String, String>();
        List<map<String, String>> addressDetailsList = new List<map<String, String>>();
        Map<Integer, map<String, String>> addressDetailsAttrVal = getAddressDetails(svcCatalogReqExtdAttrVals);

        for (Integer groupNumber: addressDetailsAttrVal.keyset()){            
            addressDetailsMap = addressDetailsAttrVal.get(groupNumber); 
            addressDetailsList.add(addressDetailsMap);
        } 
        
        String addressesToUpdatelabel = '<b> List of addresses to be updated</b><br><br>';
        String addressBody = FSCWlthUtilityClass.constructEmailBody(addressDetailsList, addressesToUpdatelabel, false);
        List<String> bodyList = new List<String>();
        bodyList.add(addressBody);
        return bodyList;
    } 
    
    //looping through the svcCatalogReqExtdAttrVals records to get the array of addresses
    private static Map<Integer, map<String, String>> getAddressDetails(List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrVals) {
        Map<Integer, Map<String, String>> addressGroupNumMap = new Map<Integer, Map<String, String>>();
        String addressType = null;
        String previousAddress = null;

        for (SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrVal : svcCatalogReqExtdAttrVals) {
            switch on svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName {
                when 'addresses_to_update' {
                    previousAddress = svcCatalogReqExtdAttrVal.TextValue;  
                } when 'account_type' {
                    addressType = svcCatalogReqExtdAttrVal.TextValue;
                }
            } 

            Integer groupNumber = svcCatalogReqExtdAttrVal.GroupNumber;
            if (groupNumber != null) {
                map<String, String> addressMap = addressGroupNumMap.get(groupNumber);
                addressMap = new Map<String, String>();
                addressGroupNumMap.put(groupNumber, addressMap);
                addressMap.put('Account Type', addressType);
                if (previousAddress != null) 
                    addressMap.put('Addresses To Update', previousAddress);
                else
                    addressMap.put('Addresses To Update', '-');
            }             
        }
        return addressGroupNumMap;
    }
}