# Permission set assigner

## Release Notes
### 0.5 : 
- Inital Beta version

### 1.0.0
- Improved handling of user deactivation
- Add a force flag

### 1.1.0
- Managed package. You'll have to import your configuration from the old to the new psa255__ objects
- Refactoring of test classes to make packaging work again
- Clean up Perm Set to Profile Assignment record page

### 1.2.0 
- Add link to this page in package

## Roadmap (As of today. Definitely not contractyual/ Suject to change based on my current mood))

### 1.5 
- Auto Assignment to Public Groups and Chatter groups

### 2.0 (Safe Harbor implied as it depends on a preview feature!!!)
- Use Dynamic formulaes feature (Dev preview in Spring '24) do define criteriaes beyond user profile

### Other ideas : 
- Global trigger bypass, should you wish to have control on the trigger handling.
- UI to manage the custom metadata

## Description

This package provides an automated mechanism to automatically assign permission sets and / or permission set groups to users based on their profiles

## Installation and setup

### Installation : 
On a sandbox
- Version 1.2 : https://login.salesforce.com/packaging/installPackage.apexp?p0=04tWx00000004q1IAA 

On production
- Version 1.2 : https://login.salesforce.com/packaging/installPackage.apexp?p0=04tWx00000004q1IAA 

Considering normal users have no business managing profiles and permission sets, I recommend installing for Admins only (A permisison set is provided to give access if needed)

**Package installation will assign the _psa255.Bypass Permset Trigger_ custom permission to the Admin profile. You'll want to remove it first from the Admin profile for the trigger to run**

(There is no way as of today to prevent this permission from being added to the Admin profile while installling the package)

### Special permission sets

The package provides the following permission set :

- **Manage Perm Set To Profile Assignments :** Gives R/W access to the configuration application and the configuratrion custom object.


### Bypassing assignments 
The **psa255.BypassPermSetTrigger** is provided to bypass automatic assignment should you need to.
Use this permission in a profile/permission set if you want the running user to add/modify users without running the assignment trigger. (e.g. to optimize mass import of users). 


## Configuration

Assignments can be defined through both the psa255__PSAssignment__mdt custom metadatype (easier to manage if you want to deploy configuration accross environments) or the psa255__PermSetAssignment__c custom object. 

For each of these configuration items you have two fields :
- Profile : Name of the profile to which permission sets are assigned
- Permission Sets : Comma separated list of permission sets to assign to the profile.

While it is possible to define more than one assignment list for a given profile, for more flexibility, it is recommended to use permission set groups should you have to manage multiple permission sets assignments to one profile. 

*It is to be noted that no action is performed when you update the Permission Set Assigner configuration. Permissions set are only assigned during user creation, activation, or change of permission sets. You may however use the* Force Permission set Assignment *flag on users to recalculate assignments.*


## How does it work  

When a new *active* user is created the algorithm checks if one or more permission sets are assigned to the user profile. If so, these permission sets are automatically assigned to the user.

When an active user changes profile or an inactive user is activated, the algorithm first checks if permission sets are assigned to the original profile and if so removes them from the user.
It then checks if permission sets are assigned to the new profile and if so assigns them to the the user. 

*__New in version 1.0.0__*

- When an user is deactivated permission set that were assigned due to its profile are removed (they will be reenabled when the user is reactivated)
- Checking the Force Permission set Assignment flag will force the algorithm to run. *Note : This will not clear assignments for permission sets removed from configuration, chek for a new version  in the future*




## Notes

No license consistency check is done between profile and associated permission sets. If a permission set with a different license is assigned to a profile, the trigger will run but the permission set will not be associated to the user.
No sucess/failure report is generated as of today.


