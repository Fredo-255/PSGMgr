/**
 * @description       : 
 * @author            : VISEO / FFI
 * @last modified on  : 01-18-2024
 * @last modified by  : VISEO / FFI
**/
public with sharing class PSAProfiles {

    @TestVisible 
    private static List<Profile> profiles {
        get {
            if(profiles == null) {
                profiles =  [
                    SELECT Id, Name 
                    FROM Profile 
                    WITH SYSTEM_MODE
                    ];
            }
            return profiles;
        }
        set;
    }

    @TestVisible 
    private static List<PermissionSet> permSets {
        get {
            if(permSets == null) {
                permSets =  [
                    SELECT Id, Name 
                    FROM PermissionSet 
                    WHERE PermissionSet.ProfileId = null
                    WITH SYSTEM_MODE
                    ];
            }
            return permSets;
        }
        set;
    }




    public static Map<String, Id> psIds {
        public get {
            if(psIds == null) {
                psIds = readPermsets();
            }
            return psIds;
        }
        private set;
    }

    public static Map<String, Id> profIds {
        public get {
            if(profIds == null) {
                profIds = readProfiles();
            }
            return profIds;
        }
        private set;
    }


    private static Map<String, Id> readProfiles() {
        Map<String, Id> resultMap = new Map<String, Id>();
        for(Profile prof : profiles) {
            resultMap.put(prof.Name, prof.Id);
        }
        return resultMap;
    }

    private static Map<String, Id> readPermSets() {
        Map<String, Id> resultMap = new Map<String, Id>();
        for(PermissionSet ps : permSets) {
            resultMap.put(ps.Name, ps.Id);
        }
        return resultMap;
    }
}