/**
 * @description       : 
 * @author            : VISEO / FFI
 * @last modified on  : 10-11-2021
 * @last modified by  : VISEO / FFI
**/
trigger PSUserTrigger on User (after insert, after update) {
    PSUserTriggerHandler.updatePermissionSetsAssignments();
}