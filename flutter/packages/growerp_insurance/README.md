# growerp_insurance

GrowERP building block for insurance agencies and brokers.

- **Policies**: the policies the agency sold for a carrier (an insurance
  company, a supplier in GrowERP) to a client (a customer), with any line of
  business, coverages, premium and commission rate.
- **Renewals**: policies expiring within 60 days; a daily backend job marks
  policies expiring within 30 days Renewal Due and emails the client. A
  renewal copies the policy for the next term.
- **Commissions**: expected yearly commission per policy against what the
  carrier paid; a received commission is booked as a sales invoice to the
  carrier.
- **Claims**: reported by staff or by the client, followed up with the carrier.
- **Client portal** (`MyPoliciesView`): clients log in as outside users
  (GROWERP_M_OTHER) and see their own policies and claims, and report a claim.

Widgets: `PolicyList`, `PolicyRenewalList`, `CommissionList`, `ClaimList`,
`MyPoliciesView`. Bloc providers: `getInsuranceBlocProviders(restClient)`.
Localizations: `InsuranceLocalizations.delegate`.

Used by the `insurance` app.
