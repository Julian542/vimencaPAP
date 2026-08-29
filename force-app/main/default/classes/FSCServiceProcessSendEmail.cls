/*************************
* @Class Name:- FSCServiceProcessSendEmail
* @Description:- This apex class contains an invocable method used to send email along with attachment
**************************/
global with sharing class FSCServiceProcessSendEmail { 
    // Method to send email along with attachment and reurns either Success or Failure back to flow output variable
    @InvocableMethod(label='Send Email to user on case creation' description='Sends email to user from apex ') 
    public static List<String> sendEmail(List<Requests> request) {
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        List<String> response =  new List<String>();
        List<String> sendTo = new List<String> {request[0].sendToEmailId};
        mail.setToAddresses(sendTo);
        mail.setSubject(request[0].emailSubject);
        mail.setHtmlBody(request[0].textTemplate);
        //Fetch attachment id associated to the caseId and append it to email as attachments
        List<Attachment> attList = new List<Attachment> ([SELECT Id, Name FROM Attachment WHERE parentId =: request[0].caseId WITH SECURITY_ENFORCED]);
        if (attList.size() > 0) {
            List<String> attachmentIds = new List<String> {attList[0].Id};
            mail.setEntityAttachments(attachmentIds);
        }
        // Add email to the master list
        mails.add(mail);
        //Send all emails in the master list
        Messaging.SendEmailResult[] results = Messaging.sendEmail(mails);
        if (results[0].success) {
            response.add('Success');
        } else {
            response.add('Failure');
        }
        return response;
    }
    
    //set of invocable variables which is used to set values from flow  
    global class Requests {
        @InvocableVariable(label='Text Template' description='Text template of email body')
        global String textTemplate;
        @InvocableVariable(label='Send To Email Id' description='Email id of recipient')
        global String sendToEmailId;
        @InvocableVariable(label='CaseId' description='Case Id associated with attachment')
        global String caseId; 
        @InvocableVariable(label='Email Subject' description='Email subject')
        global String emailSubject;   
    }
}