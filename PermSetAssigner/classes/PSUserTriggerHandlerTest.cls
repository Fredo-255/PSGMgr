/**
 * @description       : 
 * @author            : VISEO / FFI
 * @last modified on  : 01-18-2024
 * @last modified by  : VISEO / FFI
**/
@isTest
private class PSUserTriggerHandlerTest {

    private static List<PermissionSet> getPermSets(integer maxitems) {
        List<PermissionSet> permsets = new List<PermissionSet>();
        for (Integer i = 0; i < maxitems; i++) {
            permsets.add(new PermissionSet(
                Id = PSAIdGenerator.generate(PermissionSet.sobjectType),
                Name = 'PermSet' + i
            ));
        }
        PSAProfiles.permSets = permsets;
        return permsets;
    }


    private static List<Profile> getProfiles(integer maxitems) {
        List<Profile> profiles = new List<Profile>();
        for (Integer i = 0; i < maxitems; i++) {
            profiles.add(new Profile(
                Id = PSAIdGenerator.generate(Profile.sobjectType),
                Name = 'Profile' + i
            ));
        }
        PSAProfiles.profiles = profiles;
        return profiles;
    }
    

    private static User makeUser(integer i) {
        return new User (
            Id = PSAIdGenerator.generate(User.sobjectType),
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
                insert psa; 
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
        PSAUsers.mockedUsers = new List<User> { usr1 };

        PSUserTriggerHandler.setBypass(false);
        Test.startTest();
        PSUserTriggerHandler.updatePermissionSetsAssignments();
        Test.stopTest();

        System.assertEquals(1, PSAAssignments.inserted, 'A ssignment should have bneen inserted');
        System.assertEquals(permSets[1].Id, PSAAssignments.toAdd[0].PermissionSetId, 'User was assigned the wrong permission set : ' + PSAAssignments.toAdd[0].PermissionSet.Name);
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
        PSAUsers.mockedUsers = new List<User> { usr1 };

        PSUserTriggerHandler.setBypass(false);
        Test.startTest();
        PSUserTriggerHandler.updatePermissionSetsAssignments();
        Test.stopTest();

        System.assertEquals(0, PSAAssignments.inserted, 'There should be no assignment for User1');
        
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
        PSAUsers.mockedUsers = new List<User> { usr1 };

        PSUserTriggerHandler.setBypass(false);
        Test.startTest();
        PSUserTriggerHandler.updatePermissionSetsAssignments();
        Test.stopTest();


        System.assertEquals(0, PSAAssignments.inserted, 'There should be no assignment for User1');
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

        PSAUsers.oldMap = new Map<Id, User> { 
            usr1.Id => usr1 
        };

        PSAAssignments.currentAssignments = new List<PermissionSetAssignment> {
            new PermissionSetAssignment(
                Id = PSAIdGenerator.generate(PermissionSetAssignment.SObjectType),
                AssigneeId = usr1.Id,
                PermissionSetId = permSets[0].Id
            )
        };

        PSUserTriggerHandler.setBypass(false);
        User newUser = usr1.clone(true);
        newUser.ProfileId = profiles[1].Id;
        PSAUsers.mockedUsers = new List<User>{
            newUser
        };
        PSAUsers.updating = true;
        PSUserTriggerHandler.updating = true;
        Test.startTest();
            PSUserTriggerHandler.updatePermissionSetsAssignments();
        Test.stopTest();


        System.assertEquals(1, PSAAssignments.inserted, 'There should be 1 created');
        System.assertEquals(1, PSAAssignments.deleted, 'Previous assignment soud be removed');
        System.assertEquals(permSets[1].Id, PSAAssignments.toAdd[0].PermissionSetId, 'User was assigned the wrong permission set : ' + PSAAssignments.toAdd[0].PermissionSet.Name);
    }

    @isTest
    private static void testUserUpdateWithForceFlagOn() {
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

        PSAUsers.oldMap = new Map<Id, User> { 
            usr1.Id => usr1 
        };


        PSUserTriggerHandler.setBypass(false);
        User newUser = usr1.clone(true);
        newUser.Force_Permission_Set_Assignment__c = true;
        PSAUsers.mockedUsers = new List<User>{
            newUser
        };
        PSAUsers.updating = true;
        PSUserTriggerHandler.updating = true;
        Test.startTest();
        PSUserTriggerHandler.updatePermissionSetsAssignments();
        Test.stopTest();

        System.assertEquals(1, PSAAssignments.inserted, 'There should be 1 assignment for User1');
        System.assertEquals(permSets[0].Id, PSAAssignments.toAdd[0].PermissionSetId, 'User was assigned the wrong permission set : ' + PSAAssignments.toAdd[0].PermissionSet.Name);
        Assert.areEqual(1, PSAUsers.updated, '1 user should have been updated');
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

        PSAUsers.oldMap = new Map<Id, User> { 
            usr1.Id => usr1 
        };


        PSUserTriggerHandler.setBypass(false);
        User newUser = usr1.clone(true);
        newUser.IsActive = true;
        PSAUsers.mockedUsers = new List<User>{
            newUser
        };
        PSAUsers.updating = true;
        PSUserTriggerHandler.updating = true;
        Test.startTest();
        PSUserTriggerHandler.updatePermissionSetsAssignments();
        Test.stopTest();


        System.assertEquals(1, PSAAssignments.inserted, 'There should be 1 assignment for User1');
        System.assertEquals(permSets[1].Id, PSAAssignments.toAdd[0].PermissionSetId, 'User was assigned the wrong permission set : ' + PSAAssignments.toAdd[0].PermissionSet.Name);
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
        PSAUsers.oldMap = new Map<Id, User> { 
            usr1.Id => usr1 
        };

        PSAAssignments.currentAssignments = new List<PermissionSetAssignment>();

        PSAAssignments.currentAssignments.add( new PermissionSetAssignment(
            AssigneeId = usr1.Id,
            PermissionSetId = permSets[1].Id
        ));
        PSAAssignments.currentAssignments.add( new PermissionSetAssignment(
            AssigneeId = usr1.Id,
            PermissionSetId = permSets[0].Id
        ));


        PSUserTriggerHandler.setBypass(false);
        User newUser = usr1.clone(true);
        newUser.IsActive = false;
        PSAUsers.mockedUsers = new List<User>{
            newUser
        };
        PSAUsers.updating = true;
        PSUserTriggerHandler.updating = true;
        Test.startTest();
        PSUserTriggerHandler.updatePermissionSetsAssignments();
        Test.stopTest();

        System.assertEquals(1, PSAAssignments.deleted, 'A assignment soulld be deleted for User 1');
        System.assertEquals(PSAAssignments.currentAssignments[1].Id, PSAAssignments.toRemove[0].Id, 'Wrong assignment removed : ' + PSAAssignments.toRemove[0].Id);
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
        PSAUsers.oldMap = new Map<Id, User> { 
            usr1.Id => usr1 
        };

        PSAAssignments.currentAssignments = new List<PermissionSetAssignment>{ new PermissionSetAssignment(
            AssigneeId = usr1.Id,
            PermissionSetId = permSets[1].Id
        )};

        PSUserTriggerHandler.setBypass(false);
        User newUser = usr1.clone(true);
        newUser.ProfileId = profiles[1].Id;
        PSAUsers.mockedUsers = new List<User>{
            newUser
        };
        PSAUsers.updating = true;
        PSUserTriggerHandler.updating = true;
        Test.startTest();
        PSUserTriggerHandler.updatePermissionSetsAssignments();
        Test.stopTest();

        System.assertEquals(0, PSAAssignments.inserted, 'No assigments to add');
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
        PSAUsers.oldMap = new Map<Id, User> { 
            usr1.Id => usr1 
        };

        PSAAssignments.currentAssignments = new List<PermissionSetAssignment>{ new PermissionSetAssignment(
            AssigneeId = usr1.Id,
            PermissionSetId = permSets[0].Id
        )};

        PSUserTriggerHandler.setBypass(false);
        User newUser = usr1.clone(true);
        newUser.ProfileId = profiles[1].Id;
        PSAUsers.mockedUsers = new List<User>{
            newUser
        };
        PSAUsers.updating = true;
        PSUserTriggerHandler.updating = true;

        Test.startTest();
        PSUserTriggerHandler.updatePermissionSetsAssignments();
        Test.stopTest();

        System.assertEquals(1, PSAAssignments.inserted, 'A new assignment soulld be added for User 1');
        System.assertEquals(0, PSAAssignments.deleted, 'Old assignment soulld not be deleted for User 1');
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
        PSAUsers.oldMap = new Map<Id, User> { 
            usr1.Id => usr1 
        };


        PSUserTriggerHandler.setBypass(false);
        User newUser = usr1.clone(true);
        newUser.ProfileId = profiles[1].Id;
        PSAUsers.mockedUsers = new List<User>{
            newUser
        };
        PSAUsers.updating = true;
        PSUserTriggerHandler.updating = true;


        Test.startTest();
        PSUserTriggerHandler.updatePermissionSetsAssignments();
        Test.stopTest();

        List<PermissionSetAssignment> permSetAssignments =  [
            SELECT Id, PermissionSetId, AssigneeId, PermissionSet.Name
            FROM PermissionSetAssignment
        WHERE AssigneeId = :usr1.Id AND PermissionSet.ProfileId = null
        ];
        System.assertEquals(1, PSAAssignments.inserted, 'Perm set not assigned');
        System.assertEquals(permSets[1].Id, PSAAssignments.toAdd[0].PermissionSetId, 'User was assigned the wrong permission set : ' + PSAAssignments.toAdd[0].PermissionSet.Name);
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
        PSAUsers.oldMap = new Map<Id, User> { 
            usr1.Id => usr1 
        };

        PSAAssignments.currentAssignments = new List<PermissionSetAssignment> { new PermissionSetAssignment(
            AssigneeId = usr1.Id,
            PermissionSetId = permSets[0].Id
        )};

        PSUserTriggerHandler.setBypass(false);
        User newUser = usr1.clone(true);
        newUser.ProfileId = profiles[1].Id;
        PSAUsers.mockedUsers = new List<User>{
            newUser
        };
        PSAUsers.updating = true;
        PSUserTriggerHandler.updating = true;


        Test.startTest();
        PSUserTriggerHandler.updatePermissionSetsAssignments();
        Test.stopTest();

        System.assertEquals(0, PSAAssignments.inserted, 'No new assignment should be added for User 1');
        System.assertEquals(1, PSAAssignments.deleted, 'Old assignment should  be deleted for User 1');
    }
}