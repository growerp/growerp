  Relationship Between Flutter, REST, and Moqui Data Models in GrowERP

  The GrowERP system utilizes distinct data models for its Flutter frontend and Moqui backend, with a REST interface
  acting as the crucial intermediary.


  1. Flutter Data Model (growerp_models package)
   * Purpose: This package defines the client-side data structures used by the Flutter application. These models are
     written in Dart and are optimized for efficient data handling within the mobile/web application.
   * Implementation: These models are generated using freezed and json_serializable. This means they are immutable Dart
     classes that can be easily serialized to and deserialized from JSON.
   * Example (`User`): The user_model.dart file in growerp_models would define a User class with fields like userId,
     firstName, lastName, email, etc., along with methods for JSON conversion. This model represents how user data is
     structured and used within the Flutter app.

  2. Moqui Data Model (mantle-udm component)
   * Purpose: This is the server-side, persistent data model managed by the Moqui Framework. It defines the database
     schema and relationships between entities.
   * Implementation: As seen in moqui/runtime/component/mantle-udm/entity/PartyEntities.xml, Moqui uses XML files to
     define its entities. The core entity for users is Party, which can represent a Person or an Organization. The
     UserAccount entity (from moqui.security) links to a Party.
   * Example (`User`): The Party entity in Moqui would have fields like partyId, pseudoId, partyTypeEnumId, externalId,
     etc. The Person entity would extend Party with firstName, middleName, lastName, birthDate, etc. The UserAccount
     entity would contain authentication-related fields and a partyId to link to the Party entity.

  3. REST Interface (e.g., https://test.growerp.org/rest/service.swagger/growerp)
   * Purpose: The REST interface acts as the communication layer between the Flutter frontend and the Moqui backend. It
     defines the API endpoints, the request/response formats, and the operations (CRUD: Create, Read, Update, Delete)
     that can be performed on the data.
   * Role as an Intermediary:
       * Serialization/Deserialization: When the Flutter app sends data (e.g., a new user) to the backend, the Flutter
         UserModel is serialized into a JSON payload. The REST API receives this JSON, and the Moqui backend deserializes
         it into its internal Party and UserAccount entities for persistence in the database.
       * Data Transformation: The REST API (or the Moqui services behind it) is responsible for any necessary
         transformations between the Flutter data model's structure and the Moqui data model's structure. For instance, a
         single UserModel in Flutter might map to multiple entities (Party, Person, UserAccount) in Moqui.
       * Business Logic & Validation: The REST endpoints also encapsulate business logic and validation rules before data
         is committed to the Moqui database.
       * Security: The API handles authentication and authorization, ensuring that only authorized requests can access or
         modify data.
   * Example (`User`): The Swagger definition for the User entity would describe the JSON structure that the Flutter app
     sends and receives for user-related operations. This JSON structure would be a simplified or aggregated view of the
     underlying Moqui Party, Person, and UserAccount entities, tailored for the frontend's needs. For example, a GET
     request to /users/{userId} might return a JSON object that combines firstName, lastName (from Person), email (from
     UserAccount or a related contact mechanism), and partyId (from Party).

  In summary:

   * The Flutter data model is the client-side representation, optimized for the application's UI and logic.
   * The Moqui data model is the server-side, persistent representation, optimized for database storage and backend
     business logic.
   * The REST interface serves as the bridge, defining the contract for data exchange and performing the necessary
     mapping and transformations between these two distinct data models.


