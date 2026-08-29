/*************************
* @Class Name:- FSCWlthRequiredMinDistributionFlowHelper
* @Description:- FSC Wealth Required Minimum Distribution process case creation email flow helper class
**************************/
public with sharing class FSCWlthRequiredMinDistributionFlowHelper {
    
    public class FlowInputs{
        @InvocableVariable(label='Service Catalog Request Id' required=true)
        public String inputRecordId;
    }
    
    class AttributeValueGroup { 
        String paymentSchedule;
        String automatedRMDOption;
        String automatedRMDDate;
        String taxYear;
        String amountOption;
        String currencyCode;
        String amount; 
        String paymentOption;
        String accountNumber;
        String accountType;
        String routingNumber;
        String accountOwner;
        String bankAddress;
        String bankName;
        String bankZipcode;
        String bankCity;
        String bankState;
        String bankCountry;
        String payeeName;
        String taxWithholdOption;
        String state;
        String federal;
        String ownersState;
    }
    
    //Invocable method used in the flow to get the securities list
    @InvocableMethod(label='Get Required Minimum Distribution Details' description='Process all extended attribute records')
    public static List<String> getPaymentDetails(List<FlowInputs> flowInput) {
        String svcRecordId = flowInput[0].inputRecordId;
        List<String> bodyList = new List<String>();
        String emailBody;
        //Fetch all SvcCatalogReqExtdAttrVal
        List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrVals = [SELECT Id, SvcCtlgItemAttrDeveloperName, GroupNumber, TextValue, NumberValue FROM SvcCatalogReqExtdAttrVal WHERE SvcCatalogRequestId = :svcRecordId WITH SECURITY_ENFORCED ORDER BY GroupNumber ASC NULLS FIRST];
        AttributeValueGroup attributeValueGroups = getAttributeValueGroup(svcCatalogReqExtdAttrVals);
        // Email body for Payment Schedule section
        emailBody = '<table style="width: 100%;border-collapse: collapse;" cellspacing="0"><tr><td style="font-weight: bold;padding:6px;background-color: #F3F3F3;" colspan="2">Payment Schedule Details</td></tr>'+
            '<tr><td style="padding: 6px;width: 30%">Payment Schedule</td><td style="padding: 6px;"><b>'+attributeValueGroups.paymentSchedule+'</b></td> </tr>';
        if (attributeValueGroups.paymentSchedule == 'Automated RMD') {
            emailBody = emailBody + '<tr><td style="padding: 6px;">Payment Frequency</td><td style="padding: 6px;"><b>'+attributeValueGroups.automatedRMDOption+'</b></td> </tr>';
            emailBody = emailBody + '<tr><td style="padding: 6px;">Start Date</td><td style="padding: 6px;"><b>'+attributeValueGroups.automatedRMDDate+'</b></td> </tr>';
        } else {
            emailBody = emailBody + '<tr><td style="padding: 6px;">Tax Year</td><td style="padding: 6px;"><b>'+attributeValueGroups.taxYear+'</b></td> </tr>';
            if (attributeValueGroups.amountOption == 'Enter withdrawal amount') {
                emailBody = emailBody + '<tr><td style="padding: 6px;">RMD Amount</td><td style="padding: 6px;"><b>'+attributeValueGroups.currencyCode +'&nbsp;'+attributeValueGroups.amount+'</b></td> </tr>';  
            } else {
                emailBody = emailBody + '<tr><td style="padding: 6px;">RMD Amount</td><td style="padding: 6px;"><b>'+attributeValueGroups.amountOption +'</b></td> </tr>'; 
            }
        }
        emailBody = emailBody +'</table><br/>';
        // Email body for Payment Option section
        emailBody = emailBody + '<table style="width: 100%;border-collapse: collapse;" cellspacing="0"><tr><td style="font-weight: bold;padding:6px;background-color: #F3F3F3;" colspan="2">Payment Method Details</td></tr>'+
            '<tr><td style="padding: 6px;width: 30%">Selected Option</td><td style="padding: 6px;"><b>'+attributeValueGroups.paymentOption+'</b></td> </tr>';
        if (attributeValueGroups.paymentOption == 'New EFT Account' || attributeValueGroups.paymentOption == 'Existing EFT Account') {
            emailBody = emailBody + '<tr><td style="padding: 6px;">Account Number</td><td style="padding: 6px;"><b>'+attributeValueGroups.accountNumber+'</b></td> </tr>';
            emailBody = emailBody + '<tr><td style="padding: 6px;">Routing Number</td><td style="padding: 6px;"><b>'+attributeValueGroups.routingNumber+'</b></td> </tr>';
            emailBody = emailBody + '<tr><td style="padding: 6px;">Payee Name</td><td style="padding: 6px;"><b>'+attributeValueGroups.accountOwner+'</b></td> </tr>';
            if (attributeValueGroups.paymentOption == 'New EFT Account') {
                emailBody = emailBody + '<tr><td style="padding: 6px;">Account Type</td><td style="padding: 6px;"><b>'+attributeValueGroups.accountType+'</b></td> </tr>';
            }else {
                emailBody = emailBody + '<tr><td style="padding: 6px;">Ownership Type</td><td style="padding: 6px;"><b>'+attributeValueGroups.accountType+'</b></td> </tr>';
            }
        }
        if (attributeValueGroups.paymentOption == 'New EFT Account' || attributeValueGroups.paymentOption == 'Check') {
            if (attributeValueGroups.paymentOption == 'Check') {
                emailBody = emailBody + '<tr><td style="padding: 6px;">Payee Name</td><td style="padding: 6px;"><b>'+attributeValueGroups.payeeName+'</b></td> </tr>';
            }
            emailBody = emailBody + '<tr><td style="padding: 6px;">Bank Name</td><td style="padding: 6px;"><b>'+attributeValueGroups.bankName+'</b></td> </tr>';
            String finalbankAddress = attributeValueGroups.bankAddress;
            if (attributeValueGroups.bankCity != null) {
                finalbankAddress = finalbankAddress + ', '+attributeValueGroups.bankCity;
            }
            if (attributeValueGroups.bankState != null) {
                finalbankAddress = finalbankAddress + ', '+attributeValueGroups.bankState;
            }
            if (attributeValueGroups.bankCountry != null) {
                finalbankAddress = finalbankAddress + ', '+attributeValueGroups.bankCountry;
            }
            if (attributeValueGroups.bankZipcode != null) {
                finalbankAddress = finalbankAddress + ', '+attributeValueGroups.bankZipcode;
            }
            emailBody = emailBody + '<tr><td style="padding: 6px;">Bank Address</td><td style="padding: 6px;"><b>'+ finalbankAddress +'</b></td> </tr>';
        }
        emailBody = emailBody +'</table><br/>';
        // Email body for Tax withholding section
        emailBody = emailBody + '<table style="width: 100%;border-collapse: collapse;" cellspacing="0"><tr><td style="font-weight: bold;padding:6px;background-color: #F3F3F3;" colspan="2">Tax Withholding Details</td></tr>'+
            '<tr><td style="padding: 6px;width: 30%">Selected Withholding Option</td><td style="padding: 6px;"><b>'+attributeValueGroups.taxWithholdOption+'</b></td> </tr>';
        if (attributeValueGroups.taxWithholdOption == 'Elect to have federal and state') {
            emailBody = emailBody + '<tr><td style="padding: 6px;">Federal Share </td><td style="padding: 6px;"><b>'+attributeValueGroups.federal+'%</b></td> </tr>';
            emailBody = emailBody + '<tr><td style="padding: 6px;">State Share</td><td style="padding: 6px;"><b>'+attributeValueGroups.state+'%</b></td> </tr>';
            emailBody = emailBody + '<tr><td style="padding: 6px;">State of Residence</td><td style="padding: 6px;"><b>'+attributeValueGroups.ownersState+'</b></td> </tr>';
        }
        emailBody = emailBody +'</table>';
        bodyList.add(emailBody);
        return bodyList;
    } 
    
    
    //getting all the automated account transfer details by looping through svcCatalogReqExtdAttrVals records
    private static AttributeValueGroup getAttributeValueGroup(List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrVals) {
        
        AttributeValueGroup attributeValueGroups = new AttributeValueGroup();           
        for (SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrVal : svcCatalogReqExtdAttrVals) {
            if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'payment_schedule') {
                attributeValueGroups.paymentSchedule = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'automated_rmd_option') {
                attributeValueGroups.automatedRMDOption = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'automated_rmd_date') {
                attributeValueGroups.automatedRMDDate = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'tax_year') {
                attributeValueGroups.taxYear = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'amount_option') {
                attributeValueGroups.amountOption = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'currency_code') {
                attributeValueGroups.currencyCode = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'amount') {
                attributeValueGroups.amount = string.valueOf(svcCatalogReqExtdAttrVal.NumberValue);
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'payment_option') {
                attributeValueGroups.paymentOption = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'bank_account_number') {
                attributeValueGroups.accountNumber = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'bank_routing_number') {
                attributeValueGroups.routingNumber = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'bank_account_holder_name') {
                attributeValueGroups.accountOwner = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'bank_account_type') {
                attributeValueGroups.accountType = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'payee_name') {
                attributeValueGroups.payeeName = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'bank_name') {
                attributeValueGroups.bankName = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'bank_address') {
                attributeValueGroups.bankAddress = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'bank_zipcode') {
                attributeValueGroups.bankZipcode = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'bank_city') {
                attributeValueGroups.bankCity = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'bank_state') {
                attributeValueGroups.bankState = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'bank_country') {
                attributeValueGroups.bankCountry = svcCatalogReqExtdAttrVal.TextValue;
            }else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'tax_withholding_option') {
                attributeValueGroups.taxWithholdOption = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'owners_state_of_residence') {
                attributeValueGroups.ownersState = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'state_percentage') {
                attributeValueGroups.state = string.valueOf(svcCatalogReqExtdAttrVal.NumberValue);
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'federal_percentage') {
                attributeValueGroups.federal = string.valueOf(svcCatalogReqExtdAttrVal.NumberValue);
            } 
        }
        return attributeValueGroups;
    }
}