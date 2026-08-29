/*************************
* @Class Name:- FlowMapClass
* @Description:- This class is used as apex defined variable in FSC OOTB Process flows
**************************/
public with sharing class FlowMapClass {
    @AuraEnabled
    public string key; //Map key
    @AuraEnabled
    public string value; //Map value
    public FlowMapClass(){}  
}