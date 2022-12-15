# Technical Introduction
GrowERP is an Admin Flutter frontend component for Android, IOS and Web using [https://flutter.dev](https://flutter.dev) This application is build for the stable version of flutter, you can find the installation instructions at: [https://flutter.dev/docs/get-started](https://flutter.dev/docs/get-started)

Although all screens work on IOS/Anderoid/Web devices, however a smaller screen will show less information but it is still usable.

It is a simplified frontend however with the ability to still use with, or in addition to the original ERP system screens. The system is a true multicompany system and can support virtually any ERP backend as long as it has a REST interface.

The system is implemented with [https://pub.dev/packages/flutter_bloc](https://pub.dev/packages/flutter_bloc) state management with the [https://bloclibrary.dev](https://bloclibrary.dev) documentation, data models, automated integration tests and a separated rest interface for the different backend systems.

The backend is using the [Moqui ERP and framework](https://www.moqui.org)

The system configuration file is in /assets/cfg/app_settings.json. Select Moqui and for older versions select OFBiz.

The backend Moqui system needs some extra components such as for GrowERP itself, Stripe for payment processor and the PopReststore for the website generated for every company.

For test purposes we can provide access to Moqui or OFBiz backend systems in the cloud.

Additional ERP systems can be added on request, A REST interface is required. The implementation time is 40+ hours.

## Data organization

Obviously the frontend is following the backend datamodel to a great extend, however a bit less flexible. Separation by owner is done in the API interface to the backend.

### On a user level
All data within an created company and admin is controlled or linked to the ownerPartyId with a special partyTypeId 'owner' .

The major database party (owner/company/user) view used:
	owner -> (rel) company  -> (rel) person -> user account --> sec userGroup
										    |-> postal/telephone etc

When a user logs in, the system can retrieve the above from the user account.
The ownerCompanyParty is now the second level, the first level is just an empty placeholder. For convenience the ownerPartyId at the top holds the owner company partyId at the secondlevel.

currently just employees and admins of the owner company can login. Customers can login to the e-commerce website.

A customer user has a single login for all owner websites and will be linked to an new owner when the customer uses a not yet owner website.

### other entities
Other entities like products, categories etc use the 'ownerPartyId' field to separate between owners. It contains from now on the 
