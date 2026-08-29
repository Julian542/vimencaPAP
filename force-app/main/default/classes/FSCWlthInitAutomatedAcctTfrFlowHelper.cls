/*************************
* @Class Name:- FSCWlthInitAutomatedAcctTfrFlowHelper
* @Description:- FSC Wealth Automated Cutomer Account transfer process case creation email flow helper class
**************************/
public with sharing class FSCWlthInitAutomatedAcctTfrFlowHelper {
    
    public class FlowInputs{
        @InvocableVariable(label='Service Catalog Request Id' required=true)
        public String inputRecordId;
    }
    
    class AttributeValueGroup { 
        String transferType;
        String transferAction;
        String transferEntireAccount;
        String mode;
        String amountMode;
        String security;
        String cash;
        String maturityAnnuityDate;
        String currencyCode;
        String amount;
        String numberOfShares;
    }
    
    //Invocable method used in the flow to get the securities list
    @InvocableMethod(label='Get Account Transfer Details' description='Process all extended attribute records')
    public static List<String> getSecuritiesList(List<FlowInputs> flowInput) {
        String svcRecordId = flowInput[0].inputRecordId;
        List<String> bodyList = new List<String>();
        String emailBody;
        String securityBody = '&nbsp;';
        //Fetch all SvcCatalogReqExtdAttrVal
        List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrVals = [SELECT Id, SvcCtlgItemAttrDeveloperName, GroupNumber, TextValue, NumberValue FROM SvcCatalogReqExtdAttrVal WHERE SvcCatalogRequestId = :svcRecordId WITH SECURITY_ENFORCED ORDER BY GroupNumber ASC NULLS FIRST];
        AttributeValueGroup attributeValueGroups = getAttributeValueGroup(svcCatalogReqExtdAttrVals);
        emailBody = '<table style="width: 100%;border-collapse: collapse;" cellspacing="0"><tr><td style="font-weight: bold;padding:6px;background-color: #F3F3F3;" colspan="2">Transfer Details</td></tr>'+
            '<tr><td style="padding: 6px;width: 30%">Selected Action</td><td style="padding: 6px;"><b>'+attributeValueGroups.transferAction+'</b></td> </tr>'+
            '<tr><td style="padding: 6px;">Transfer Type</td><td style="padding: 6px;"><b>'+attributeValueGroups.transferType+'</b></td> </tr>';
        if (attributeValueGroups.transferType == 'Managed Account Transfer') {
            emailBody = emailBody + '<tr><td style="padding: 6px;">Mode</td><td style="padding: 6px;"><b>'+attributeValueGroups.mode+'</b></td> </tr>';
            if (attributeValueGroups.mode == 'Transfer the following number of whole shares') {
                emailBody = emailBody + '<tr><td style="padding: 6px;">Quantity</td><td style="padding: 6px;"><b>'+attributeValueGroups.numberOfShares+'</b></td> </tr>';
            }
        }
        if (attributeValueGroups.transferType == 'Annuity Transfer' || attributeValueGroups.transferType == 'Bank or Credit Union Account Transfer') {
            emailBody = emailBody + '<tr><td style="padding: 6px;">Mode</td><td style="padding: 6px;"><b>'+attributeValueGroups.mode+'</b></td> </tr>';
            if (attributeValueGroups.mode == 'Full Annuity Surrender, dated') {
                emailBody = emailBody + '<tr><td style="padding: 6px;">Annuity Date</td><td style="padding: 6px;"><b>'+attributeValueGroups.maturityAnnuityDate+'</b></td> </tr>';
            }
            if (attributeValueGroups.mode == 'Partial Annuity Surrender') {
                emailBody = emailBody + '<tr><td style="padding: 6px;">Surrender Amount</td><td style="padding: 6px;"><b>'+attributeValueGroups.currencyCode +'&nbsp;'+attributeValueGroups.amount+'</b></td> </tr>';
            }
            if (attributeValueGroups.mode == 'Liquidate CD at maturity and send cash') {
                emailBody = emailBody + '<tr><td style="padding: 6px;">Maturity Date</td><td style="padding: 6px;"><b>'+attributeValueGroups.maturityAnnuityDate+'</b></td> </tr>';
            }
            if (attributeValueGroups.mode == 'Transfer partial cash amount') {
                emailBody = emailBody + '<tr><td style="padding: 6px;">Cash Amount</td><td style="padding: 6px;"><b>'+attributeValueGroups.currencyCode +'&nbsp;'+attributeValueGroups.amount+'</b></td> </tr>';
            }
        }
        if (attributeValueGroups.transferEntireAccount == 'Yes' && (attributeValueGroups.transferType == 'Brokerage or Trust Company Transfer' || attributeValueGroups.transferType == 'Mutual Fund Company Account Transfer')) {
            if (attributeValueGroups.transferType == 'Brokerage or Trust Company Transfer') {
                emailBody = emailBody + '<tr><td style="padding: 6px;">Cash Transfer</td><td style="padding: 6px;"><b>All</b></td> </tr>';
            }
            emailBody = emailBody + '<tr><td style="padding: 6px;">Security Transfer</td><td style="padding: 6px;"><b>All</b></td> </tr>';
        }
        if (attributeValueGroups.transferEntireAccount == 'No' && (attributeValueGroups.transferType == 'Brokerage or Trust Company Transfer' || attributeValueGroups.transferType == 'Mutual Fund Company Account Transfer')) {
            if (attributeValueGroups.transferType == 'Brokerage or Trust Company Transfer' && attributeValueGroups.cash == 'Yes') {
                if (attributeValueGroups.amountMode == 'All') {
                    emailBody = emailBody + '<tr><td style="padding: 6px;">Cash Transfer</td><td style="padding: 6px;"><b>All</b></td> </tr>';
                } else if (attributeValueGroups.amountMode == 'Custom') {
                    emailBody = emailBody + '<tr><td style="padding: 6px;">Cash Transfer</td><td style="padding: 6px;"><b>'+attributeValueGroups.currencyCode +'&nbsp;'+attributeValueGroups.amount+'</b></td> </tr>';    
                }
            }
            if (attributeValueGroups.transferType == 'Brokerage or Trust Company Transfer' && attributeValueGroups.security == 'Yes') {
                emailBody = emailBody + '<tr><td style="padding: 6px;">Security Transfer</td><td style="padding: 6px;"><b>Custom</b></td> </tr>';   
            }
            if (attributeValueGroups.transferType == 'Mutual Fund Company Account Transfer') {
                emailBody = emailBody + '<tr><td style="padding: 6px;">Transfer Funds</td><td style="padding: 6px;"><b>Custom</b></td> </tr>';
            }
            if ((attributeValueGroups.transferType == 'Brokerage or Trust Company Transfer' && attributeValueGroups.security == 'Yes') || attributeValueGroups.transferType == 'Mutual Fund Company Account Transfer') {
                //create table for custom Securities / Funds
                Map<String, String> securityDetailsObj = new Map<String, String>();
                List<Map<String, String>> securityDetails = new List<Map<String, String>>();
                Map<Integer, Map<String, String>> securityDetailsAttrVal;
                if (attributeValueGroups.transferType == 'Brokerage or Trust Company Transfer') {
                    securityDetailsAttrVal = getSecurityDetails(svcCatalogReqExtdAttrVals, 'Securities');
                } else if (attributeValueGroups.transferType == 'Mutual Fund Company Account Transfer') {
                    securityDetailsAttrVal = getSecurityDetails(svcCatalogReqExtdAttrVals , 'Funds');
                }
                for (Integer groupNumber: securityDetailsAttrVal.keyset()){            
                    securityDetailsObj = securityDetailsAttrVal.get(groupNumber); 
                    securityDetails.add(securityDetailsObj);
                }
                if (attributeValueGroups.transferType == 'Brokerage or Trust Company Transfer') {
                    String securitylabel = '<br>&nbsp;List of securities<br><br>';
                    securityBody = FSCWlthUtilityClass.constructEmailBody(securityDetails, securitylabel, false);
                } else if (attributeValueGroups.transferType == 'Mutual Fund Company Account Transfer') {
                    String securitylabel = '<br>&nbsp;List of funds<br><br>';
                    securityBody = FSCWlthUtilityClass.constructEmailBody(securityDetails, securitylabel, false);
                }
            }
        }
        emailBody = emailBody +'</table>'+securityBody;
        bodyList.add(emailBody);
        return bodyList;
    } 
    
    private static Map<Integer, Map<String,String>> getSecurityDetails(List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrVals, String type) {
        Map<Integer, Map<String, String>> securityGroupNumMap = new Map<Integer, Map<String, String>>();
        String securityName = null;
        String quantity = null;
        String quantityMode  = null;
        for (SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrVal : svcCatalogReqExtdAttrVals) {
            switch on svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName {
                when 'security_fund_name' {
                    securityName = svcCatalogReqExtdAttrVal.TextValue;  
                }  when 'number_of_units' {
                    quantity = String.valueOf(svcCatalogReqExtdAttrVal.NumberValue);
                } when 'quantity_mode' {
                    quantityMode = svcCatalogReqExtdAttrVal.TextValue;
                } 
            }           
            Integer groupNumber = svcCatalogReqExtdAttrVal.GroupNumber;
            if (groupNumber != null) {
                Map<String, String> securityMap = securityGroupNumMap.get(groupNumber);
                securityMap = new Map<String, String>();
                securityGroupNumMap.put(groupNumber, securityMap);
                if (type == 'Securities'){
                    securityMap.put('Security Identifier', securityName);
                    if (quantityMode == 'All') {
                      securityMap.put('Number of Shares', quantityMode);  
                    } else if (quantityMode == 'Custom') {
                      securityMap.put('Number of Shares', quantity);  
                    }
                } else if (type == 'Funds'){
                    securityMap.put('Fund Identifier', securityName);
                    if (quantityMode == 'All') {
                      securityMap.put('Number of Shares', quantityMode);  
                    } else if (quantityMode == 'Custom') {
                      securityMap.put('Number of Shares', quantity);  
                    }
                }
            }             
        }
        return securityGroupNumMap;
    }
    
    //getting all the automated account transfer details by looping through svcCatalogReqExtdAttrVals records
    private static AttributeValueGroup getAttributeValueGroup(List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrVals) {
        
        AttributeValueGroup attributeValueGroups = new AttributeValueGroup();           
        for (SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrVal : svcCatalogReqExtdAttrVals) {
            if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'transfer_type') {
                attributeValueGroups.transferType = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'amount') {
                attributeValueGroups.amount = string.valueOf(svcCatalogReqExtdAttrVal.NumberValue);
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'transfer_action') {
                attributeValueGroups.transferAction = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'transfer_entire_account') {
                attributeValueGroups.transferEntireAccount = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'mode') {
                attributeValueGroups.mode = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'amount_mode') {
                attributeValueGroups.amountMode = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'security') {
                attributeValueGroups.security = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'cash') {
                attributeValueGroups.cash = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'currency_code') {
                attributeValueGroups.currencyCode = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'number_of_shares') {
                attributeValueGroups.numberOfShares = string.valueOf(svcCatalogReqExtdAttrVal.NumberValue);
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'maturity_annuity_date') {
                attributeValueGroups.maturityAnnuityDate = svcCatalogReqExtdAttrVal.TextValue;
            }
        }
        return attributeValueGroups;
    }
}