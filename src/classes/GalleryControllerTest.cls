@isTest
public class GalleryControllerTest {
	private class Mock implements HttpCalloutMock {
		public String body;

        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setBody(this.body);
            res.setStatusCode(200);
            return res;
        }

        public Mock(String body){
        	this.body = body;
        }
    }

    @testSetup static void testSetup() {
		//Test Program Creation
        FieloPLT__Program__c testProgram = new FieloPLT__Program__c();
        testProgram.Name = 'Test Program';
        testProgram.FieloPLT__OnlineTransactionProcessing__c = true;
        testProgram.FieloGRS__GRSMemberFieldset__c = '[{"grsFieldName":"employeeId","sfFieldName":"Id"},{"grsFieldName":"firstName","sfFieldName":"FieloPLT__Contact__r.FirstName"},{"grsFieldName":"lastName","sfFieldName":"FieloPLT__Contact__r.LastName"},{"grsFieldName":"email","sfFieldName":"FieloPLT__Email__c"},{"grsFieldName":"address1","sfFieldName":"FieloPLT__Contact__r.MailingStreet"},{"grsFieldName":"city","sfFieldName":"FieloPLT__Contact__r.MailingCity"},{"grsFieldName":"postalCode","sfFieldName":"FieloPLT__Contact__r.MailingPostalCode"},{"grsFieldName":"provinceState","sfFieldName":"FieloPLT__Contact__r.MailingStateCode"},{"grsFieldName":"country","sfFieldName":"FieloPLT__Contact__r.MailingCountryCode"},{"grsFieldName":"telephone","sfFieldName":"FieloPLT__Contact__r.Phone"},{"grsFieldName":"language","sfFieldName":"FieloPLT__User__r.LanguageLocaleKey","isLocale":true}]';
        testProgram.FieloGRS__GRSMetadataFieldset__c = '[{"id":"tier", "name":"tier", "fieldName":"FieloPLT__CurrentLevelMember__r.FieloPLT__Level__r.Name"},{"id":"account_type", "name":"account_type", "dataValue":"test"}]';
        insert testProgram;

        FieloPLT__Level__c level = new FieloPLT__Level__c();
        level.FieloPLT__Program__c = testProgram.Id;
        level.name = 'Gold';
        insert level;

        //Program Point Type and Point Type Id
        FieloPLT__ProgramPointType__c ppt = [SELECT Id, FieloPLT__PointType__c, FieloPLT__RequestPointApproval__c FROM FieloPLT__ProgramPointType__c WHERE FieloPLT__Program__c =: testProgram.Id limit 1];
        ppt.FieloPLT__RequestPointApproval__c = true;
        update ppt;
        Id pointTypeId = ppt.FieloPLT__PointType__c;
        
        testProgram.FieloGRS__GRSPointType__c = pointTypeId;
        update testProgram;

        //Test Member Creation
        FieloPLT__Member__c testMember = new FieloPLT__Member__c();
        testMember.Name = 'Test Member';
        testMember.FieloPLT__Email__c = testMember.Name.deleteWhitespace() + '@fielo.com';
        testMember.FieloPLT__Program__c = testProgram.id;
        testMember.FieloPLT__User__c = UserInfo.getUserId();
        insert testMember;

        FieloPLT__LevelMember__c memberLevel = new FieloPLT__LevelMember__c();
        memberLevel.FieloPLT__Level__c = level.Id;
        memberLevel.FieloPLT__Member__c = testMember.Id;
        insert memberLevel;

        update new FieloPLT__Member__c(Id = testMember.Id,FieloPLT__CurrentLevelMember__c = memberLevel.Id);
	}

	public static testMethod void testLogin(){
		Id memberId = [SELECT Id FROM FieloPLT__Member__c LIMIT 1].Id;

		Test.setMock(HttpCalloutMock.class, new Mock('{"id":"GJQW0357","employeeId":"' + memberId + '","firstName":"Rest","lastName":"Test Member","email":"tiago.leal@fielo.com","address1":"123","address2":null,"city":"33","postalCode":null,"provinceState":"CA","country":"US","telephone":"","language":"en","hireDate":null,"balance":15725,"creditBalances":{},"lifetimePointsAwarded":19498,"lifetimePointsRedeemed":3773,"credentials":{"0":"Rewards Program","1":"Dream Tracker","2":"Shopping Cart","3":"My Orders"},"accessGroups":{"0":"defaultStorefrontExternalMember"},"locale":"en_US","hierarchyNodeCode":"ROOT","hierarchyRoles":{},"metadata":{},"totalUnderAdministration":0,"created":"2017-10-13 08:19:51","deleted":null,"statusCode":"OK","error":null}'));

        try{
        	UserService.enableAdminPermission(true);
            update new User(Id = UserInfo.getUserId(), FieloGRS__MemberId__c = memberId, Country='United States');
            UserService.enableAdminPermission(false);    
        } catch(Exception e) {
            System.debug(e);
        }
		

		Test.startTest();
        Boolean result = false;
        try{
			result = GalleryController.login();   
        } catch (Exception e) {
            result = false;
        }
		System.debug(result);
		System.assertEquals(result,true);
		Test.stopTest();
	}

	public static testMethod void testLoginError(){
		Id memberId = [SELECT Id FROM FieloPLT__Member__c LIMIT 1].Id;
		
		Test.setMock(HttpCalloutMock.class, new Mock('{"id":"GJQW0357","employeeId":"' + memberId + '","firstName":"Rest","lastName":"Test Member","email":"tiago.leal@fielo.com","address1":"123","address2":null,"city":"33","postalCode":null,"provinceState":"CA","country":"US","telephone":"","language":"en","hireDate":null,"balance":15725,"creditBalances":{},"lifetimePointsAwarded":19498,"lifetimePointsRedeemed":3773,"credentials":{"0":"Rewards Program","1":"Dream Tracker","2":"Shopping Cart","3":"My Orders"},"accessGroups":{"0":"defaultStorefrontExternalMember"},"locale":"en_US","hierarchyNodeCode":"ROOT","hierarchyRoles":{},"metadata":{},"totalUnderAdministration":0,"created":"2017-10-13 08:19:51","deleted":null,"statusCode":"OK","error":null}'));
		
		Test.startTest();
		Boolean result = false;
        try{
			result = GalleryController.login();   
        } catch (Exception e) {
            result = false;
        }
		System.debug(result);
		System.assertEquals(result,false);
		Test.stopTest();
	}

	public static testMethod void testSetCurrentMember() {
		Test.startTest();
        try{
        	FieloPLT__Member__c member = GalleryController.setCurrentMember((FieloPLT__Member__c)[SELECT Id, Name FROM FieloPLT__Member__c LIMIT 1]);    
        } catch(Exception e) {
            System.debug(e);
        }
		
		Test.stopTest();
	}
}