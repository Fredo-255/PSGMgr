# Permission set assigner

## Description

This package provides an automated mechanism to automatically assign permission sets and / or permission set groups to users based on their profiles

## Installation and setup

Simply install the package. Considering normal users have no business managing profiles and permission sets, I recommend installing for Admins only (A permisison set is provided to give access if needed)

**Package installation may assign the _Bypass Permset Trigger_ custom permission to the Admin profile. You'll want to remove it first from Admin profile for the trigger to run**

### Special permission sets

The package provides the following permission set :

- **Manage Perm Set To Profile Assignments :** Gives R/W access to the configuration application and then configuratrion custom object.


### Bypassing assignments 
Create a custom permission named **BypassPermSetTrigger**.
Use this permission in a profile/permission set if you want the running user add/modify users without running the assignment trigger. (e.g. to optimize mass import of users). 


## Configuration

Assignments can be defined through both the PSAssignment__mdt custom metadatype (easier to manage if you want to deploy configuration accross environments) or the PermSetAssignment__c custom object. 

For each of these configuration items you have two fields :
- Profile : Name of the profile to which permission sets are assigned
- Permission Sets : Comma separated list of permission sets to assign to the profile.

While it is possible to define more than one assignment list for a given profile, for more flexibility, it is recommended to use permission set groups should you have to manage multiple permission sets assignments to one profile. 

*It is to be noted that no action is performed when you update the Permission Set Assigner configuration. Permissions set are only assigned during user creation, activation, or change of permission sets*


## How does it work ?

When a new *active* user is created the algorithm checks if one or more permission sets are assigned to the user profile. If so, these permission sets are automatically assigned to the user.

When an active user changes profile or an inactive user is activated, the algorithm first checks if permission sets are assigned to the original profile and if so removes them from the user.
It then checks if permission sets are assigned to the new profile and if so assigns them to the the user. 

## Notes

No license consistency check is done between profile and associated permission sets. Assigning a permission set with a different license is assigned to a profile, the trigger will run but the permission will not be associated to the user.
No sucess/failure report is generated as of today.