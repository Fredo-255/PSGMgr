/**
 * @description       : 
 * @author            : VISEO / FFI
 * @last modified on  : 01-18-2024
 * @last modified by  : VISEO / FFI
**/
public with sharing class PSAConfigReader {

    private static Map<String, Set<String>> mapAssignments = new Map<String, Set<String>>();

    public static Map<String, Set<String>> read() {
        readConfFromCMDT();
        readConfFromData();
        return mapAssignments;

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
            WITH SYSTEM_MODE
        ]) 
        {
            addAssignmentDataToMap(assignment.Profile__c, assignment.PermissionSets__c);
        }
    }
    
    private static void addAssignmentDataToMap(String profileName, String permissionSets) {
        String profId = PSAProfiles.profIds.get(profileName);
        List<String> lstPermSetIds = new list<String>();

        for(String psName : permissionSets.split(',')) {
            if(PSAProfiles.psIds.containsKey(psName)) {
                lstPermSetIds.add(PSAProfiles.psIds.get(psName));
            }
        }

        if(!mapAssignments.containsKey(profId)) {
            mapAssignments.put(profId, new Set<String>());
        }
        mapAssignments.get(profId).addAll(lstPermSetIds);
    }
}