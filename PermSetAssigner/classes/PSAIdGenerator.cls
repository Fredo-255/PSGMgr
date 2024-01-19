/**
 * @description       : 
 * @author            : VISEO / FFI
 * @last modified on  : 01-19-2024
 * @last modified by  : VISEO / FFI
**/
public class PSAIdGenerator {
    private static Integer fakeIdCount = 0;
    private static final String ID_PATTERN = '000000000000';

    /**
     * Generate a fake Salesforce Id for the given SObjectType
     */
    public static Id generate(Schema.SObjectType sobjectType) {
        String keyPrefix = sobjectType.getDescribe().getKeyPrefix();
        fakeIdCount++;

        String fakeIdPrefix = ID_PATTERN.substring(0, ID_PATTERN.length() - String.valueOf(fakeIdCount).length());

        return Id.valueOf(keyPrefix + fakeIdPrefix + fakeIdCount);
    }
}
