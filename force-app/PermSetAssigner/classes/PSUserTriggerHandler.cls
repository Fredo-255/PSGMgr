/**
 * @description       : 
 * @author            : VISEO / FFI
 * @last modified on  : 10-11-2021
 * @last modified by  : VISEO / FFI
**/
@SuppressWarnings('pmd.ApexCRUDViolation')
public without sharing class PSUserTriggerHandler {
    
    
    private static Map<String, Set<String>> mapAssignments = new Map<String, Set<String>>();
    private static Map<String, Id> psIds = new Map<string, Id>();
    private static Map<String, Id> profIds = new Map<string, Id>();
    private static Map<String, Set<PermissionSetAssignment>> assignmentsByUser = new Map<String, Set<PermissionSetAssignment>>();

    private static Map<String, Set<String>> testAssignments;
    private static Boolean bypass = FeatureManagement.checkPermission('BypassPermsetTrigger');
    
    
    public static void updatePermissionSetsAssignments() {

        if(bypass) { return; } // Opportunity to bypass trigger during test setup

        readIds();
        readConfFromCMDT();
        readConfFromData();

        List<PermissionSetAssignment> psaToAdd = new List<PermissionSetAssignment>();
        List<PermissionSetAssignment> psaToRemove = new List<PermissionSetAssignment>();

        Set<Id> usrIds = filterUserIds(); // in case of update, removes user whose profile is unchanged
        if(usrIds.size() == 0) { return; }

        readCurrentAssignments(usrIds);

        for(String userId : usrIds) {
            if(Trigger.isUpdate) {
                psaToRemove.addAll(getPsaToRemove(userId));
            }
            psaToAdd.addAll(getPsaToAdd(userId));
        }

        if(psaToRemove.size() > 0) {
            delete psaToRemove;
        }
        if(psaToAdd.size() > 0) {
            insert psaToAdd;
        }

    }

    private static List<PermissionSetAssignment> getPsaToRemove(String userId) {
        User oldUser = (User)Trigger.oldMap.get(userId);
        User newUser = (User)Trigger.newMap.get(userId);
        String oldProfileId = oldUser.ProfileId;
        String newProfileId = newUser.ProfileId;

        Set<String> setOldAssignments = mapAssignments.containsKey(oldProfileId)?mapAssignments.get(oldProfileId):new Set<String>();
        Set<String> setNewAssignments = mapAssignments.containsKey(newProfileId)?mapAssignments.get(newProfileId):new Set<String>();
        
        List<PermissionSetAssignment> lstPsa = new List<PermissionSetAssignment>();
        if(!assignmentsByUser.containsKey(userId)) { return lstPsa; }

        for(PermissionSetAssignment psa : assignmentsByUser.get(userId)) {
            if(setOldAssignments.contains(psa.PermissionSetId) && !setNewAssignments.contains(psa.PermissionSetId)) {
                // If the PS is assigned to the old profile but not to the new one, it must be removed
                lstPsa.add(new PermissionSetAssignment(
                    Id = psa.Id
                ));
            }
        }

        return lstPsa;
    }

    private static List<PermissionSetAssignment> getPsaToAdd(String userId) {
        User usr = (User)Trigger.newMap.get(userId);
        String profileId = usr.ProfileId;
        Set<String> setAssignments = mapAssignments.containsKey(profileId)?mapAssignments.get(profileId):new Set<String>();
        List<PermissionSetAssignment> lstPsa = new List<PermissionSetAssignment>();
        for(String psId : setAssignments) {
            Boolean isPresent = false;
            Set<PermissionSetAssignment> currentAssignments = assignmentsByUser.containsKey(userId)?assignmentsByUser.get(userId):new Set<PermissionSetAssignment>();
            for(PermissionSetAssignment psa : currentAssignments) {
                if(psa.PermissionSetId == psid) {
                    isPresent = true;
                    break;
                }
            }
            if(!isPresent) {
                lstPsa.add(new PermissionSetAssignment(
                    AssigneeId = userId,
                    PermissionSetId = psId
                ));
            }
        }

        return lstPsa;
    }

    private static Set<Id> filterUserIds() {
        Set<Id> usrids = new Set<Id>();
        for(User usr : (List<User>)Trigger.new) {
            if(Trigger.isUpdate) {
                User oldUsr = (User)Trigger.oldMap.get(usr.Id);
                if(usr.isActive && (usr.ProfileId != oldUsr.ProfileId || !oldUsr.IsActive)) {
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
    

    private static void readIds() {
        for(Profile prof : [
                SELECT Id, Name 
                FROM Profile ]) 
        {
            profIds.put(prof.Name, prof.Id);
        }

        for(PermissionSet ps : [
            SELECT Id, Name 
            FROM PermissionSet 
            WHERE PermissionSet.ProfileId = null]) 
        {
            psIds.put(ps.Name, ps.Id);
        }
    }

    private static void readConfFromCMDT() {

        for(PSAssignment__mdt assignment : PSAssignment__mdt.getAll().Values()) {
            addAssignmentDataToMap(assignment.Profile__c, assignment.PermissionSets__c);
        }
        if(Test.isRunningTest()) {
            mapAssignments.clear();
            // For tests, only use test provided data (no custom metadata)
        }
    }

    private static void readConfFromData() {

        for(PermSetProfileAssignment__c assignment : [
            SELECT Profile__c, PermissionSets__c
            FROM PermSetProfileAssignment__c
        ]) 
        {
            addAssignmentDataToMap(assignment.Profile__c, assignment.PermissionSets__c);
        }
    }
    
    private static void addAssignmentDataToMap(String profileName, String permissionSets) {
        String profId = profIds.get(profileName);
        List<String> lstPermSetIds = new list<String>();

        for(String psName : permissionSets.split(',')) {
            if(psIds.containsKey(psName)) {
                lstPermSetIds.add(psIds.get(psName));
            }
        }

        if(!mapAssignments.containsKey(profId)) {
            mapAssignments.put(profId, new Set<String>());
        }
        mapAssignments.get(profId).addAll(lstPermSetIds);
    }

    private static void readCurrentAssignments(Set<Id> userIds) {
        for(PermissionSetAssignment psa : [
            SELECT Id, AssigneeId, PermissionSetId
            FROM PermissionSetAssignment
            WHERE AssigneeId IN :userIds AND PermissionSet.ProfileId = null
        ]) {
            if(!assignmentsByUser.containsKey(psa.AssigneeId)) {
                assignmentsByUser.put(psa.AssigneeId, new Set<PermissionSetAssignment>());
            }
            assignmentsByUser.get(psa.AssigneeId).add(psa);
        }
    }

    @testVisible
    private static void setBypass(Boolean bypassValue) {
        bypass = bypassValue;
    }


}
