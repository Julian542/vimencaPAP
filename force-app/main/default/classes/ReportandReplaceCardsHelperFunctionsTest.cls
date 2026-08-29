/*************************
* @Class Name:- ReportandReplaceCardsHelperFunctionsTest
* @Description:- Test class for ReportandReplaceCardsHelperFunctions
*                Which handles Case creation and service catalog request and 
*                extended attribute creation based on input parameter. 
**************************/
@IsTest
public with sharing class ReportandReplaceCardsHelperFunctionsTest {
    
    // Set input values
    @IsTest(SeeAllData=true) 
    static void testCaseCreation() {
        List<Object> cardList = new List<Object>();
        Map<String, Object>card = new Map<String, Object>();
        card.put('CardNumberLast4', '9012');
        card.put('CardName', 'TestCard');
        card.put('CardSourceSystemId', '1234retAST');
        card.put('CardType', 'Credit Card');
        card.put('Reissue', 'true');
        cardList.add(card);
        Map<String, Object> input = new Map<String, Object>();
        input.put('accountId', 'AccountId');
        input.put('accountSourceSystemId', '123testid');
        input.put('svcCatalogItemDefApiName', 'ReportandReplaceCard');
        input.put('caseSubject', 'Report and Replace Card Service Request');
        input.put('isCommunitySite', 'false');
        input.put('reason', 'Stolen');
        input.put('remarks', 'need card replacement');
        input.put('addressLine1', '1 street');
        input.put('addressLine2', '2nd stage,5th cross');
        input.put('city', 'sCity');
        input.put('state', 'cState');
        input.put('country', 'nCountry');
        input.put('postalCode', '567890');
        input.put('shippingPreference', 'Standard');
        input.put('finalListofSelectedCard', cardList);
        input.put('selectedCardData', cardList);
        input.put('replaceCard', 'Yes');
        Map<String, Object> output = new Map<String, Object>();
        
        Map<String, Object>args = new Map<String, Object>();
        args.put('input', input);
        args.put('output', output);
        
        Callable cll = (Callable)Type.forName('ReportandReplaceCardsHelperFunctions').newInstance();
        Object createCaseApiObj = cll.call('callCreateCaseApi', args);
        System.assertEquals('{apiResponse={}}', String.valueOf(createCaseApiObj));
    }
    
    //getUniqueAddress
    @IsTest 
    static void testgetUniqueAddress() {
        Map<String, Object> input = new Map<String, Object>();
        List<Object> mainList = new List<Object>();
        String address1='123,A zone, B City , C country, 34567';
        mainList.add(address1);
        input.put('MainList', mainList);
        Map<String, Object> output = new Map<String, Object>();
        
        Map<String, Object> args = new Map<String, Object>();
        args.put('input', input);
        args.put('output', output);
        Callable cll = (Callable)Type.forName('ReportandReplaceCardsHelperFunctions').newInstance();
        Object getUniqueAddress = cll.call('getUniqueAddress', args);
        System.assertEquals('{AddressList={123,A zone, B City , C country, 34567}}', String.valueOf(getUniqueAddress));
    }
}