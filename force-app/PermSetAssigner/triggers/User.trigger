/**
 * @description       : 
 * @author            : VISEO / FFI
 * @last modified on  : 10-07-2021
 * @last modified by  : VISEO / FFI
**/
trigger User on User (after insert, after update) {
    UserTriggerHandler.updatePermissionSetsAssignments();
}