/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class PSAUsersTest {

    @isTest
    private static void testFilterCreate() {
        Id profile1Id = PSAIdGenerator.generate(Profile.getSObjectType());
        PSAUsers.mockedUsers = new List<User> {
            new User(
                Id = PSAIdGenerator.generate(User.getSObjectType()),
                Username = 'user1@test.com',
                ProfileId = profile1Id,
                IsActive = true
            )
        };
        PSAUsers users = new PSAUsers();
        Assert.areEqual(1, users.filteredIds.size(), 'SHoud be 1 filtered user in users');
    }

    @isTest
    private static void testFilterupdate() {
        Id profile1Id = PSAIdGenerator.generate(Profile.getSObjectType());
        Id profile2Id = PSAIdGenerator.generate(Profile.getSObjectType());
        Id userId1 = PSAIdGenerator.generate(User.getSObjectType());
        PSAUsers.mockedUsers = new List<User> {
            new User(
                Id = userId1,
                Username = 'user1@test.com',
                ProfileId = profile1Id,
                Force_Permission_Set_Assignment__c = true,
                IsActive = true
            )
        };
        User oldUser = PSAUsers.mockedUsers[0].clone(true);
        olduser.ProfileId = profile2Id;
        PSAUsers.oldMap = new Map<Id, User> {
            userId1 => oldUser 
        };
        PSAUsers.updating = true;
        PSAUsers users = new PSAUsers();
        Assert.areEqual(users.newUser(userId1).ProfileId, profile1Id, 'wrong Profile returned for updated user');
        Assert.areEqual(users.oldUser(userId1).ProfileId, profile2Id, 'wrong Profile returned for original user');
        Assert.areEqual(1, users.filteredIds.size(), 'SHoud be 1 filtered user in users');
    }

    @isTest
    private static void testClearFlag() {
        Id profile1Id = PSAIdGenerator.generate(Profile.getSObjectType());
        Id profile2Id = PSAIdGenerator.generate(Profile.getSObjectType());
        Id userId1 = PSAIdGenerator.generate(User.getSObjectType());
        PSAUsers.mockedUsers = new List<User> {
            new User(
                Id = userId1,
                Username = 'user1@test.com',
                ProfileId = profile1Id,
                Force_Permission_Set_Assignment__c = true,
                IsActive = true
            )
        };
        PSAUsers users = new PSAUsers();
        users.clearForceFlags();
        Assert.areEqual(1, PSAUsers.updated, 'A user should have been updated');
    }
}