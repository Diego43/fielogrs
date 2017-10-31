global class LoginService {
    private static String adjustmentMemo = 'Balance credit adjustment to match source';

	global static String login(Id memberId) {
		System.debug('LoginService : login');

		String query = 'SELECT Id, ' +
            'FieloPLT__Program__r.GRSAccount__c, ' +
            'FieloPLT__Program__r.GRSPointType__r.FieloPLT__RedemptionItemBalanceField__c, ' +
            'FieloPLT__Program__r.GRSPointType__r.FieloPLT__MemberBalanceField__c, ' +
            'FieloPLT__Program__r.GRSMemberFieldset__c, ' +
            'FieloPLT__Type__c ' +
            'FROM FieloPLT__Member__c WHERE Id =: memberId LIMIT 1';

        FieloPLT__Member__c member;
        Id userId = UserInfo.getUserId();

        try{
            member = (FieloPLT__Member__c) Database.query(query);
        } catch (Exception e) {
            throw new FieloPLT.FieloException (Label.MemberNotFound.replace('{0}',memberId));
        }

        if ( member != null ) {
            query = 'SELECT RecordId, HasEditAccess FROM UserRecordAccess WHERE UserId = :userId AND RecordId = :memberId';

            UserRecordAccess access = (UserRecordAccess) Database.query(query);

            if (member.FieloPLT__Type__c == 'Organization Contributor') {
                throw new FieloPLT.FieloException (Label.UserCannotAccessMember.replace('{0}',userId).replace('{1}',memberId));
            } else if (member.FieloPLT__Type__c == 'Individual Account' || member.FieloPLT__Type__c == 'Organization Account') {
                if (!access.HasEditAccess) {
                    throw new FieloPLT.FieloException (Label.UserCannotAccessMember.replace('{0}',userId).replace('{1}',memberId));
                }
            }

            String pointBalanceField = member.FieloPLT__Program__r.GRSPointType__r.FieloPLT__MemberBalanceField__c;
            Set<String> fieldsetToQuery = new Set<String>{pointBalanceField};

            List<FieldWrapper> memberFieldset;
            if(String.isNotBlank(member.FieloPLT__Program__r.GRSMemberFieldset__c)){
                //parse de json con fieldset casteado a wrapper interno
                memberFieldset = (List<FieldWrapper>)JSON.deserialize(member.FieloPLT__Program__r.GRSMemberFieldset__c, List<FieldWrapper>.class);
                
                for(FieldWrapper mf : memberFieldset){
                    fieldsetToQuery.add(mf.sfFieldName);
                }
            }

            String memberRetrieveQuery = 'SELECT ' + String.join(new List<String>(fieldsetToQuery),',') + ' FROM FieloPLT__Member__c WHERE Id =: memberId LIMIT 1';

            member = Database.query(memberRetrieveQuery);
            
            Settings__c grsSettings = Settings__c.getInstance(UserInfo.getProfileId());
            
            String domain = grsSettings.Domain__c;
            String apiKey = grsSettings.ApiKey__c;
            String adminId = grsSettings.AdminId__c;

            StorefrontService sfs = new StorefrontService(domain);
            sfs.setUserAuth(member.Id, apiKey);
            sfs.setAdminAuth(adminId, apiKey);

            Map<String,Object> grsMember = sfs.getMember();

            Boolean createMember = grsMember == null ?
                true :
                grsMember.containsKey('id') ?
                    ( grsMember.get('id') != null ? false : true ) :
                    true;

            Map<String,Object> memberData = new Map<String,Object>();

            memberData.put('pointBalance', member.get(pointBalanceField));
            // Locale special treatment
            List<String> language_parts;
            Boolean isLocale;

            for(FieldWrapper mf : memberFieldset){
                // Locale special treatment
                isLocale = mf.isLocale != null ? mf.isLocale : false;

                // cargo los campos en el mapa
                // +Locale special treatment
                if (isLocale) {
                    language_parts = ((String)getFieldValue(member, mf.sfFieldName)).split('_', 2);
                    memberData.put(mf.grsFieldName, language_parts[0]);
                } else {
                    memberData.put(mf.grsFieldName, getFieldValue(member, mf.sfFieldName));
                }
            }

            //do we need to create or update the member?
            if (createMember) {
                memberData.put('accessGroups', (Object)new List<String>{'defaultStorefrontExternalMember'});
                memberData.put('hierarchyNodeCode', 'ROOT');
                grsMember = sfs.createMember(memberData);
            } else {
                memberData.put('id', grsMember.get('id'));
                grsMember = sfs.updateMember(memberData);
            }
            
            System.debug('Member Initiated');
            System.debug(JSON.serializePretty(grsMember));

            System.debug('Creating Session');

            if (grsMember != null) {
                return 'success';
            }
            return 'fail';
        } else {
            return 'fail';
        }
    }

    private static Object getFieldValue(FieloPLT__Member__c member, String sfFieldName){
        //split para campos a segundo o tercer nivel
        String[] fieldNameSplited = sfFieldName.split('\\.');
        SObject relationObject = member;
        Integer index = 0;
        for(; index < fieldNameSplited.size() - 1; index++){
            relationObject = relationObject.getSObject(fieldNameSplited[index].removeEnd('Id'));
            if(relationObject == null)
                return null;
        }

        return relationObject.get(fieldNameSplited[index]);
    }
}