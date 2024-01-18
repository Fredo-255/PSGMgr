/**
 * @description       : 
 * @author            : VISEO / FFI
 * @last modified on  : 01-18-2024
 * @last modified by  : VISEO / FFI
**/
@SuppressWarnings('pmd.CognitiveComplexity')
public without sharing class PSUserTriggerHandler {
    
    
    private static Map<String, Set<String>> mapAssignments = new Map<String, Set<String>>();
    private static Map<String, Set<PermissionSetAssignment>> assignmentsByUser = new Map<String, Set<PermissionSetAssignment>>();

    private static Map<String, Set<String>> testAssignments;
    private static Boolean bypass = FeatureManagement.checkPermission('BypassPermsetTrigger');

    @TestVisible
    private static Boolean updating = false;
    
    
    public static void updatePermissionSetsAssignments() {

        if(bypass) { return; } // Opportunity to bypass trigger during test setup

        PSAUsers users = new PSAUsers();
        Set<Id> usrIds = users.filteredIds;
        if(usrIds.isEmpty()) { return; }

        mapAssignments = PSAConfigReader.read();

        List<PermissionSetAssignment> psaToAdd = new List<PermissionSetAssignment>();
        List<PermissionSetAssignment> psaToRemove = new List<PermissionSetAssignment>();

        assignmentsByUser = PSAAssignments.readCurrentAssignments(usrIds);

        for(String userId : usrIds) {
            if(updating || (Trigger.isExecuting && Trigger.isUpdate)) {
                psaToRemove.addAll(getPsaToRemove(users, userId));
            }
            psaToAdd.addAll(getPsaToAdd(users, userId));
        }

        if(psaToRemove.size() > 0) {
            PSAAssignments.deleteAssignments(psaToRemove);
        }
        if(psaToAdd.size() > 0) {
            PSAAssignments.insertAssignments(psaToAdd);
        }
        users.clearForceFlags();

    }

    private static List<PermissionSetAssignment> getPsaToRemove(PSAUsers users, String userId) {
        User oldUser = users.oldUser(userId);
        User newUser = users.newUser(userId);
        String oldProfileId = oldUser.ProfileId;
        String newProfileId = newUser.ProfileId;

        Set<String> setOldAssignments = mapAssignments.containsKey(oldProfileId)?mapAssignments.get(oldProfileId):new Set<String>();
        Set<String> setNewAssignments = new Set<String>();
        if(newUSer.isActive) {
            // In case the user is deactivated, we want to remove its old assignments, whether or not the profile has changed
            setNewAssignments = mapAssignments.containsKey(newProfileId)?mapAssignments.get(newProfileId):new Set<String>();
        }
        
        
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

    private static List<PermissionSetAssignment> getPsaToAdd(PSAUsers users, String userId) {
        User usr = users.newUser(userId);
        if(!usr.IsActive) {
            // If the user has been deactivated, we return an empty list so that no new assignments are added
            return new List<PermissionSetAssignment>();
        }
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




    @testVisible
    private static void setBypass(Boolean bypassValue) {
        bypass = bypassValue;
    }


}
