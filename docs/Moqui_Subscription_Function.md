# Moqui Subscription Function Documentation

This document provides an overview of the Moqui subscription functionality, including the data model (entities) and the services that manage subscriptions.

## Data Model

The subscription functionality is based on four main entities:

### 1. `ProductSubscriptionResource`

This entity links a `Product` to a `SubscriptionResource`. It defines the terms of the subscription when a product is purchased.

**Fields:**

*   `productId`: The ID of the product.
*   `subscriptionResourceId`: The ID of the subscription resource.
*   `fromDate`: The date the subscription becomes available.
*   `thruDate`: The date the subscription expires.
*   `purchaseFromDate`: The date from which the subscription can be purchased.
*   `purchaseThruDate`: The date until which the subscription can be purchased.
*   `availableTime`: The duration of the subscription.
*   `availableTimeUomId`: The unit of measurement for `availableTime`.
*   `useCountLimit`: The number of times the subscription can be used.
*   `useTime`: The duration of each use.
*   `useTimeUomId`: The unit of measurement for `useTime`.
*   `useRoleTypeId`: The role required to use the subscription.

### 2. `Subscription`

This entity represents an instance of a subscription for a specific party.

**Fields:**

*   `subscriptionId`: The unique ID of the subscription.
*   `subscriptionTypeEnumId`: The type of subscription (e.g., "Product").
*   `subscriptionResourceId`: The ID of the subscription resource.
*   `subscriberPartyId`: The ID of the party subscribed.
*   `deliverToContactMechId`: The contact mechanism for delivery.
*   `orderId`: The ID of the order that created the subscription.
*   `orderItemSeqId`: The sequence ID of the order item.
*   `productId`: The ID of the product.
*   `externalSubscriptionId`: An external ID for the subscription.
*   `resourceInstanceId`: An ID for a specific instance of the resource.
*   `description`: A description of the subscription.
*   `fromDate`: The start date of the subscription.
*   `thruDate`: The end date of the subscription.
*   `purchaseFromDate`: The date from which the subscription could be purchased.
*   `purchaseThruDate`: The date until which the subscription could be purchased.
*   `availableTime`: The duration of the subscription.
*   `availableTimeUomId`: The unit of measurement for `availableTime`.
*   `useTime`: The duration of each use.
*   `useTimeUomId`: The unit of measurement for `useTime`.
*   `useCountLimit`: The number of times the subscription can be used.

### 3. `SubscriptionDelivery`

This entity tracks the delivery of a subscription.

**Fields:**

*   `subscriptionId`: The ID of the subscription.
*   `dateSent`: The date the subscription was sent.
*   `communicationEventId`: The ID of the communication event.
*   `comments`: Any comments about the delivery.

### 4. `SubscriptionResource`

This entity defines a resource that can be subscribed to. It also defines the services that are called at different stages of the subscription lifecycle.

**Fields:**

*   `subscriptionResourceId`: The unique ID of the subscription resource.
*   `parentResourceId`: The ID of a parent resource.
*   `description`: A description of the resource.
*   `contentLocation`: The location of the resource's content.
*   `remoteResourceId`: The ID of a remote resource.
*   `initServiceName`: The service called to initialize a new subscription.
*   `renewServiceName`: The service called to renew a subscription.
*   `revokeAccessTime`: The time after which access is revoked.
*   `revokeAccessTimeUomId`: The unit of measurement for `revokeAccessTime`.
*   `revokeAccessServiceName`: The service called to revoke access.
*   `restoreAccessServiceName`: The service called to restore access.
*   `destroyTime`: The time after which the subscription is destroyed.
*   `destroyTimeUomId`: The unit of measurement for `destroyTime`.
*   `destroyServiceName`: The service called to destroy the subscription.

## Services

The subscription functionality is managed by a set of services defined in `SubscriptionServices.xml` and a SECA rule in `ProductSubscription.secas.xml`.

### `ProductSubscription.secas.xml`

This file contains a SECA (Service ECA) rule that triggers the subscription fulfillment process.

*   **`OrderApprovedFulfillSubscriptions`**: This rule is triggered after the `update#mantle.order.OrderHeader` service is called and the order status changes to "OrderApproved". It calls the `mantle.product.SubscriptionServices.fulfill#OrderSubscriptions` service to fulfill any subscriptions in the order.

### `SubscriptionServices.xml`

This file defines the services for managing the subscription lifecycle.

#### Interface Services

These services define the interface for subscription management.

*   `init#SubscriptionResource`: Initializes a new subscription.
*   `renew#SubscriptionResourceAccess`: Renews an existing subscription.
*   `revoke#SubscriptionResourceAccess`: Revokes access to a subscription.
*   `restore#SubscriptionResourceAccess`: Restores access to a subscription.
*   `destroy#SubscriptionResource`: Destroys a subscription.

#### Fulfillment Services

These services handle the fulfillment of subscriptions.

*   **`fulfill#OrderSubscriptions`**: This service is called when an order is approved. It iterates through the order parts and calls `fulfill#OrderPartSubscriptions` for each part.
*   **`fulfill#OrderPartSubscriptions`**: This service iterates through the order items in a part. If an item is a digital product with a `ProductSubscriptionResource`, it calls `fulfill#ProductSubscriptionResource` to create the subscription. It then creates an invoice for the fulfilled items and applies any payments.
*   **`fulfill#ProductSubscriptionResource`**: This service creates a `Subscription` record. It determines the start and end dates of the subscription and calls the `initServiceName` or `renewServiceName` defined on the `SubscriptionResource` to initialize or renew the subscription.
