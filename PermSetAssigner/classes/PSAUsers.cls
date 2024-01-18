/**
 * @description       : 
 * @author            : VISEO / FFI
 * @last modified on  : 01-18-2024
 * @last modified by  : VISEO / FFI
**/
public with sharing class PSAUsers {
    
    @TestVisible
    private static List<User> mockedUsers;
    private List<User> newUsers;
    @TestVisible 
    private static Map<Id, User> oldMap = (Map<Id, User>)Trigger.oldMap;
    private map<Id, User> newMap = new Map<id, User>();
    @TestVisible 
    private static Boolean updating = false;
    @TestVisible
    private Boolean mock = Test.isRunningTest();
    @TestVisible
    private static Integer updated = 0;

    public PSAUsers() {
        if(!mock) { 
            newUsers = (List<User>)Trigger.new;
            newMap = (Map<id, User>)Trigger.newMap;
        } else {
            newUsers = mockedUsers;
            newMap = new Map<Id, User>(newUsers);
        } 
    }

    public User newUser(Id userId) {
        return newMap.get(userId);
    }

    public User oldUser(Id userId) {
        return oldMap.get(userId);
    }
    
    public Set<Id> filteredIds {
        public get {
            if (filteredIds == null) {
                filteredIds = filterUserIds();
            }
            return filteredIds;
        }
        private set;
    }

    private Set<Id> filterUserIds() {
        Set<Id> usrids = new Set<Id>();
        for(User usr : newUsers) {
            if(updating || (Trigger.isExecuting && Trigger.isUpdate)) {
                User oldUsr = oldMap.get(usr.Id);
                if(usr.ProfileId != oldUsr.ProfileId || oldUsr.IsActive != usr.isActive || (usr.Force_Permission_Set_Assignment__c && usr.IsActive)) {
                    usrIds.add(usr.Id);
                }
            } else {
                if(usr.isActive) { 
                    usrIds.add(usr.Id);
                }
            }
        }
        return usrIds;
    }

    public void clearForceFlags() {
        List<User> lstUsers = new List<user>();
        for(User usr : newUsers) {
            if(usr.Force_Permission_Set_Assignment__c) {
                lstUsers.add(new User(
                    id = usr.Id,
                    Force_Permission_Set_Assignment__c = false
                ));
            }
        }
        if(!lstUsers.isEmpty()) {
            if(!mock) {
                Database.update(lstUsers, false, AccessLevel.SYSTEM_MODE);
            }
            updated = lstUsers.size();
        }
    }




}