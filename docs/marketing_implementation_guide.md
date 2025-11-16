# Implementation Guide: GrowERP, BirdSend, and Landing Page Integration

This guide outlines the technical steps to implement the marketing plan by modifying the existing GrowERP Flutter landing page to capture leads and send them to BirdSend via the Moqui backend.

## High-Level Architecture (Updated)

The data will flow as follows:

1.  A user fills out the new lead capture form on the GrowERP public landing page (Flutter).
2.  The form submission triggers a `LandingPageLeadCapture` event in the `LandingPageBloc`.
3.  The Bloc calls a new `captureLead` method in the `RestClient`.
4.  The `RestClient` makes a REST API call to the `createLeadAndAddToBirdSend` service in the Moqui backend.
5.  The Moqui service creates a `Lead` record in GrowERP and calls the BirdSend API to add the contact to the "Cold Email Sequence".
6.  When the lead is converted in GrowERP, a separate trigger calls the BirdSend API to move them to the "Weekly Mailing List".

---

## Part 1: Backend (Moqui)

This section outlines the backend service that needs to be created. It's the same service as in the previous version of this guide, but it's now called by the Flutter application instead of a public form post.

### Step 1: Create the `createLeadAndAddToBirdSend` Service

In your Moqui component, create a service that creates a lead in GrowERP and then calls the BirdSend API.

**File:** `.../component/service/MarketingServices.xml` (create if it doesn't exist)

```xml
<service verb="create" noun="LeadAndAddToBirdSend">
    <description>Create a lead and add it to BirdSend</description>
    <in-parameters>
        <parameter name="firstName" required="true"/>
        <parameter name="emailAddress" required="true"/>
    </in-parameters>
    <out-parameters>
        <parameter name="partyId"/>
    </out-parameters>
    <actions>
        <!-- 1. Create the Lead in GrowERP -->
        <service-call name="create#Party" in-map="[partyTypeId:'PERSON']" out-map="context"/>
        <service-call name="create#PartyName" in-map="[partyId:partyId, firstName:firstName]" out-map="context"/>
        <service-call name="create#PartyContactMech" in-map="[partyId:partyId, contactMechPurposeId:'PRIMARY_EMAIL', emailAddress:emailAddress]" out-map="context"/>
        <service-call name="create#Lead" in-map="[partyId:partyId, statusId:'LEAD_NEW']" out-map="context"/>

        <!-- 2. Add the Lead to BirdSend -->
        <service-call name="addLeadToBirdSend" in-map="[email:emailAddress, firstName:firstName]"/>
    </actions>
</service>

<service verb="addLeadToBirdSend" noun="Lead">
    <description>Adds a lead to the BirdSend cold email sequence.</description>
    <in-parameters>
        <parameter name="email" required="true"/>
        <parameter name="firstName" required="true"/>
    </in-parameters>
    <actions>
        <script>
            def url = "https://api.birdsend.co/v1/subscribers";
            def apiKey = "YOUR_BIRD_SEND_API_KEY"; // Store this securely

            def headers = [
                "Authorization": "Bearer " + apiKey,
                "Content-Type": "application/json"
            ];

            def body = [
                "email": email,
                "first_name": firstName,
                "tags": ["cold-lead-sequence"] // Use a tag to trigger the sequence
            ];

            ec.service.sync().call("mantle.service.ServiceTools.send#RestRequest", [
                url: url,
                method: "POST",
                headers: headers,
                body: groovy.json.JsonOutput.toJson(body)
            ]);
        </script>
    </actions>
</service>
```

### Step 2: Expose the Service via REST API

**File:** `.../component/rest-api.xml`

```xml
<resource name="marketing">
    <resource name="lead">
        <method type="post">
            <service name="...MarketingServices.create#LeadAndAddToBirdSend"/>
        </method>
    </resource>
</resource>
```
*Note: Ensure the service path is correct.*

---

## Part 2: Frontend (Flutter)

This section details the changes needed in the Flutter application.

### Step 1: Add Lead Capture Method to RestClient

**File:** `flutter/packages/growerp_models/lib/src/rest_client.dart`

Add a new method to your `RestClient` class to call the backend service.

```dart
// Add this inside the RestClient class
Future<void> captureLead({
  required String firstName,
  required String emailAddress,
}) async {
  try {
    await dio.post(
      '/rest/s1/marketing/lead',
      data: {
        'firstName': firstName,
        'emailAddress': emailAddress,
      },
    );
  } catch (e) {
    throw Exception(getDioError(e));
  }
}
```

### Step 2: Add the Lead Capture Event

**File:** `flutter/packages/growerp_assessment/lib/src/bloc/landing_page_event.dart`

Create a new event to represent the lead capture action.

```dart
// Add this to the file
class LandingPageLeadCapture extends LandingPageEvent {
  const LandingPageLeadCapture({
    required this.firstName,
    required this.email,
  });
  final String firstName;
  final String email;

  @override
  List<Object> get props => [firstName, email];
}
```

### Step 3: Update the LandingPageBloc

**File:** `flutter/packages/growerp_assessment/lib/src/bloc/landing_page_bloc.dart`

Handle the new event in the `LandingPageBloc`.

```dart
// In the constructor, add the new event handler
on<LandingPageLeadCapture>(_onLandingPageLeadCapture);

// Add the new handler method to the Bloc class
Future<void> _onLandingPageLeadCapture(
  LandingPageLeadCapture event,
  Emitter<LandingPageState> emit,
) async {
  try {
    emit(state.copyWith(status: LandingPageStatus.loading));
    await restClient.captureLead(
      firstName: event.firstName,
      emailAddress: event.email,
    );
    emit(state.copyWith(
      status: LandingPageStatus.success,
      message: 'Thank you for your interest! We will be in touch shortly.',
    ));
  } catch (error) {
    emit(state.copyWith(
      status: LandingPageStatus.failure,
      message: await getDioError(error),
    ));
  }
}
```

### Step 4: Update the Landing Page UI

**File:** `flutter/packages/growerp_assessment/lib/src/screens/public_landing_page_screen.dart`

Modify the `_PublicLandingPageScreenState` to include a form in the CTA section.

1.  **Add State Variables:**
    ```dart
    // Add these to the _PublicLandingPageScreenState class
    final _formKey = GlobalKey<FormState>();
    final _firstNameController = TextEditingController();
    final _emailController = TextEditingController();

    @override
    void dispose() {
      _firstNameController.dispose();
      _emailController.dispose();
      super.dispose();
    }
    ```

2.  **Replace `_buildCtaSection`:**
    Replace the existing `_buildCtaSection` method with this new one that includes the form.

    ```dart
    Widget _buildCtaSection(BuildContext context, LandingPage page) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withAlpha((0.8 * 255).round()),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                'Get personalized recommendations in just 3 minutes - completely free!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty || !value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      context.read<LandingPageBloc>().add(
                        LandingPageLeadCapture(
                          firstName: _firstNameController.text,
                          email: _emailController.text,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Get Started Now',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    ```

---

## Part 3: Lead Conversion

The process for handling lead conversion remains the same. When a lead is converted in GrowERP, a trigger (e.g., a Moqui ECA rule) should call a service that uses the BirdSend API to move the contact from the "cold-lead-sequence" to the "weekly-newsletter" tag/audience.