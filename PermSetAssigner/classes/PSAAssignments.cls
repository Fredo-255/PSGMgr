/**
 * @description       : 
 * @author            : VISEO / FFI
 * @last modified on  : 01-19-2024
 * @last modified by  : VISEO / FFI
**/
public with sharing class PSAAssignments {


    @testVisible 
    private static List<PermissionSetAssignment> currentAssignments;
    @testVisible 
    private static Integer deleted = 0;
    @testVisible
    private static List<PermissionSetAssignment> toRemove;
    @testVisible 
    private static Integer inserted = 0;
    @testVisible
    private static List<PermissionSetAssignment> toAdd;
    @testVisible
    private static Boolean mock = Test.isRunningTest();



    public static Map<String, Set<PermissionSetAssignment>> readCurrentAssignments(Set<Id> userIds) {
        Map<String, Set<PermissionSetAssignment>> resultMap = new Map<String, Set<PermissionSetAssignment>>();
        if(currentAssignments == null) {
            currentAssignments = [
                SELECT Id, AssigneeId, PermissionSetId
                FROM PermissionSetAssignment
                WHERE AssigneeId IN :userIds AND PermissionSet.ProfileId = null
                WITH SYSTEM_MODE
            ];
        }
        for(PermissionSetAssignment psa : currentAssignments){
            if(!resultMap.containsKey(psa.AssigneeId)) {
                resultMap.put(psa.AssigneeId, new Set<PermissionSetAssignment>());
            }
            resultMap.get(psa.AssigneeId).add(psa);
        }
        return resultMap;
    }

    public static void insertAssignments(List<PermissionSetAssignment> assignments) {
        if (!mock) {
            Database.insert(assignments, false, AccessLevel.SYSTEM_MODE);
        }
        inserted = assignments.size();
        toAdd = assignments;
    }


    public static void deleteAssignments(List<PermissionSetAssignment> assignments) {
        if (!mock) {
            Database.delete(assignments, false, AccessLevel.SYSTEM_MODE);
        }
        deleted = assignments.size();
        toRemove = assignments;
    }




}