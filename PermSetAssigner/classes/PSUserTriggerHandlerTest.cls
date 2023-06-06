/**
 * @description       : 
 * @author            : VISEO / FFI
 * @last modified on  : 06-06-2023
 * @last modified by  : VISEO / FFI
**/
@isTest
private class PSUserTriggerHandlerTest {

    private static List<PermissionSet> getPermSets(integer maxitems) {
        return [
            SELECT Id, Name
            FROM PermissionSet
            WHERE LicenseId = null AND PermissionSet.ProfileId = null
            lIMIT :maxitems
        ];
    }

    private static List<Profile> getProfiles(integer maxitems) {
        return [
            SELECT Id, Name
            FROM Profile
            WHERE userLicense.Name = 'Salesforce'
            LIMIT :maxitems
        ];
    }

    private static User makeUser(integer i) {
        return new User (
            LastName = 'test' + i,
            Username = 'testuser@ffiprofilemgr.testclass.user' + 'i',
            Email = 'test@test.com',
            Alias = 'test' + i, 
            TimeZoneSidKey = 'Europe/Paris',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'fr_FR_EURO'
        );
    }

    private static void setAssignments(Map<String, Set<String>> assignments) {
        List<PermSetProfileAssignment__c> psa = new List<PermSetProfileAssignment__c>();
        for(String profName : assignments.keySet()) {
            List<String> lstPermSets = new List<String>();
            lstPermSets.addAll(assignments.get(profName));
            String strPermSets = lstPermSets.size() > 0 ? lstPermSets.remove(0) : '';
            while (lstPermSets.size() > 0) {
                strPermSets = lstPermSets.remove(0) + ',' + strPermSets;
            }
            psa.add(new PermSetProfileAssignment__c(
                Profile__c = profName,
                PermissionSets__c = strPermSets
            ));
        }
        if(psa.size() > 0) { 
            User usr = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
            System.runAs(usr) {
                insert psa; 
            }
        }
    }


    @isTest
    private static void testUserCreation() {
        List<PermissionSet> permSets = getPermSets(2);
        List<Profile> profiles = getProfiles(2);
        Map<String, Set<String>> assignments = new Map<String, Set<String>>();

        for(Integer i = 0; i < 2; i++){
            assignments.put(profiles[i].Name, new Set<String>{ permSets[i].Name });
        }
        setAssignments(assignments);

        User usr1 = makeUser(1);
        usr1.ProfileId = profiles[1].Id;
        usr1.IsActive = true;

        PSUserTriggerHandler.setBypass(false);
        Test.startTest();
        insert usr1;
        Test.stopTest();

        List<PermissionSetAssignment> permSetAssignments =  [
            SELECT Id, PermissionSetId, AssigneeId, PermissionSet.Name
            FROM PermissionSetAssignment
        WHERE AssigneeId = :usr1.Id AND PermissionSet.ProfileId = null
        ];

        System.assertEquals(1, permSetAssignments.size(), 'There should be 1 assignment for User1');
        System.assertEquals(permSets[1].Id, permSetAssignments[0].PermissionSetId, 'User was assigned the wrong permission set : ' + permSetAssignments[0].PermissionSet.Name);
        
    }


    @isTest
    private static void testUserCreationNoChangeIfNotActive() {
        List<PermissionSet> permSets = getPermSets(2);
        List<Profile> profiles = getProfiles(2);
        Map<String, Set<String>> assignments = new Map<String, Set<String>>();

        for(Integer i = 0; i < 2; i++){
            assignments.put(profiles[i].Name, new Set<String>{ permSets[i].Name });
        }
        setAssignments(assignments);

        User usr1 = makeUser(1);
        usr1.ProfileId = profiles[1].Id;
        usr1.IsActive = false;

        PSUserTriggerHandler.setBypass(false);
        Test.startTest();
        insert usr1;
        Test.stopTest();

        List<PermissionSetAssignment> permSetAssignments =  [
            SELECT Id, PermissionSetId, AssigneeId, PermissionSet.Name
            FROM PermissionSetAssignment
        WHERE AssigneeId = :usr1.Id AND PermissionSet.ProfileId = null
        ];

        System.assertEquals(0, permSetAssignments.size(), 'There should be no assignment for User1');
        // System.assertEquals(permSets[1].Id, permSetAssignments[0].PermissionSetId, 'User was assigned the wrong permission set : ' + permSetAssignments[0].PermissionSet.Name);
        
    }

    @isTest
    private static void testUserCreationNoConfiguration() {
        List<PermissionSet> permSets = getPermSets(2);
        List<Profile> profiles = getProfiles(2);
        Map<String, Set<String>> assignments = new Map<String, Set<String>>();

        setAssignments(assignments);

        User usr1 = makeUser(1);
        usr1.ProfileId = profiles[1].Id;
        usr1.IsActive = true;

        PSUserTriggerHandler.setBypass(false);
        Test.startTest();
        insert usr1;
        Test.stopTest();

        List<PermissionSetAssignment> permSetAssignments =  [
            SELECT Id, PermissionSetId, AssigneeId, PermissionSet.Name
            FROM PermissionSetAssignment
        WHERE AssigneeId = :usr1.Id AND PermissionSet.ProfileId = null
        ];

        System.assertEquals(0, permSetAssignments.size(), 'There should be no assignment for User1');
    }

    @isTest
    private static void testUserUpdate() {
        List<PermissionSet> permSets = getPermSets(2);
        List<Profile> profiles = getProfiles(2);
        Map<String, Set<String>> assignments = new Map<String, Set<String>>();

        for(Integer i = 0; i < 2; i++){
            assignments.put(profiles[i].Name, new Set<String>{ permSets[i].Name });
        }
        setAssignments(assignments);
        PSUserTriggerHandler.setBypass(true);

        User usr1 = makeUser(1);
        usr1.ProfileId = profiles[0].Id;
        usr1.IsActive = true;
        insert usr1;

        insert new PermissionSetAssignment(
            AssigneeId = usr1.Id,
            PermissionSetId = permSets[0].Id
        );

        PSUserTriggerHandler.setBypass(false);
        Test.startTest();
        update new User(
            Id = usr1.Id,
            ProfileId = profiles[1].Id
        );
        Test.stopTest();

        List<PermissionSetAssignment> permSetAssignments =  [
            SELECT Id, PermissionSetId, AssigneeId, PermissionSet.Name
            FROM PermissionSetAssignment
        WHERE AssigneeId = :usr1.Id AND PermissionSet.ProfileId = null
        ];

        System.assertEquals(1, permSetAssignments.size(), 'There should be 1 assignment for User1');
        System.assertEquals(permSets[1].Id, permSetAssignments[0].PermissionSetId, 'User was assigned the wrong permission set : ' + permSetAssignments[0].PermissionSet.Name);
    }


    @isTest
    private static void testUserUpdateToIsActive() {
        List<PermissionSet> permSets = getPermSets(2);
        List<Profile> profiles = getProfiles(2);
        Map<String, Set<String>> assignments = new Map<String, Set<String>>();

        for(Integer i = 0; i < 2; i++){
            assignments.put(profiles[i].Name, new Set<String>{ permSets[i].Name });
        }
        setAssignments(assignments);
        PSUserTriggerHandler.setBypass(true);

        User usr1 = makeUser(1);
        usr1.ProfileId = profiles[1].Id;
        usr1.IsActive = false;
        insert usr1;


        PSUserTriggerHandler.setBypass(false);
        Test.startTest();
        update new User(
            Id = usr1.Id,
            isActive = true
        );
        Test.stopTest();

        List<PermissionSetAssignment> permSetAssignments =  [
            SELECT Id, PermissionSetId, AssigneeId, PermissionSet.Name
            FROM PermissionSetAssignment
        WHERE AssigneeId = :usr1.Id AND PermissionSet.ProfileId = null
        ];

        System.assertEquals(1, permSetAssignments.size(), 'There should be 1 assignment for User1');
        System.assertEquals(permSets[1].Id, permSetAssignments[0].PermissionSetId, 'User was assigned the wrong permission set : ' + permSetAssignments[0].PermissionSet.Name);
    }
    
    @isTest
    private static void testUserUpdateToInactive() {
        List<PermissionSet> permSets = getPermSets(2);
        List<Profile> profiles = getProfiles(2);
        Map<String, Set<String>> assignments = new Map<String, Set<String>>();

        for(Integer i = 0; i < 2; i++){
            assignments.put(profiles[i].Name, new Set<String>{ permSets[i].Name });
        }
        setAssignments(assignments);
        PSUserTriggerHandler.setBypass(true);

        User usr1 = makeUser(1);
        usr1.ProfileId = profiles[1].Id;
        usr1.IsActive = true;
        insert usr1;

        insert new PermissionSetAssignment(
            AssigneeId = usr1.Id,
            PermissionSetId = permSets[1].Id
        );
        insert new PermissionSetAssignment(
            AssigneeId = usr1.Id,
            PermissionSetId = permSets[0].Id
        );


        PSUserTriggerHandler.setBypass(false);
        Test.startTest();
        update new User(
            Id = usr1.Id,
            isActive = false
        );
        Test.stopTest();

        List<PermissionSetAssignment> permSetAssignments =  [
            SELECT Id, PermissionSetId, AssigneeId, PermissionSet.Name
            FROM PermissionSetAssignment
        WHERE AssigneeId = :usr1.Id AND PermissionSet.ProfileId = null
        ];

        System.assertEquals(1, permSetAssignments.size(), 'There should be only 1  assignment left for User 1');
        System.assertEquals(permSets[0].Id, permSetAssignments[0].PermissionSetId, 'The remaining permission set is the one that should have been removed : ' + permSetAssignments[0].PermissionSet.Name);
    }

    @isTest
    private static void testUserUpdateUserAlreadyHasProfile() {

        List<PermissionSet> permSets = getPermSets(2);
        List<Profile> profiles = getProfiles(2);
        Map<String, Set<String>> assignments = new Map<String, Set<String>>();

        for(Integer i = 0; i < 2; i++){
            assignments.put(profiles[i].Name, new Set<String>{ permSets[i].Name });
        }
        setAssignments(assignments);
        PSUserTriggerHandler.setBypass(true);

        User usr1 = makeUser(1);
        usr1.ProfileId = profiles[0].Id;
        usr1.IsActive = true;
        insert usr1;

        insert new PermissionSetAssignment(
            AssigneeId = usr1.Id,
            PermissionSetId = permSets[1].Id
        );

        PSUserTriggerHandler.setBypass(false);
        Test.startTest();
        update new User(
            Id = usr1.Id,
            ProfileId = profiles[1].Id
        );
        Test.stopTest();

        List<PermissionSetAssignment> permSetAssignments =  [
            SELECT Id, PermissionSetId, AssigneeId, PermissionSet.Name
            FROM PermissionSetAssignment
        WHERE AssigneeId = :usr1.Id AND PermissionSet.ProfileId = null
        ];

        System.assertEquals(1, permSetAssignments.size(), 'There should be 1 assignment for User1');
        System.assertEquals(permSets[1].Id, permSetAssignments[0].PermissionSetId, 'User was assigned the wrong permission set : ' + permSetAssignments[0].PermissionSet.Name);
    }

    @isTest
    private static void testUserUpdateOldProfileNotDefined() {
        // User already have profile
        List<PermissionSet> permSets = getPermSets(2);
        List<Profile> profiles = getProfiles(2);
        Map<String, Set<String>> assignments = new Map<String, Set<String>>();

        assignments.put(profiles[1].Name, new Set<String>{ permSets[1].Name });

        setAssignments(assignments);
        PSUserTriggerHandler.setBypass(true);

        User usr1 = makeUser(1);
        usr1.ProfileId = profiles[0].Id;
        usr1.IsActive = true;
        insert usr1;

        insert new PermissionSetAssignment(
            AssigneeId = usr1.Id,
            PermissionSetId = permSets[0].Id
        );

        PSUserTriggerHandler.setBypass(false);


        Test.startTest();
        update new User(
            Id = usr1.Id,
            ProfileId = profiles[1].Id
        );
        Test.stopTest();

        List<PermissionSetAssignment> permSetAssignments =  [
            SELECT Id, PermissionSetId, AssigneeId, PermissionSet.Name
            FROM PermissionSetAssignment
        WHERE AssigneeId = :usr1.Id AND PermissionSet.ProfileId = null
        ];
        System.assertEquals(2, permSetAssignments.size(), 'Original assignment is not erased');
    }


    @isTest
    private static void testUserUpdateOldProfileNotDefinedAndNoProfile() {
        // User already have profile
        List<PermissionSet> permSets = getPermSets(2);
        List<Profile> profiles = getProfiles(2);
        Map<String, Set<String>> assignments = new Map<String, Set<String>>();

        assignments.put(profiles[1].Name, new Set<String>{ permSets[1].Name });

        setAssignments(assignments);
        PSUserTriggerHandler.setBypass(true);

        User usr1 = makeUser(1);
        usr1.ProfileId = profiles[0].Id;
        usr1.IsActive = true;
        insert usr1;

        // insert new PermissionSetAssignment(
        //     AssigneeId = usr1.Id,
        //     PermissionSetId = permSets[0].Id
        // );

        PSUserTriggerHandler.setBypass(false);


        Test.startTest();
        update new User(
            Id = usr1.Id,
            ProfileId = profiles[1].Id
        );
        Test.stopTest();

        List<PermissionSetAssignment> permSetAssignments =  [
            SELECT Id, PermissionSetId, AssigneeId, PermissionSet.Name
            FROM PermissionSetAssignment
        WHERE AssigneeId = :usr1.Id AND PermissionSet.ProfileId = null
        ];
        System.assertEquals(1, permSetAssignments.size(), 'Perm set not assigned');
        System.assertEquals(permSets[1].Id, permSetAssignments[0].PermissionSetId, 'User was assigned the wrong permission set : ' + permSetAssignments[0].PermissionSet.Name);
    }

    @isTest
    private static void testUserUpdateNewProfileNotDefined() {
        // User already have profile
        List<PermissionSet> permSets = getPermSets(2);
        List<Profile> profiles = getProfiles(2);
        Map<String, Set<String>> assignments = new Map<String, Set<String>>();

        assignments.put(profiles[0].Name, new Set<String>{ permSets[0].Name });

        setAssignments(assignments);
        PSUserTriggerHandler.setBypass(true);

        User usr1 = makeUser(1);
        usr1.ProfileId = profiles[0].Id;
        usr1.IsActive = true;
        insert usr1;

        insert new PermissionSetAssignment(
            AssigneeId = usr1.Id,
            PermissionSetId = permSets[0].Id
        );

        PSUserTriggerHandler.setBypass(false);


        Test.startTest();
        update new User(
            Id = usr1.Id,
            ProfileId = profiles[1].Id
        );
        Test.stopTest();

        List<PermissionSetAssignment> permSetAssignments =  [
            SELECT Id, PermissionSetId, AssigneeId, PermissionSet.Name
            FROM PermissionSetAssignment
        WHERE AssigneeId = :usr1.Id AND PermissionSet.ProfileId = null
        ];
        System.assertEquals(0, permSetAssignments.size(), 'Original assignment should be erased');
    }
}