/*************************
* @Class Name:- FSCServiceProcessSendEmailTest
* @Description:- Test class for FSCServiceProcessSendEmail which contains an invocable method to send email along with attachment 
**************************/
@IsTest
public class FSCServiceProcessSendEmailTest {
    @IsTest
    public static void InvocableMethodSuccess() {
        //Create accounts from FSCRetailTestDataFactory
        List<Account> accList = new List<Account>();
        accList = FSCRetailTestDataFactory.createAccounts(1);
        //Create case from FSCRetailTestDataFactory
        List<Case> caseList = new List<Case>();
        caseList = FSCRetailTestDataFactory.createCase(1, accList);
        //Create attachment and associate to the case
        Attachment att = new Attachment();
        att.name = 'AttachmentTest';
        att.ParentId = caseList[0].Id;
        att.Body =  Blob.toPDF('<Html><p>test Email body </p></html>');
        insert att;
        //Set Invocable variable value
        final String textTemplate ='<Html><p>test Email body </p></html>';
        final String sendToEmailId = 'test@gmail.com';
        final String caseId = caseList[0].Id;
        final String emailSubject = 'Test Email Subject';
        FSCServiceProcessSendEmail.Requests request = new FSCServiceProcessSendEmail.Requests();
        request.textTemplate = textTemplate;
        request.sendToEmailId = sendToEmailId;
        request.caseId = caseId;
        request.emailSubject = emailSubject;
        test.startTest();
        List<String> resultList = new List<String>();
        resultList = FSCServiceProcessSendEmail.sendEmail(new List<FSCServiceProcessSendEmail.Requests> {request});
        System.assertEquals('Success', resultList[0]);
        test.stopTest(); 
    }
}