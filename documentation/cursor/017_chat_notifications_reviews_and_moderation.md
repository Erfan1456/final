# Cursor Task 017 — Booking-Scoped Chat, In-App Notifications, Verified Reviews, and Admin Moderation

## Metadata

- Task ID: 017
- Task title: Booking-Scoped Chat, In-App Notifications, Verified Reviews, and Admin Moderation
- Date: 2026-08-26
- Git branch: main
- Repository root: D:\freelance\erfankhan_cse489\final
- Flutter project root: D:\freelance\erfankhan_cse489\final\project
- Status: SUCCESS

## Objective

Add booking-scoped customer/cleaner chat, a persistent in-app notification feed, verified completed-booking reviews, discovery rating aggregation, and admin review moderation without WebSockets, push providers, Firebase, or a transactional outbox. Do not commit.

## Exact Cursor Prompt

~~~~text
# TASK 017 — Booking-Scoped Chat, In-App Notifications, Verified Reviews, and Admin Moderation

Repository:

D:\freelance\erfankhan_cse489\final

TASK 016 must be committed before starting this task.

======================================================================
OBJECTIVE
======================================================================

The marketplace currently supports:

- authentication and secure refresh sessions;
- persisted role authorization;
- customer profiles and addresses;
- cleaner onboarding/admin approval;
- service offerings;
- cleaner availability;
- customer discovery and comparison;
- concurrency-aware bookings;
- booking lifecycle;
- payment ledger;
- development/test sandbox payment provider;
- signed payment webhooks;
- refunds;
- payment-aware booking cancellation;
- admin payment inspection.

TASK 017 must implement the next large post-booking trust and communication
vertical slice:

CHAT
- booking-scoped customer ↔ cleaner conversations;
- one conversation per booking;
- participant authorization;
- idempotent message sending;
- message history;
- unread/read state;
- REST polling for new messages;
- terminal-booking read-only behavior.

NOTIFICATIONS
- persistent in-app notification feed;
- unread counts;
- mark one read;
- mark all read;
- idempotent notification creation;
- notifications generated from important booking/payment/chat/review events;
- no push-notification provider yet.

REVIEWS
- customer review only for completed bookings;
- one review per booking;
- rating + optional comment;
- customer may update own review;
- only published reviews affect discovery;
- cleaner review list;
- discovery rating aggregate + review count;
- public cleaner review summaries;
- admin hide/unhide moderation.

FLUTTER
- booking chat for customer and cleaner;
- notifications center;
- unread notification badge/count;
- completed-booking review CTA/form;
- cleaner My Reviews;
- discovery rating/review integration;
- admin review moderation screens.

Do NOT implement:

- WebSockets;
- Firebase;
- push notifications;
- email notifications;
- SMS;
- file/image attachments;
- voice messages;
- video calls;
- message editing;
- message deletion;
- typing indicators;
- presence;
- read receipts per individual message;
- AI moderation;
- automated sentiment analysis;
- review replies;
- disputes;
- payouts;
- coupons;
- promotions.

No AI features.

======================================================================
NO NEW DIRECT DEPENDENCY POLICY
======================================================================

Expected:

BACKEND:
no new direct dependency

FLUTTER:
no new direct dependency

Reuse existing:

Backend:
- Dart Frog
- mongo_dart
- hashlib
- existing authentication/authorization/database architecture

Flutter:
- Dio
- Riverpod
- go_router
- Dart Timer
- existing authenticated Dio/session architecture

Do NOT add:

web_socket_channel
firebase_messaging
socket_io
intl
freezed
json_serializable
retrofit
another HTTP package
another router
another state-management system
another local-storage package

If a genuinely unavoidable new direct dependency is required:

STOP and report before adding it.

Do NOT run:

dart pub upgrade
flutter pub upgrade

======================================================================
EXPECTED BASELINE
======================================================================

After TASK 016 checkpoint:

Backend:

dart analyze:
clean

dart test:
398 passed

Flutter:

flutter analyze:
clean

flutter test:
244 passed

Verify these exact baselines before implementation.

======================================================================
COLLECTION — CONVERSATIONS
======================================================================

Create:

conversations

Document:

{
  "_id": ObjectId,
  "booking_id": ObjectId,
  "customer_user_id": ObjectId,
  "cleaner_user_id": ObjectId,
  "created_at": DateTime,
  "updated_at": DateTime,
  "last_message_at": DateTime?
}

One booking:

at most one conversation.

Do NOT store:

email
phone
address
password
token
payment credentials
full booking snapshot

inside the conversation.

Booking remains authoritative for participant relationship and lifecycle.

======================================================================
COLLECTION — CONVERSATION MEMBERS
======================================================================

Create:

conversation_members

Document:

{
  "_id": ObjectId,
  "conversation_id": ObjectId,
  "user_id": ObjectId,
  "role": String,
  "last_read_message_id": ObjectId?,
  "last_read_at": DateTime?,
  "created_at": DateTime,
  "updated_at": DateTime
}

Allowed member roles:

customer
cleaner

Do NOT allow:

admin

as a booking-chat participant in TASK 017.

Admin chat/dispute access is deferred.

Exactly two intended members:

booking.customer_user_id
booking.cleaner_user_id

======================================================================
CONVERSATION CREATION CONSISTENCY
======================================================================

Creating a conversation involves:

conversations
+
conversation_members

There is currently no general Mongo multi-document transaction architecture.

Therefore implement idempotent, repairable creation:

1. create/find conversation by unique booking_id;
2. upsert customer conversation member;
3. upsert cleaner conversation member;
4. repeated initialization repairs missing member rows safely.

Do NOT claim creation is transactionally atomic across collections.

Document this limitation.

======================================================================
COLLECTION — MESSAGES
======================================================================

Create:

messages

Document:

{
  "_id": ObjectId,
  "conversation_id": ObjectId,
  "sender_user_id": ObjectId,
  "sender_role": String,
  "body": String,
  "client_idempotency_key": String,
  "created_at": DateTime
}

Messages are immutable in TASK 017.

Do NOT store:

recipient email
recipient phone
customer address
password/token information

in a message.

======================================================================
MESSAGE VALIDATION
======================================================================

body:

required String.

Trim leading/trailing whitespace.

After trim:

1–2000 Unicode code points.

Allow:

normal text
newlines
tabs

Reject other control characters.

Plain text only.

Do not parse/store HTML.

Do not add Markdown rendering requirements.

======================================================================
MESSAGE IDEMPOTENCY
======================================================================

POST message requires:

Idempotency-Key

Validation:

16–128 ASCII
trim surrounding whitespace
reject control characters
do not lowercase.

Unique combination:

conversation_id
sender_user_id
client_idempotency_key

Same key from same sender/conversation:

if same normalized body:
return existing message as idempotent replay.

If body differs:

409
idempotency_key_reused

Correctness must rely on a unique Mongo index, not only a pre-read.

Duplicate-key race:

load existing
compare body
return replay or conflict.

======================================================================
CHAT BOOKING LIFECYCLE POLICY
======================================================================

Conversation may be created/read for a booking owned by the participant.

MESSAGE SENDING is allowed only when booking status is:

pending
confirmed
in_progress

Conversation becomes READ-ONLY when booking is:

completed
declined
cancelled

Attempt to send when read-only:

409
conversation_read_only

Existing messages remain readable.

Do NOT physically delete conversation/history when booking becomes terminal.

======================================================================
CHAT AUTHORIZATION
======================================================================

Never authorize conversation access using:

conversation id alone.

For every chat request:

1. verify Bearer JWT;
2. resolve current persisted active user;
3. load conversation;
4. require current user id equals either:
   customer_user_id
   OR
   cleaner_user_id;
5. verify booking relationship where application service requires it.

Unknown conversation OR non-member:

404
conversation_not_found

Do not return:

403 "belongs to someone else"

because that leaks existence.

Persisted user remains authoritative.

JWT role alone is not sufficient.

======================================================================
CHAT ROUTES
======================================================================

Add shared authenticated routes:

POST /api/v1/conversations/booking/[bookingId]

GET /api/v1/conversations

GET /api/v1/conversations/[conversationId]

GET /api/v1/conversations/[conversationId]/messages

POST /api/v1/conversations/[conversationId]/messages

POST /api/v1/conversations/[conversationId]/read

Allowed participants:

customer
cleaner

Admin:

forbidden.

POST booking conversation:

create-or-return conversation for authenticated booking participant.

First creation:
201

Existing:
200

======================================================================
CONVERSATION LIST
======================================================================

GET /api/v1/conversations

Return authenticated user's conversations.

Sort:

last_message_at descending
then _id descending

Conversation summary:

id
booking_id
other_party_display_name
other_party_role
booking_status
last_message_preview
last_message_at
unread_count

Do NOT expose:

other party email
phone
address
account status internals.

Display name:

Customer-facing:
cleaner profile full_name.

Cleaner-facing:
customer profile full_name if available;
otherwise "Customer".

Avoid N+1 queries.

Batch related profiles/messages/unread information where practical.

Page size expected small initially.

Use keyset pagination if pagination is implemented.

If unpaginated initially:

cap at 50 conversations.

Document decision.

======================================================================
MESSAGE HISTORY QUERY
======================================================================

GET /api/v1/conversations/[conversationId]/messages

Support:

limit
before
after

limit:

default 50
min 1
max 100

`before`:

message ObjectId cursor for older history.

`after`:

message ObjectId cursor for polling newer messages.

Do not allow both:

before
and
after

simultaneously.

If both:

400
invalid_message_cursor

Initial request with neither:

return latest 50 messages in chronological display order.

For before:

return older page suitable for prepend.

For after:

return newer messages suitable for polling append.

Use keyset queries.

Do NOT use offset/skip primary pagination.

======================================================================
MESSAGE RESPONSE
======================================================================

Safe message DTO:

id
conversation_id
sender_user_id
sender_role
body
created_at
is_mine

`is_mine` may be computed for current authenticated user.

Do NOT return:

client_idempotency_key

in normal API representation.

======================================================================
MARK CONVERSATION READ
======================================================================

POST /api/v1/conversations/[conversationId]/read

Body may optionally contain:

{
  "message_id": "..."
}

If omitted:

mark through latest message.

If supplied:

message must belong to conversation.

Update authenticated member only:

last_read_message_id
last_read_at

Never update the other participant's read state.

Do NOT expose fine-grained per-message read receipts to the sender yet.

Unread count is:

number of messages in conversation
where sender_user_id != current user
and message id is newer than last_read_message_id

Use practical bounded/query implementation.

======================================================================
REST POLLING POLICY
======================================================================

TASK 017 does NOT add WebSockets.

Flutter chat screen may poll:

GET messages?after=<lastMessageId>

approximately every:

5 seconds

ONLY while the chat screen is mounted/visible.

Requirements:

- one poll at a time;
- no overlapping requests;
- timer cancelled on dispose;
- polling stopped after authentication loss;
- errors during background poll do not repeatedly spam visible dialogs;
- manual send/load failures remain visible safely.

Document:

REST polling is an intentional first realtime approximation.

WebSocket/SSE infrastructure is deferred.

======================================================================
COLLECTION — NOTIFICATIONS
======================================================================

Create:

notifications

Document:

{
  "_id": ObjectId,
  "user_id": ObjectId,
  "type": String,
  "title": String,
  "body": String,
  "resource_type": String?,
  "resource_id": ObjectId?,
  "dedupe_key": String,
  "read_at": DateTime?,
  "created_at": DateTime
}

All notifications are:

in-app only.

No push/email/SMS.

======================================================================
NOTIFICATION TYPE ENUM
======================================================================

Create explicit enum/wire values for supported types such as:

booking_requested
booking_confirmed
booking_declined
booking_cancelled
job_started
job_completed
payment_paid
payment_failed
payment_refunded
message_received
review_received

Use clean domain names.

Do not scatter strings.

======================================================================
NOTIFICATION PRIVACY
======================================================================

Notification title/body must NEVER contain:

full service address
password/token
payment credentials
webhook data
Mongo ids not useful to user
customer/cleaner phone
private email
raw payment failure stack/provider payload

Examples should remain generic:

"New booking request"
"Your booking was confirmed"
"New message"
"Payment completed"
"New review received"

Safe cleaner/customer names may be used only when useful.

======================================================================
NOTIFICATION DEDUPLICATION
======================================================================

Every created notification requires deterministic:

dedupe_key

Unique per:

user_id + dedupe_key

Examples conceptually:

booking:<bookingId>:created
booking:<bookingId>:confirmed
booking:<bookingId>:declined
booking:<bookingId>:cancelled
booking:<bookingId>:started
booking:<bookingId>:completed
message:<messageId>
payment-event:<providerEventId>
review:<reviewId>:created

Do not rely on the examples as literal parsing requirements.

Duplicate creation:

return/expose no error to business workflow.

Treat as already delivered.

======================================================================
NOTIFICATION DELIVERY CONSISTENCY
======================================================================

TASK 017 does NOT introduce a distributed transactional outbox.

Primary booking/payment/message/review mutation remains authoritative.

Notification insert occurs AFTER successful primary mutation.

If notification creation fails unexpectedly:

- primary business operation remains successful;
- notification failure must not roll back booking/payment/message/review;
- do not expose raw DB failure to end user;
- record/report the limitation.

Notification creation itself must be idempotent.

Document explicitly:

cross-collection exactly-once notification delivery is NOT guaranteed yet.

Future option:

transactional outbox / queue worker.

Do NOT falsely claim exactly-once delivery.

======================================================================
NOTIFICATION APPLICATION SERVICE
======================================================================

Create:

NotificationService

or equivalent.

Responsibilities:

createIdempotentNotification
listForUser
unreadCount
markRead
markAllRead

Use authenticated user id for ownership.

Do not accept arbitrary user_id from HTTP body.

Introduce a narrow:

NotificationSink

interface if it improves integration/test isolation.

Business services should not directly construct Mongo notification documents.

======================================================================
NOTIFICATION ROUTES
======================================================================

Shared authenticated routes:

GET /api/v1/notifications

GET /api/v1/notifications/unread-count

POST /api/v1/notifications/[notificationId]/read

POST /api/v1/notifications/read-all

Available to active:

customer
cleaner
admin

No role-specific duplication.

Persisted current UserAccount must still be resolved.

======================================================================
NOTIFICATION LIST
======================================================================

GET /api/v1/notifications

Query:

unread
limit
after

unread:

optional bool

limit:

default 20
min 1
max 50

after:

notification ObjectId cursor

Sort:

_id descending

Use:

_id < after

No offset pagination.

Safe notification JSON only.

Unknown/not-owned notification on mark-read:

404
notification_not_found

======================================================================
NOTIFICATION EVENTS — BOOKING
======================================================================

Integrate idempotently.

Booking created:

recipient:
cleaner

type:
booking_requested

Cleaner accepts:

recipient:
customer

booking_confirmed

Cleaner declines:

recipient:
customer

booking_declined

Customer or cleaner cancels:

notify the OTHER booking participant

booking_cancelled

Cleaner starts:

recipient:
customer

job_started

Cleaner completes:

recipient:
customer

job_completed

Idempotent booking-create replay must NOT create duplicate notification.

======================================================================
NOTIFICATION EVENTS — PAYMENT
======================================================================

After a valid webhook transition:

paid:
notify customer

failed:
notify customer

fully refunded:
notify customer

partially refunded:
may use payment_refunded with clear body or another explicit enum if justified.

Duplicate webhook event:

must not duplicate notification.

Use provider event id/event metadata in dedupe key.

Do not notify on:

invalid signature
integrity mismatch
ignored unknown payment
stale event that causes no state change.

======================================================================
NOTIFICATION EVENTS — CHAT
======================================================================

After first successful message creation:

notify the OTHER conversation participant.

Type:

message_received

Dedupe:

message id.

Idempotent message replay:

must NOT create another notification.

Notification body may contain:

safe short preview

maximum:

120 Unicode code points.

Do not include hidden/private booking address or security information.

======================================================================
COLLECTION — REVIEWS
======================================================================

Create:

reviews

Document:

{
  "_id": ObjectId,
  "booking_id": ObjectId,
  "customer_user_id": ObjectId,
  "cleaner_user_id": ObjectId,
  "rating": int,
  "comment": String?,
  "moderation_status": String,
  "hidden_reason": String?,
  "hidden_by": ObjectId?,
  "hidden_at": DateTime?,
  "created_at": DateTime,
  "updated_at": DateTime
}

One review per booking.

Do NOT copy:

customer email
cleaner email
customer phone
cleaner phone
address
payment details
security fields

into review.

======================================================================
REVIEW MODERATION STATUS
======================================================================

Enum:

published
hidden

New review:

published

Admin may:

hide
unhide

Customer cannot choose moderation_status.

Cleaner cannot modify moderation state.

======================================================================
REVIEW ELIGIBILITY
======================================================================

Only authenticated booking CUSTOMER may create/update review.

Booking must:

exist
belong to customer
status == completed

Otherwise:

404 booking_not_found
or
409 review_not_allowed

Do not reveal foreign booking ownership.

Do NOT require:

payment status

for review in TASK 017.

Booking completion is the verification condition.

Response may expose:

verified_booking: true

as a computed customer/public field.

Do not persist a fake `verified_booking` boolean when booking relationship is
already authoritative.

======================================================================
REVIEW RATING
======================================================================

rating:

integer only

1–5 inclusive.

Reject:

double
string number
0
>5

======================================================================
REVIEW COMMENT
======================================================================

Optional.

Trim.

Empty:
null.

Maximum:

1000 Unicode code points.

Allow normal text/newline/tab.

Reject other control characters.

Plain text only.

Do not render arbitrary HTML.

======================================================================
CUSTOMER REVIEW CREATE / UPDATE
======================================================================

Use:

PUT /api/v1/customer/bookings/[bookingId]/review

Body:

{
  "rating": 5,
  "comment": "..."
}

If no review exists:

create
201

If review exists and belongs to same booking/customer:

update rating/comment
200

Preserve:

_id
booking_id
customer_user_id
cleaner_user_id
created_at
moderation metadata unless policy below changes it.

IMPORTANT moderation decision:

If a customer edits a review that is currently hidden:

keep it hidden.

Do NOT automatically republish hidden content.

Admin may explicitly unhide after moderation.

First review creation should trigger:

review_received

notification to cleaner.

Subsequent customer edits:

do NOT create repeated review_received notifications.

======================================================================
CUSTOMER REVIEW GET
======================================================================

GET /api/v1/customer/bookings/[bookingId]/review

If none:

200
{
  "success": true,
  "data": {
    "review": null
  }
}

If exists:

return own review including moderation_status.

Do not expose admin hidden reason to public discovery.

Customer may see a safe moderation note/reason if desired.

======================================================================
CLEANER REVIEW API
======================================================================

Add:

GET /api/v1/cleaner/reviews

Cleaner role only.

Query:

status
limit
after

status optional:

published
hidden

Default:

all

limit:
20 default
1–50

after:
review ObjectId cursor

Sort:
_id descending

Cleaner sees reviews belonging to their cleaner_user_id.

Safe fields:

rating
comment
moderation_status
created_at
updated_at
booking id if useful

Reviewer identity:

use neutral:

"Verified customer"

Do NOT expose:

customer email
phone
address.

Hidden reviews:

cleaner may see that moderation_status is hidden,
but do not expose internal admin identity unless clearly necessary.

======================================================================
ADMIN REVIEW MODERATION API
======================================================================

Add:

GET /api/v1/admin/reviews

GET /api/v1/admin/reviews/[reviewId]

POST /api/v1/admin/reviews/[reviewId]/hide

POST /api/v1/admin/reviews/[reviewId]/unhide

Admin role only.

======================================================================
ADMIN REVIEW LIST
======================================================================

Query:

status
rating
cleaner_user_id
limit
after

status optional:

published
hidden

rating optional:

1–5

limit:

default 20
1–50

after:

review ObjectId

Sort:

_id descending.

No offset pagination.

Return safe moderation DTO.

No customer security/private contact data.

======================================================================
HIDE REVIEW
======================================================================

POST /api/v1/admin/reviews/[reviewId]/hide

Body:

{
  "reason": "..."
}

Reason:

required
5–500 Unicode code points
trim
plain text
reject control characters.

Condition:

published
→ hidden

Set:

moderation_status = hidden
hidden_reason
hidden_by = current admin
hidden_at = now
updated_at = now

If already hidden:

either:

200 idempotent safe result

OR

409 invalid_review_state

Choose one deliberate policy and document/test it.

Preferred:

idempotent 200 if already hidden with the same stored state,
without overwriting original moderation reason automatically.

======================================================================
UNHIDE REVIEW
======================================================================

POST /api/v1/admin/reviews/[reviewId]/unhide

Condition:

hidden
→ published

Clear:

hidden_reason
hidden_by
hidden_at

Update:

updated_at

If already published:

idempotent 200 is acceptable.

======================================================================
REVIEW DISCOVERY PRIVACY
======================================================================

Customer discovery may expose ONLY:

rating
comment
created_at
verified_booking = true

Reviewer name:

"Verified customer"

Do NOT expose:

customer_user_id
customer profile id
customer email
customer phone
booking address
booking notes
payment data.

Admin/internal review DTO may contain ids needed for moderation.

Public DTO must be separate or explicitly shaped.

======================================================================
DISCOVERY RATING AGGREGATION
======================================================================

Update TASK 014 discovery.

Only reviews where:

moderation_status == published

count.

For each discoverable cleaner expose:

rating_average
review_count

rating_average:

double is acceptable because rating average is not money.

When no reviews:

rating_average = null
review_count = 0

Do NOT store denormalized rating counters on cleaner_profiles in TASK 017.

Compute/batch aggregate from reviews.

Reason:

avoid stale cross-document counters without transaction/outbox architecture.

Avoid N+1 review queries.

For discovery page <=50:

one aggregate/batch operation for visible cleaner ids is acceptable.

======================================================================
DISCOVERY DETAIL REVIEWS
======================================================================

Cleaner detail should include:

rating_average
review_count
reviews

Return latest:

10

published reviews.

Sort:

_id descending
or created_at descending with stable tie-breaker.

Each public review:

rating
comment
created_at
verified_booking: true
reviewer_display_name: "Verified customer"

No pagination for detail reviews yet.

A separate public review pagination endpoint is not required in TASK 017.

======================================================================
REVIEW NOTIFICATION
======================================================================

On FIRST successful review creation:

notify cleaner:

review_received

Dedupe key based on review id.

Customer review update:

no duplicate notification.

Admin hide/unhide:

no notification required in TASK 017.

======================================================================
DATABASE INDEXES
======================================================================

Add deliberate indexes.

CONVERSATIONS

1.
conversations_booking_unique

booking_id: 1

unique:
true

2.
conversations_customer_last_message

customer_user_id: 1
last_message_at: -1
_id: -1

3.
conversations_cleaner_last_message

cleaner_user_id: 1
last_message_at: -1
_id: -1

Evaluate whether both role-specific indexes are needed for chosen query
implementation.

Do not create redundant indexes without purpose.

CONVERSATION_MEMBERS

1.
conversation_members_conversation_user_unique

conversation_id: 1
user_id: 1

unique:
true

2.
conversation_members_user_conversation

user_id: 1
conversation_id: 1

MESSAGES

1.
messages_conversation_id_desc

conversation_id: 1
_id: -1

2.
messages_sender_idempotency_unique

conversation_id: 1
sender_user_id: 1
client_idempotency_key: 1

unique:
true

NOTIFICATIONS

1.
notifications_user_id_desc

user_id: 1
_id: -1

2.
notifications_user_read_id_desc

user_id: 1
read_at: 1
_id: -1

3.
notifications_user_dedupe_unique

user_id: 1
dedupe_key: 1

unique:
true

REVIEWS

1.
reviews_booking_unique

booking_id: 1

unique:
true

2.
reviews_cleaner_status_id_desc

cleaner_user_id: 1
moderation_status: 1
_id: -1

3.
reviews_customer_id_desc

customer_user_id: 1
_id: -1

4.
reviews_status_rating_id_desc

moderation_status: 1
rating: 1
_id: -1

Evaluate actual query usage.

Omit any demonstrably redundant index and document why.

======================================================================
COLLECTION NAMES / DATABASE TOOLING
======================================================================

Extend central collection constants with:

conversations
conversation_members
messages
notifications
reviews

Extend controlled database-index ensure.

Indexes must NOT be created in request middleware.

======================================================================
LIVE DATABASE POLICY
======================================================================

TASK 017 may mutate live Atlas ONLY through:

controlled index ensure.

It MUST NOT create live:

conversations
conversation members
messages
notifications
reviews
users
bookings
payments
addresses
availability
sessions

Do NOT use real accounts to test chat/reviews.

Automated tests:

fakes/in-memory seams only.

Do not dump private documents.

======================================================================
CONVERSATION REPOSITORY
======================================================================

Create narrow:

ConversationRepository

Responsibilities conceptually:

findById
findByBookingId
createForBooking
listForUser
touchLastMessage

No arbitrary update maps exposed to services.

======================================================================
CONVERSATION MEMBER REPOSITORY
======================================================================

Create:

ConversationMemberRepository

Responsibilities:

upsertMember
findMember
updateReadState

Use owner/member selectors.

======================================================================
MESSAGE REPOSITORY
======================================================================

Create:

MessageRepository

Responsibilities:

findBySenderIdempotency
create
latest
before
after
findByIdInConversation
countUnreadForMember
latestForConversationIds

Duplicate idempotency mapping explicit.

No arbitrary updates because messages immutable.

======================================================================
NOTIFICATION REPOSITORY
======================================================================

Create:

NotificationRepository

Responsibilities:

create
findByUserDedupe
listForUser
unreadCount
markReadOwned
markAllRead

Ownership selectors:

notification _id
AND user_id

Never find notification by id then trust client ownership separately if Mongo
can enforce owner selector.

======================================================================
REVIEW REPOSITORY
======================================================================

Create:

ReviewRepository

Responsibilities:

findByBooking
upsertCustomerReview
listForCleaner
adminPage
findById
hidePublished
unhideHidden
aggregateForCleanerIds
latestPublishedForCleaner

Review create/update ownership should remain booking/customer scoped.

Conditional moderation updates.

======================================================================
CHAT APPLICATION SERVICE
======================================================================

Create:

BookingConversationService

Responsibilities:

createOrGetForBooking
listConversations
getConversation
listMessages
sendMessage
markRead

HTTP independent.

Compose:

BookingRepository
ConversationRepository
ConversationMemberRepository
MessageRepository
CustomerProfileRepository
CleanerProfileRepository
NotificationService

Do not put business rules in route handlers.

======================================================================
REVIEW APPLICATION SERVICES
======================================================================

Create focused services:

CustomerReviewService

CleanerReviewService

AdminReviewModerationService

or equivalent.

Customer service:

getForBooking
upsertForCompletedBooking

Cleaner:

listOwnReviews

Admin:

list
detail
hide
unhide

DiscoveryService composes review aggregate repository.

======================================================================
SHARED CURRENT-USER AUTHORIZATION
======================================================================

Notifications and conversations are not simply customer-only or cleaner-only.

Reuse existing:

JWT verification
→ persisted UserAccount resolution
→ active-state check.

Create/reuse a middleware boundary that can authenticate:

customer
cleaner
admin

without authorizing solely from stale JWT role.

For conversation operations:

service then requires role:
customer or cleaner

and booking membership.

For notifications:

all three active roles allowed.

Do not duplicate Bearer JWT code.

======================================================================
BACKEND HTTP ERRORS
======================================================================

Add safe mappings where needed:

conversation_not_found
conversation_read_only
invalid_message
invalid_message_cursor
notification_not_found
review_not_allowed
review_not_found
invalid_review_rating
invalid_review_comment
invalid_review_reason
invalid_review_state

Reuse:

idempotency_key_required
invalid_idempotency_key
idempotency_key_reused

where appropriate.

No raw Mongo exception text.

======================================================================
BACKEND TESTS — CHAT AUTHORIZATION
======================================================================

Test:

booking customer can create/get conversation
booking cleaner can create/get conversation
foreign customer → 404
foreign cleaner → 404
admin → forbidden
deleted user after JWT → unauthorized
inactive user → account unavailable
stale JWT role cannot bypass persisted role

Conversation initialize repeated:

same conversation
members repaired/idempotent
no duplicate conversation.

======================================================================
BACKEND TESTS — MESSAGES
======================================================================

Test:

send pending booking
send confirmed
send in_progress
completed read-only
cancelled read-only
declined read-only

message trim/validation
newline allowed
tab allowed
control rejected
max 2000

Idempotency:

first 201
same key/body replay 200
same key/different body 409
duplicate race handling

sender derived from auth
body cannot override sender
foreign conversation 404

Pagination:

initial latest
before
after
both cursor params invalid
stable ordering

Read state:

mark latest
mark supplied message
foreign message rejected
other member unchanged

No Atlas.

======================================================================
BACKEND TESTS — NOTIFICATIONS
======================================================================

Test repository/service:

create
dedupe
list
cursor
unread filter
unread count
mark one
foreign mark → 404
mark all

Event integration:

booking creation → cleaner once
booking accept → customer once
decline → customer once
cancel → other participant once
start → customer
complete → customer

payment paid → customer
payment failed → customer
refund → customer

message → other participant
message replay no duplicate

review creation → cleaner
review edit no duplicate

Duplicate webhook → no duplicate notification.

Unexpected notification write failure:

primary business result remains successful.

No secret/private fields in notification bodies.

======================================================================
BACKEND TESTS — REVIEWS
======================================================================

Customer:

completed booking create
first create 201
update existing 200
pending booking rejected
confirmed rejected
in_progress rejected
cancelled rejected
foreign booking hidden
rating 1 allowed
rating 5 allowed
0 rejected
6 rejected
double rejected
string rejected
comment trimming
empty comment null
comment max
control rejection

one review per booking
duplicate race safe

Hidden review customer edit:

content updates
moderation remains hidden

Cleaner:

own review list
published
hidden
pagination
foreign reviews excluded
no customer email/phone/address

Admin:

customer/cleaner forbidden
admin allowed
list filters
detail
hide
hide idempotency policy
unhide
reason validation
hidden metadata
safe public/internal separation

======================================================================
BACKEND TESTS — DISCOVERY REVIEWS
======================================================================

Test:

no reviews:
rating_average null
review_count 0

one published review
multiple average
hidden review excluded
customer-edited published review reflected
cleaner page aggregate batched
no N+1 review query
detail returns latest 10
detail excludes hidden reviews
public review reviewer name == Verified customer
no customer ids/contact/address/payment fields exposed.

======================================================================
BACKEND TESTS — INDEX SPECS
======================================================================

Test exact:

collection
index name
keys
unique options

for TASK 017 indexes.

No Atlas.

======================================================================
FLUTTER CHAT MODELS
======================================================================

Create:

ConversationSummary
ConversationDetail
ChatMessage

Fields should mirror safe server DTOs only.

Do NOT expose:

client idempotency key
email
phone
address
tokens.

======================================================================
FLUTTER CHAT API
======================================================================

Use authenticated Dio.

Operations:

createOrGetConversationForBooking
listConversations
getConversation
getMessages
sendMessage
markRead

Message send:

Idempotency-Key

Generate securely:

Random.secure()

at least 128 bits.

One logical send retains key through network/auth retry.

New user send:

new key.

Do not store chat idempotency keys in secure auth storage.

======================================================================
FLUTTER CHAT CONTROLLER
======================================================================

Focused Riverpod controller.

State supports:

initial loading
loaded messages
loading older
sending
background polling
safe error
read-only conversation

Operations:

load
loadOlder
send
markRead
startPolling
stopPolling

Polling:

about every 5 seconds
GET after latest message id
one request at a time
cancel timer on dispose.

Do not put Timer in widget without lifecycle cleanup.

Do not put chat state into AuthController.

======================================================================
FLUTTER CHAT ROUTES
======================================================================

Add:

/customer/bookings/:bookingId/chat

/cleaner/bookings/:bookingId/chat

Route may:

initialize conversation
then show ChatScreen

or navigate with conversation id internally.

Customer role only on customer path.

Cleaner role only on cleaner path.

Admin redirected to admin home.

Backend remains authoritative.

======================================================================
CHAT SCREEN
======================================================================

Create reusable:

BookingChatScreen

Show:

other party display name
booking/status context
message list
sender distinction
timestamps
composer

If conversation writable:

text field
Send

If read-only:

hide/disable composer

show:

"This conversation is read-only because the booking is closed."

No:

attachments
typing indicator
online presence
message editing/deleting.

After successful send:

append message
clear composer
mark appropriate read state.

When screen loads/new messages arrive:

mark read appropriately.

======================================================================
BOOKING UI CHAT INTEGRATION
======================================================================

Customer booking detail:

show:

Message Cleaner

when conversation can be viewed.

Cleaner booking detail:

show:

Message Customer

Conversation remains viewable after terminal booking.

Do not show personal email/phone.

======================================================================
FLUTTER NOTIFICATION MODEL
======================================================================

Create:

AppNotification
NotificationType

Fields:

id
type
title
body
resourceType
resourceId
readAt
createdAt

Unknown notification type:

map to safe `unknown`
rather than crash.

======================================================================
FLUTTER NOTIFICATION API
======================================================================

Use authenticated Dio.

Operations:

list
unreadCount
markRead
markAllRead

No local database dependency.

======================================================================
FLUTTER NOTIFICATION CONTROLLER
======================================================================

Focused Riverpod controller.

Support:

first load
load more
unread-only filter
mark one
mark all
unread count
safe error

After mark read:

local list/count remains coherent.

Do not require full app restart.

======================================================================
NOTIFICATIONS ROUTE / UI
======================================================================

Shared route:

/notifications

Accessible to authenticated:

customer
cleaner
admin

Create:

NotificationCenterScreen

Show:

title
body
timestamp
read/unread state

Actions:

mark one read
mark all read
load more
unread filter

Tap notification:

when resource is recognized:

booking-related:
navigate to role-appropriate booking detail.

message:
navigate to role-appropriate booking chat if resource mapping is available.

payment:
customer booking payment/detail if user customer.

review_received:
cleaner My Reviews.

If navigation target cannot be safely resolved:

mark read and remain in notification center.

Do not trust arbitrary server route strings.

Use explicit resource type mapping.

======================================================================
NOTIFICATION HOME INTEGRATION
======================================================================

CustomerHomeScreen:

Notifications
with unread count when available.

CleanerHomeScreen:

Notifications
with unread count.

AdminHomeScreen:

Notifications
with unread count.

A simple text badge/count is sufficient.

Do NOT implement OS push badges.

======================================================================
FLUTTER REVIEW MODELS
======================================================================

Create:

ReviewModerationStatus
CustomerReview
CleanerReview
PublicCleanerReview
AdminReviewSummary
AdminReviewDetail

Keep public review model separate enough to prevent leaking internal fields.

======================================================================
FLUTTER REVIEW API
======================================================================

Customer:

getForBooking
upsertReview

Cleaner:

listReviews

Admin:

listReviews
getReview
hideReview
unhideReview

Discovery parsing updated for:

ratingAverage
reviewCount
public reviews.

Use authenticated Dio for customer/cleaner/admin review APIs.

Discovery remains existing authenticated customer Dio.

======================================================================
CUSTOMER REVIEW CONTROLLER
======================================================================

Focused controller.

Support:

load existing
create/update
saving
safe error

No AuthController pollution.

======================================================================
CLEANER REVIEWS CONTROLLER
======================================================================

Support:

load
filter
pagination
safe error

======================================================================
ADMIN REVIEW CONTROLLER
======================================================================

Support:

list
filter
pagination
detail
hide
unhide
safe errors

After moderation:

list/detail state must update coherently.

======================================================================
CUSTOMER BOOKING DETAIL REVIEW UX
======================================================================

If booking status:

completed

show:

Leave Review

if none.

If existing:

Edit Review

Do not show review CTA for:

pending
confirmed
in_progress
cancelled
declined.

======================================================================
CUSTOMER REVIEW SCREEN
======================================================================

Route:

/customer/bookings/:bookingId/review

Create:

CustomerReviewScreen

Show:

service
cleaner display name if already available
rating selector 1–5
comment optional

Use simple Material controls.

Do not add rating-widget dependency.

Five tappable stars/icons or radio-like controls using core Flutter are fine.

If existing hidden review:

show safe moderation state.

Editing hidden review:

must not imply edit automatically republishes it.

======================================================================
CLEANER MY REVIEWS
======================================================================

Route:

/cleaner/reviews

Add to approved CleanerHomeScreen:

My Reviews

Create:

CleanerReviewsScreen

Show:

rating
comment
status
date

Reviewer:

Verified customer

Filters:

All
Published
Hidden

Load More.

No customer identity/contact data.

======================================================================
DISCOVERY UI REVIEW INTEGRATION
======================================================================

CleanerDiscoveryScreen cards:

show:

rating average
review count

Examples:

4.7 ★ (23 reviews)

If no reviews:

No reviews yet

Do not fabricate ratings.

CleanerDiscoveryDetailScreen:

show aggregate rating/count
+
latest published review cards

Each:

rating
comment
date
"Verified customer"

Do not show customer identities.

Comparison screen:

add rating average
review count

No fake score/rank.

======================================================================
ADMIN REVIEW ROUTES
======================================================================

Flutter:

/admin/reviews
/admin/reviews/:reviewId

AdminHomeScreen:

Review Moderation

======================================================================
ADMIN REVIEW LIST SCREEN
======================================================================

Show:

rating
comment excerpt
status
cleaner id/name if safe data available
created time

Filters:

Published
Hidden
Rating

Load More.

======================================================================
ADMIN REVIEW DETAIL SCREEN
======================================================================

Show:

full review text
rating
moderation status
booking id
cleaner id
customer id only if backend intentionally exposes for moderation
timestamps
hidden reason/status

Actions:

Hide
Unhide

Hide dialog requires reason.

No editing customer review content.

======================================================================
FLUTTER ERROR MAPPING
======================================================================

Add safe mappings:

conversation_not_found
conversation_read_only
invalid_message
invalid_message_cursor
notification_not_found
review_not_allowed
review_not_found
invalid_review_rating
invalid_review_comment
invalid_review_reason
invalid_review_state

Reuse idempotency mappings.

Do not show:

DioException.toString()
Mongo errors
stack traces
backend secrets.

======================================================================
FLUTTER TESTS — CHAT
======================================================================

Models/API:

parse conversation
parse message
create conversation
send has Idempotency-Key
auth refresh retains same message key
same logical retry behavior
pagination before
poll after
safe errors

Controller:

load
send
duplicate send guard
load older
poll append
prevent overlapping poll
poll error non-spam
mark read
read-only
dispose cancels timer

Widgets:

customer Message Cleaner
cleaner Message Customer
message rendering
mine vs other
composer
send loading
terminal read-only
no email/phone
older-message loading.

No real network/timer leak.

======================================================================
FLUTTER TESTS — NOTIFICATIONS
======================================================================

API/models:

list
unread count
mark
mark all
unknown type safe

Controller:

load
pagination
unread filter
mark one
mark all
count coherence
safe errors

Widgets:

customer home unread link/count
cleaner home
admin home
notification list
unread styling
mark all
tap known resource navigation
unknown resource safe behavior.

======================================================================
FLUTTER TESTS — REVIEWS
======================================================================

Customer:

completed booking CTA
non-completed no CTA
load none
load existing
rating validation
comment
create
update
hidden-state message
safe error

Cleaner:

My Reviews
published/hidden filters
Verified customer label
pagination
no customer email/phone

Discovery:

aggregate display
no reviews state
detail public reviews
hidden not represented
comparison rating/count

Admin:

Review Moderation home entry
list
filters
detail
hide dialog/reason validation
unhide
safe error.

======================================================================
FLUTTER ROUTER TESTS
======================================================================

Customer allowed:

customer booking chat
customer review
notifications

Cleaner allowed:

cleaner booking chat
cleaner reviews
notifications

Admin allowed:

admin reviews
notifications

Admin forbidden:

booking conversation participant routes

Customer/cleaner forbidden:

admin moderation

Cross-role booking chat routes redirect to own home.

Logout/session expiry:

login.

All existing payment/booking/discovery/onboarding/profile routes remain green.

======================================================================
BACKEND INTEGRATION — BOOKING SERVICES
======================================================================

Integrate notifications into existing booking operations through a narrow
NotificationSink/NotificationService.

Important:

Do NOT rewrite booking state machine.

Do NOT weaken conditional transitions.

Do NOT make successful booking operation fail solely because notification write
failed.

Tests must preserve TASK 015 behavior.

======================================================================
BACKEND INTEGRATION — PAYMENT WEBHOOK
======================================================================

On ACTUAL successful payment state change:

notify customer.

Do not notify on:

duplicate event no-op
stale ignored event
integrity mismatch
invalid signature

Do not modify existing webhook security/idempotency behavior.

======================================================================
BACKEND INTEGRATION — DISCOVERY
======================================================================

Extend discovery result DTOs with:

rating_average
review_count

Detail adds latest 10 published reviews.

Do not expose review internal ids if unnecessary.

Avoid N+1 queries.

Preserve:

active cleaner
approved cleaner
active service/offering
availability reservation filters.

======================================================================
SECURITY AUDIT
======================================================================

CHAT

Confirm:

- conversation membership derived from booking/authenticated user;
- admin cannot silently read private conversations;
- sender identity cannot be overridden by body;
- foreign conversation returns 404;
- message idempotency prevents retry duplicates;
- terminal booking is read-only;
- no email/phone/address/token leakage;
- polling uses authenticated Dio.

NOTIFICATIONS

Confirm:

- ownership by persisted current user;
- body cannot specify user_id;
- deterministic dedupe;
- notification failures do not corrupt primary business state;
- no full address/security/payment secrets;
- no arbitrary navigation URLs trusted by Flutter.

REVIEWS

Confirm:

- only completed booking customer can review;
- cleaner cannot review themselves through API;
- one review per booking;
- customer cannot change cleaner id/customer id/moderation;
- hidden reviews excluded from public discovery;
- public reviewer identity neutral;
- admin moderation role-protected;
- no customer contact/address/payment data public.

GLOBAL

Confirm:

- existing JWT persisted-role authorization still intact;
- no new auth stack;
- no password/token logging;
- no MONGODB_URI in Flutter;
- no ACCESS_TOKEN_SECRET in Flutter;
- no SANDBOX_PAYMENT_WEBHOOK_SECRET in Flutter;
- backend/.env ignored.

======================================================================
DOCUMENTATION — DATABASE
======================================================================

Create:

documentation/database/conversations-collection.md

documentation/database/conversation-members-collection.md

documentation/database/messages-collection.md

documentation/database/notifications-collection.md

documentation/database/reviews-collection.md

Document:

fields
ownership
indexes
privacy
lifecycle
idempotency
read-state design
notification dedupe
review moderation
non-transactional limitations.

======================================================================
DOCUMENTATION — CHAT API
======================================================================

Create:

documentation/api/chat-api.md

Document:

conversation routes
message routes
Idempotency-Key
pagination
polling after cursor
read state
booking lifecycle restrictions
privacy/errors.

======================================================================
DOCUMENTATION — NOTIFICATION API
======================================================================

Create:

documentation/api/notification-api.md

Document:

list
unread
mark read
mark all
pagination
notification types
resource linking
dedupe behavior
in-app-only limitation.

======================================================================
DOCUMENTATION — REVIEW API
======================================================================

Create:

documentation/api/review-api.md

Document:

customer review
cleaner list
admin moderation
discovery aggregates
public privacy
rating/comment validation
status/errors.

======================================================================
DOCUMENTATION — ARCHITECTURE
======================================================================

Create:

documentation/architecture/chat-notifications-and-reviews.md

Document flows:

BOOKING CHAT

Authenticated participant
→ booking membership
→ conversation
→ message idempotency
→ message persist
→ best-effort idempotent notification
→ Flutter polling

NOTIFICATIONS

domain transition
→ NotificationService
→ dedupe
→ notification feed

Explain:

notification insert is cross-document best-effort;
no transactional outbox yet.

REVIEWS

completed booking
→ customer review
→ published review
→ aggregate discovery query
→ admin moderation

Explain:

why aggregates are computed rather than stored;
why hidden reviews do not count;
why public reviewer identity is neutral.

======================================================================
ADR-015
======================================================================

Create:

documentation/decisions/ADR-015-chat-notifications-and-verified-reviews.md

Required:

# ADR-015 — Booking-Scoped Chat, In-App Notifications, and Verified Reviews

## Status
Accepted

## Context
## Decision
## Alternatives Considered
## Consequences
## Security
## Deferred Decisions

Decision must cover:

- one conversation per booking;
- customer+cleaner members only;
- idempotent repairable conversation initialization;
- immutable text messages;
- message Idempotency-Key;
- booking lifecycle controls message writing;
- REST polling instead of WebSockets;
- member read cursor;
- persistent in-app notifications;
- deterministic notification dedupe;
- best-effort cross-document notification creation;
- one verified review per completed booking;
- review moderation published/hidden;
- hidden reviews excluded from discovery;
- computed rating aggregates;
- neutral Verified customer public identity;
- admin moderation.

Alternatives:

### Global direct messages independent of booking
Rejected because chat should be tied to marketplace relationship and privacy.

### WebSockets immediately
Deferred because REST polling can exercise conversation semantics without new
realtime infrastructure/dependencies.

### Editable/deletable messages
Deferred to preserve simpler audit/history semantics.

### Push notifications now
Deferred because external push provider/device-token management is not yet
configured.

### Transactional notification outbox now
Deferred; current notifications are idempotent best-effort side effects and
the limitation is explicit.

### Stored cleaner rating_average/review_count
Not selected because cross-document aggregate updates could become stale
without transaction/outbox infrastructure.

### Allow reviews before completion
Rejected because review must represent a verified completed service.

### Expose customer identity publicly with review
Rejected for privacy.

Deferred:

WebSockets/SSE
push notifications
email/SMS
attachments
message moderation
typing/presence
admin dispute-chat access
review replies
review reporting
appeals
transactional outbox
stored rating aggregates
review analytics.

======================================================================
DOCUMENTATION INDEX UPDATES
======================================================================

Update as necessary:

documentation/README.md
documentation/api/README.md
documentation/database/README.md
documentation/architecture/README.md
documentation/decisions/README.md

documentation/architecture/backend-api-architecture.md
documentation/architecture/flutter-client-architecture.md
documentation/architecture/booking-reservation-and-lifecycle.md
documentation/architecture/payment-processing-and-webhooks.md

backend/README.md
project/README.md
README.md

Do not claim:

WebSockets
push notifications
AI moderation
disputes
payouts

exist.

======================================================================
TASK EXECUTION
======================================================================

STEP 1 — CLEAN CHECKPOINT

From repository root:

git rev-parse --show-toplevel
git branch --show-current
git status
git status --short
git log -10 --oneline

Expected:

root:
D:\freelance\erfankhan_cse489\final

branch:
main

working tree:
clean

latest commit:
TASK 016 checkpoint

Verify:

documentation/cursor/016_payment_ledger_webhooks_and_admin_transactions.md

Status:
SUCCESS

Verify:

backend/.env ignored:

git check-ignore -v backend/.env

If tree is not clean:

STOP.

======================================================================
STEP 2 — BACKEND BASELINE

From backend/:

dart pub get
dart analyze
dart test
dart_frog list

Expected:

398 passed
0 failed

If not:

STOP.

======================================================================
STEP 3 — FLUTTER BASELINE

From project/:

flutter pub get
flutter analyze
flutter test

Expected:

244 passed

If not:

STOP.

======================================================================
STEP 4 — DEPENDENCY AUDIT

Confirm no new direct package is required.

If one appears necessary:

STOP before adding it.

======================================================================
STEP 5 — CHAT DOMAIN / DATA

Implement:

Conversation
ConversationMember
ChatMessage

validation
safe DTOs
repositories
index specs

Add focused tests.

======================================================================
STEP 6 — CHAT APPLICATION SERVICE

Implement:

BookingConversationService

conversation initialization
membership
listing
message history
idempotent send
read cursor
terminal read-only behavior

Add comprehensive tests.

======================================================================
STEP 7 — NOTIFICATION DOMAIN / DATA

Implement:

AppNotification
NotificationType
NotificationRepository
NotificationService

dedupe
list
unread count
mark read
mark all

Add tests.

======================================================================
STEP 8 — REVIEW DOMAIN / DATA

Implement:

Review
ReviewModerationStatus
validation
ReviewRepository
safe customer/cleaner/admin/public DTOs

Add tests.

======================================================================
STEP 9 — REVIEW SERVICES

Implement:

CustomerReviewService
CleanerReviewService
AdminReviewModerationService

Add tests.

======================================================================
STEP 10 — DOMAIN NOTIFICATION INTEGRATION

Integrate notification sink into:

booking creation/transitions
payment webhook applied transitions
chat message creation
first review creation

Preserve existing primary state machines.

Add regression tests.

======================================================================
STEP 11 — DISCOVERY REVIEW INTEGRATION

Add:

rating_average
review_count
latest public reviews

Avoid N+1.

Add discovery regression tests.

======================================================================
STEP 12 — BACKEND ROUTES

Implement:

conversation routes
notification routes
customer review route
cleaner review route
admin review routes

Thin handlers.

No direct Mongo queries in route handlers.

======================================================================
STEP 13 — BACKEND PRE-LIVE VERIFICATION

Run:

dart format .
dart analyze
dart test
dart_frog list

All must pass.

Record exact test count and complete route list.

Only then perform live index ensure.

======================================================================
STEP 14 — LIVE INDEX ENSURE

Run existing controlled index tool.

Ensure TASK 017 indexes.

Verify metadata.

Do NOT create conversation/message/notification/review documents.

======================================================================
STEP 15 — FLUTTER CHAT DATA / STATE

Implement:

models
API
controller
polling lifecycle
idempotency

using authenticated Dio.

======================================================================
STEP 16 — FLUTTER NOTIFICATION DATA / STATE

Implement:

models
API
controller
unread count
notification resource navigation mapping.

======================================================================
STEP 17 — FLUTTER REVIEW DATA / STATE

Implement:

customer
cleaner
admin
discovery review models/APIs/controllers.

======================================================================
STEP 18 — FLUTTER ROUTING

Add:

customer chat
cleaner chat
notifications
customer review
cleaner reviews
admin review moderation

Preserve all previous role/auth guards.

======================================================================
STEP 19 — CHAT UI

Implement:

BookingChatScreen
booking-detail chat actions

REST polling.

No WebSocket.

======================================================================
STEP 20 — NOTIFICATION UI

Implement:

NotificationCenterScreen
unread links/counts on role homes
resource navigation.

======================================================================
STEP 21 — REVIEW UI

Implement:

CustomerReviewScreen
CleanerReviewsScreen
admin moderation screens
discovery aggregate/review display.

======================================================================
STEP 22 — FLUTTER TESTS

Add comprehensive:

API
controller
polling
router
widget

tests.

No real network.

Then run:

dart format lib test
flutter analyze
flutter test

Record exact count.

======================================================================
STEP 23 — ANDROID DEBUG BUILD

Run:

flutter build apk --debug

Must succeed.

No release signing/security changes.

======================================================================
STEP 24 — SAFE LIVE BACKEND VERIFICATION

Start backend only long enough for:

GET /
GET /api/v1/health
GET /api/v1/ready
GET /api/v1/services

Expected:

200

Do NOT invoke live:

conversation
message
notification
review
admin moderation
protected discovery

routes against Atlas.

No live application fixtures.

Stop server afterward.

======================================================================
STEP 25 — LIVE DATA SAFETY

Confirm:

only index metadata was live-mutated.

No live:

conversation
member
message
notification
review

documents created/updated/deleted.

No private document dumps.

======================================================================
STEP 26 — SECURITY AUDIT

Perform every CHAT / NOTIFICATION / REVIEW / GLOBAL security check above.

Regression test:

TASK 012 auth
TASK 013 persisted role
TASK 014 approved cleaner
TASK 015 booking reservation
TASK 016 payment/webhook

must remain green.

======================================================================
STEP 27 — DOCUMENTATION

Create:

documentation/database/conversations-collection.md
documentation/database/conversation-members-collection.md
documentation/database/messages-collection.md
documentation/database/notifications-collection.md
documentation/database/reviews-collection.md

documentation/api/chat-api.md
documentation/api/notification-api.md
documentation/api/review-api.md

documentation/architecture/chat-notifications-and-reviews.md

documentation/decisions/ADR-015-chat-notifications-and-verified-reviews.md

Update documentation indexes/README files.

======================================================================
STEP 28 — FINAL BACKEND VERIFICATION

From backend/:

dart analyze
dart test
dart_frog list

All green.

Record exact count/routes.

======================================================================
STEP 29 — FINAL FLUTTER VERIFICATION

From project/:

flutter analyze
flutter test
flutter build apk --debug

All green.

Record exact count.

======================================================================
STEP 30 — FINAL GIT REVIEW

From root:

git status --short
git check-ignore -v backend/.env

Inspect:

git diff -- backend/
git diff -- project/
git diff -- documentation/
git diff -- README.md

Confirm no:

backend/.env
MONGODB_URI
ACCESS_TOKEN_SECRET
SANDBOX_PAYMENT_WEBHOOK_SECRET
JWT
refresh token
password
private Atlas data
APK
build directory
SDK artifact
unrelated generated tooling file

is tracked.

If `project/devtools_options.yaml` appears again only from Flutter tooling and is
not intentionally part of project policy:

remove it before final report.

Do NOT stage.

======================================================================
STEP 31 — TASK REPORT

Create:

documentation/cursor/017_chat_notifications_reviews_and_moderation.md

Use existing task report template.

The report MUST contain the COMPLETE EXACT TASK 017 prompt under:

## Exact Cursor Prompt

Document:

- TASK 016 checkpoint;
- baseline counts;
- dependency audit;
- conversation schema;
- member schema;
- message schema;
- conversation repair behavior;
- participant authorization;
- chat lifecycle;
- message idempotency;
- message pagination;
- REST polling;
- notification schema;
- notification types;
- dedupe;
- event integrations;
- notification consistency limitation;
- review schema;
- review eligibility;
- moderation;
- review aggregate strategy;
- public review privacy;
- repositories/services;
- backend routes;
- indexes + live metadata ensure;
- Flutter chat;
- Flutter notification center;
- Flutter review flows;
- discovery integration;
- admin moderation;
- backend test count;
- Flutter test count;
- debug APK;
- safe live GETs;
- security audit;
- live data safety;
- files created;
- files modified;
- files deleted;
- warnings;
- final Git status.

Never include:

backend/.env
MONGODB_URI
ACCESS_TOKEN_SECRET
SANDBOX_PAYMENT_WEBHOOK_SECRET
password
JWT
refresh token
payment credentials
real messages
real notification content
real reviews
private Atlas records.

======================================================================
STEP 32 — DO NOT COMMIT

Do NOT:

git add
git commit
git push

Leave TASK 017 completely uncommitted for ChatGPT review.

======================================================================
FINAL RESPONSE FORMAT
======================================================================

Respond exactly:

# TASK 017 RESULT

## Status

SUCCESS
PARTIAL
FAILED

## Pre-Task Verification

Report:
repository
branch
clean TASK 016 checkpoint
backend baseline
Flutter baseline
.env ignored

## Dependencies

Confirm no new direct packages.

## Conversations

Describe one-conversation-per-booking design and repairable member creation.

## Chat Authorization

Describe booking participant enforcement and foreign-resource privacy.

## Messages

Describe immutable text, validation, and sender ownership.

## Message Idempotency

Describe Idempotency-Key and race handling.

## Chat Lifecycle

Describe writable vs read-only booking states.

## Message Pagination

Describe initial/before/after keyset behavior.

## REST Polling

Describe Flutter 5-second visible-screen polling and lifecycle cleanup.

## Notifications

Describe persistent in-app feed, unread state, and pagination.

## Notification Dedupe

Describe user+dedupe-key uniqueness.

## Notification Integrations

Describe booking/payment/chat/review events.

## Notification Consistency

Explicitly state best-effort cross-document behavior and no outbox claim.

## Reviews

Describe verified completed-booking customer review behavior.

## Review Moderation

Describe published/hidden admin workflow.

## Discovery Review Integration

Describe aggregate rating/count and latest public reviews.

## Discovery Review Privacy

Confirm neutral Verified customer identity and no customer private data.

## MongoDB Indexes

List actual TASK 017 indexes and live ensure result.

Explain deliberately omitted redundant indexes.

## Backend Tests

Report:
dart analyze
exact passing test count
Atlas-free automated tests

## Backend Routes

Provide complete dart_frog list.

## Flutter Chat Experience

Describe customer/cleaner chat and terminal read-only behavior.

## Flutter Notification Experience

Describe notification center/unread count/resource navigation.

## Flutter Customer Review Experience

Describe completed-booking create/edit flow.

## Flutter Cleaner Review Experience

Describe My Reviews.

## Flutter Admin Moderation Experience

Describe review list/detail/hide/unhide.

## Flutter Discovery Experience

Describe rating and review display.

## Flutter State

Describe focused Riverpod controllers.

## Flutter Routing

Describe new shared/role-protected routes.

## Flutter Tests

Report exact count and major coverage.

## Flutter Static Analysis

Report result.

## Android Debug Build

Report result.

## Live Backend Verification

Report only:

GET /
GET /api/v1/health
GET /api/v1/ready
GET /api/v1/services

Confirm no protected TASK 017 route invoked live.

## Live Data Safety

Confirm only index metadata live-mutated.

## Files Created

List.

## Files Modified

List.

## Files Deleted

List.

## Documentation

Confirm creation of all TASK 017 docs and cursor report.

## Security Verification

Confirm:

chat ownership
message sender ownership
notification ownership
review ownership
admin moderation
public review privacy
no private contact/address leaks
existing auth/payment security intact
no secrets in Flutter
.env ignored.

## Git Status

Provide final git status --short.

## Issues / Warnings

List every remaining issue.

## Final Statement

State whether booking-scoped chat + persistent notifications + verified reviews
+ discovery rating integration + admin review moderation are complete and
ready for ChatGPT review.

Do NOT implement WebSockets.

Do NOT implement push notifications.

Do NOT implement disputes.

Do NOT implement payouts.

Do NOT begin TASK 018.

Start TASK 017 now.
~~~~

## Power-Loss Recovery Note

An unexpected machine power loss occurred while TASK 017 was in progress.

Existing uncommitted TASK 017 work was preserved. The working tree was not reset, restored, reverted, stashed, cleaned, staged, committed, or pushed.

Last observed pre-loss backend suite: **416 passed**, 0 failed.

Plain `dart_frog list` failed only because the `dart_frog` executable was not on PATH (`CommandNotFoundException`). That was a CLI invocation/environment issue, not an application failure.

Recovery used:

```text
dart pub global run dart_frog_cli:dart_frog list
```

The repository was inspected for interrupted/truncated writes (`git diff --check`, file sizes, conflict markers). No truncated Dart files, conflict markers, or zero-byte implementation files were found.

TASK 017 resumed from the existing dirty tree rather than being restarted from scratch.

Pre-loss work already included backend chat/notifications/reviews, routes, tests, Flutter feature surfaces, and index wiring. Recovery completed Flutter test fixes, live index ensure, debug APK, safe live GETs, documentation, and this report.

## Pre-Task Repository State

- `git rev-parse --show-toplevel`: `D:/freelance/erfankhan_cse489/final`
- Branch: `main`
- HEAD at TASK 017 start: `bb462cf` TASK 016 checkpoint (`payment_ledger_webhooks_and_admin_transactions`)
- TASK 016 report Status: SUCCESS
- Working tree at TASK 017 start: clean (TASK 016 committed)
- After power loss / at recovery start: dirty with uncommitted TASK 017 work
- `backend/.env` gitignored (`.gitignore:8:.env`)

Original TASK 017 expected baselines (TASK 016 checkpoint):

- Backend `dart analyze`: clean
- Backend `dart test`: **398 passed**
- Flutter `flutter analyze`: clean
- Flutter `flutter test`: **244 passed**

## Work Performed

Implemented booking-scoped customer ↔ cleaner chat (one conversation per booking, repairable members, immutable messages, Idempotency-Key, keyset history, REST polling), persistent in-app notifications (user+dedupe uniqueness, best-effort side effect after primary mutations), verified completed-booking reviews (one per booking, published/hidden moderation, computed discovery aggregates), Flutter chat/notification/review UX, tests, indexes (live metadata ensure only), and documentation including ADR-015.

No WebSockets, push, Firebase, attachments, message edit/delete, typing/presence, review replies, disputes, or payouts. No new direct packages. No commit.

## Files Created

### Backend chat

- `backend/lib/src/features/chat/application/booking_conversation_service.dart`
- `backend/lib/src/features/chat/data/conversation_indexes.dart`
- `backend/lib/src/features/chat/data/conversation_member_indexes.dart`
- `backend/lib/src/features/chat/data/conversation_member_repository.dart`
- `backend/lib/src/features/chat/data/conversation_repository.dart`
- `backend/lib/src/features/chat/data/message_indexes.dart`
- `backend/lib/src/features/chat/data/message_repository.dart`
- `backend/lib/src/features/chat/domain/chat_exceptions.dart`
- `backend/lib/src/features/chat/domain/chat_message.dart`
- `backend/lib/src/features/chat/domain/chat_validation.dart`
- `backend/lib/src/features/chat/domain/conversation.dart`
- `backend/lib/src/features/chat/domain/conversation_member.dart`

### Backend notifications

- `backend/lib/src/features/notifications/application/notification_service.dart`
- `backend/lib/src/features/notifications/application/notification_sink.dart`
- `backend/lib/src/features/notifications/data/notification_indexes.dart`
- `backend/lib/src/features/notifications/data/notification_repository.dart`
- `backend/lib/src/features/notifications/domain/app_notification.dart`
- `backend/lib/src/features/notifications/domain/notification_exceptions.dart`
- `backend/lib/src/features/notifications/domain/notification_type.dart`
- `backend/lib/src/features/notifications/domain/notification_validation.dart`

### Backend reviews

- `backend/lib/src/features/reviews/application/admin_review_moderation_service.dart`
- `backend/lib/src/features/reviews/application/cleaner_review_service.dart`
- `backend/lib/src/features/reviews/application/customer_review_service.dart`
- `backend/lib/src/features/reviews/data/review_indexes.dart`
- `backend/lib/src/features/reviews/data/review_repository.dart`
- `backend/lib/src/features/reviews/domain/review.dart`
- `backend/lib/src/features/reviews/domain/review_exceptions.dart`
- `backend/lib/src/features/reviews/domain/review_moderation_status.dart`
- `backend/lib/src/features/reviews/domain/review_validation.dart`

### Backend routes / tests

- `backend/routes/api/v1/conversations/_middleware.dart`
- `backend/routes/api/v1/conversations/index.dart`
- `backend/routes/api/v1/conversations/booking/[bookingId]/index.dart`
- `backend/routes/api/v1/conversations/[conversationId]/index.dart`
- `backend/routes/api/v1/conversations/[conversationId]/messages.dart`
- `backend/routes/api/v1/conversations/[conversationId]/read.dart`
- `backend/routes/api/v1/notifications/_middleware.dart`
- `backend/routes/api/v1/notifications/index.dart`
- `backend/routes/api/v1/notifications/read-all.dart`
- `backend/routes/api/v1/notifications/unread-count.dart`
- `backend/routes/api/v1/notifications/[notificationId]/read.dart`
- `backend/routes/api/v1/customer/bookings/[bookingId]/review.dart`
- `backend/routes/api/v1/cleaner/reviews/index.dart`
- `backend/routes/api/v1/admin/reviews/index.dart`
- `backend/routes/api/v1/admin/reviews/[reviewId]/index.dart`
- `backend/routes/api/v1/admin/reviews/[reviewId]/hide.dart`
- `backend/routes/api/v1/admin/reviews/[reviewId]/unhide.dart`
- `backend/test/helpers/recording_notification_sink.dart`
- `backend/test/routes/api/v1/chat_notification_review_routes_test.dart`
- `backend/test/src/features/chat/chat_notifications_reviews_test.dart`

### Flutter

- `project/lib/features/chat/data/chat_api.dart`
- `project/lib/features/chat/data/chat_models.dart`
- `project/lib/features/chat/presentation/booking_chat_controller.dart`
- `project/lib/features/chat/presentation/booking_chat_screen.dart`
- `project/lib/features/notifications/data/notification_api.dart`
- `project/lib/features/notifications/data/notification_models.dart`
- `project/lib/features/notifications/presentation/notification_center_screen.dart`
- `project/lib/features/notifications/presentation/notification_controller.dart`
- `project/lib/features/notifications/presentation/notification_home_link.dart`
- `project/lib/features/reviews/data/review_api.dart`
- `project/lib/features/reviews/data/review_models.dart`
- `project/lib/features/reviews/presentation/admin_review_controller.dart`
- `project/lib/features/reviews/presentation/admin_review_detail_screen.dart`
- `project/lib/features/reviews/presentation/admin_review_list_screen.dart`
- `project/lib/features/reviews/presentation/cleaner_reviews_controller.dart`
- `project/lib/features/reviews/presentation/cleaner_reviews_screen.dart`
- `project/lib/features/reviews/presentation/customer_review_controller.dart`
- `project/lib/features/reviews/presentation/customer_review_screen.dart`
- `project/test/features/chat/data/chat_api_test.dart`
- `project/test/features/chat/presentation/booking_chat_controller_test.dart`
- `project/test/features/chat/presentation/booking_chat_screens_test.dart`
- `project/test/features/notifications/data/notification_api_test.dart`
- `project/test/features/notifications/presentation/notification_controller_test.dart`
- `project/test/features/notifications/presentation/notification_screens_test.dart`
- `project/test/features/reviews/data/review_api_test.dart`
- `project/test/features/reviews/presentation/review_controller_test.dart`
- `project/test/features/reviews/presentation/review_screens_test.dart`

### Documentation

- `documentation/database/conversations-collection.md`
- `documentation/database/conversation-members-collection.md`
- `documentation/database/messages-collection.md`
- `documentation/database/notifications-collection.md`
- `documentation/database/reviews-collection.md`
- `documentation/api/chat-api.md`
- `documentation/api/notification-api.md`
- `documentation/api/review-api.md`
- `documentation/architecture/chat-notifications-and-reviews.md`
- `documentation/decisions/ADR-015-chat-notifications-and-verified-reviews.md`
- `documentation/cursor/017_chat_notifications_reviews_and_moderation.md`

## Files Modified

- `README.md`
- `backend/README.md`
- `backend/lib/src/database/collection_names.dart`
- `backend/lib/src/database/database_indexes.dart`
- `backend/lib/src/features/authorization/application/role_scoped_composition.dart`
- `backend/lib/src/features/authorization/http/role_http_errors.dart`
- `backend/lib/src/features/authorization/http/role_middleware.dart`
- `backend/lib/src/features/authorization/http/role_route_helpers.dart`
- `backend/lib/src/features/authorization/role_authorizer.dart`
- `backend/lib/src/features/authorization/role_request_authorizer.dart`
- `backend/lib/src/features/bookings/application/cleaner_booking_service.dart`
- `backend/lib/src/features/bookings/application/customer_booking_service.dart`
- `backend/lib/src/features/bookings/domain/booking_status.dart`
- `backend/lib/src/features/discovery/application/cleaner_discovery_service.dart`
- `backend/lib/src/features/discovery/domain/cleaner_discovery_models.dart`
- `backend/lib/src/features/payments/application/payment_webhook_service.dart`
- `backend/test/helpers/payment_test_fixtures.dart`
- `backend/test/src/features/bookings/booking_service_test.dart`
- `backend/test/src/features/discovery/discovery_test.dart`
- `backend/test/src/features/payments/payment_service_test.dart`
- `backend/tool/ensure_database_indexes.dart`
- `documentation/README.md`
- `documentation/api/README.md`
- `documentation/api/booking-api.md`
- `documentation/api/services-availability-discovery-api.md`
- `documentation/architecture/README.md`
- `documentation/architecture/backend-api-architecture.md`
- `documentation/architecture/booking-reservation-and-lifecycle.md`
- `documentation/architecture/flutter-client-architecture.md`
- `documentation/architecture/payment-processing-and-webhooks.md`
- `documentation/architecture/service-availability-and-discovery.md`
- `documentation/database/README.md`
- `documentation/database/bookings-collection.md`
- `documentation/decisions/README.md`
- `project/README.md`
- `project/lib/app/router/app_router.dart`
- `project/lib/app/router/app_routes.dart`
- `project/lib/core/network/api_failure.dart`
- `project/lib/features/admin/presentation/admin_home_screen.dart`
- `project/lib/features/bookings/presentation/cleaner_booking_detail_screen.dart`
- `project/lib/features/bookings/presentation/customer_booking_detail_screen.dart`
- `project/lib/features/cleaner/presentation/cleaner_home_screen.dart`
- `project/lib/features/customer/presentation/customer_home_screen.dart`
- `project/lib/features/discovery/data/cleaner_discovery_models.dart`
- `project/lib/features/discovery/presentation/cleaner_comparison_screen.dart`
- `project/lib/features/discovery/presentation/cleaner_discovery_detail_screen.dart`
- `project/lib/features/discovery/presentation/cleaner_discovery_screen.dart`
- `project/test/app/router/app_router_test.dart`
- `project/test/core/network/api_failure_test.dart`
- `project/test/features/admin/presentation/admin_screens_test.dart`
- `project/test/features/bookings/presentation/cleaner_booking_screens_test.dart`
- `project/test/features/bookings/presentation/customer_booking_screens_test.dart`
- `project/test/features/cleaner/presentation/cleaner_screens_test.dart`
- `project/test/features/customer/presentation/customer_screens_test.dart`
- `project/test/features/discovery/presentation/discovery_controller_test.dart`
- `project/test/features/discovery/presentation/discovery_screens_test.dart`
- `project/test/features/payments/presentation/admin_payment_screens_test.dart`
- `project/test/features/payments/presentation/customer_payment_screens_test.dart`
- `project/test/helpers/feature_test_fakes.dart`

## Files Deleted

None.

## Commands Executed

- `git rev-parse --show-toplevel`
- `git branch --show-current`
- `git status` / `git status --short`
- `git log -3 --oneline`
- `git check-ignore -v backend/.env`
- `git diff --check`
- `git diff --stat`
- `dart format .` (backend)
- `dart analyze` (backend)
- `dart test` (backend; 416 passed)
- `dart pub global run dart_frog_cli:dart_frog list`
- `dart run tool/ensure_database_indexes.dart`
- `dart format lib test` (Flutter)
- `flutter analyze`
- `flutter test` (302 passed)
- `flutter build apk --debug`
- `dart pub global run dart_frog_cli:dart_frog build`
- production server on port 8097 for safe GETs, then stopped
- final `dart analyze` / `dart test` / `dart_frog list` / `flutter analyze` / `flutter test`

Did not run: `git add`, `git commit`, `git push`, `dart pub upgrade`, `flutter pub upgrade`, plain `dart_frog list`.

## Implementation Details

Conversations are unique per `booking_id`. Initialization finds or creates the conversation, then upserts customer and cleaner `conversation_members`. Missing members are repaired on later create-or-get. This is not a Mongo multi-document transaction.

Messages are immutable plaintext (1–2000 Unicode code points after trim; newline/tab allowed). Sender comes from the persisted user. `Idempotency-Key` uniqueness is `(conversation_id, sender_user_id, client_idempotency_key)`. Duplicate-key races load the existing row and compare body.

Writable booking statuses: `pending`, `confirmed`, `in_progress`. Terminal statuses are read-only. Message history uses `_id` keyset pagination (`before`/`after`, not both). Conversation list is unpaginated and capped at 50.

`NotificationSink.notifyBestEffort` swallows unexpected write failures so booking/payment/message/review success is not rolled back. Dedupe uses unique `(user_id, dedupe_key)`.

Reviews: one per completed booking; first create 201, update 200; hidden stays hidden after customer edit; hide/unhide idempotent 200. Discovery aggregates published reviews in one batch per visible cleaner id list. Public reviewer identity is `Verified customer`.

Shared chat routes use `multiRoleMiddleware` for customer+cleaner. Notifications allow customer+cleaner+admin. Admin cannot read private booking chat.

Flutter chat polls every 5 seconds while mounted, one in-flight poll, timer cancelled on dispose. Send uses `generateBookingIdempotencyKey` (`Random.secure()`), retained through retry of the same logical send.

## Technical Decisions

- REST polling instead of WebSockets.
- Best-effort notifications instead of a transactional outbox.
- Computed discovery aggregates instead of stored cleaner counters.
- `conversation_members_user_conversation` omitted; lists query `conversations` by role user id, and member reads use `(conversation_id, user_id)` covered by the unique index.
- Message notifications use `resource_type: booking` and the booking id so Flutter opens a role-appropriate booking surface; explicit resource mapping never trusts an arbitrary URL.

## Verification Performed

Backend format/analyze/test/route list, live index ensure, Flutter format/analyze/test, debug APK, safe live GETs `/`, `/api/v1/health`, `/api/v1/ready`, `/api/v1/services`. No protected TASK 017 routes invoked live. No live chat/notification/review fixtures.

## Verification Results

- Backend `dart analyze`: No issues found
- Backend `dart test`: **416 passed**
- `dart pub global run dart_frog_cli:dart_frog list`: success
- Live indexes: ensured; TASK 017 named indexes exist
- Flutter `flutter analyze`: No issues found
- Flutter `flutter test`: **302 passed**
- `flutter build apk --debug`: success (`build/app/outputs/flutter-apk/app-debug.apk`, untracked)
- Live GET `/`, `/api/v1/health`, `/api/v1/ready`, `/api/v1/services`: HTTP 200

## Errors / Warnings

- Unexpected power loss mid-TASK 017. Work resumed from the dirty tree.
- Direct `dart_frog` is not on PATH. Use `dart pub global run dart_frog_cli:dart_frog list`.
- Non-TTY `dart_frog dev` StdinException remains; production `dart build\bin\server.dart` fallback used for live GETs.
- Two Flutter tests failed on resume (`authenticated roles can open shared notifications` sequential `pumpApp`; `home shows unread notification count` duplicate Riverpod override). Both fixed in TASK 017 scope.

## Security / Secrets Check

No secrets added to Flutter or Git. `backend/.env` remains ignored. No MONGODB_URI, ACCESS_TOKEN_SECRET, SANDBOX_PAYMENT_WEBHOOK_SECRET, JWT, refresh token, or password values recorded. No private Atlas documents dumped. APK and `backend/build` are untracked.

## Git Diff Summary

Uncommitted TASK 017: five new collections and feature modules, shared conversation/notification routes, customer/cleaner/admin review routes, Flutter chat/notification/review UX, discovery rating fields, tests, indexes, ADR-015, and documentation index updates.

## Final Repository State

Branch `main`, dirty working tree, HEAD still TASK 016 checkpoint `bb462cf`. TASK 017 complete and uncommitted.

## Unresolved Issues

None blocking. WebSockets, push, outbox exactly-once, attachments, admin dispute chat, and review replies remain deferred.

## Suggested Next Step

TASK 018 as prepared by ChatGPT after review. Do not start it in this task.

## Conversations

One conversation per booking via unique `conversations_booking_unique`. Repairable member upserts for customer and cleaner only.

## Chat Authorization

JWT + persisted active user. Participant must be booking customer or cleaner. Foreign/non-member: `404 conversation_not_found`. Admin forbidden. Sender cannot be body-overridden.

## Messages

Immutable trimmed plaintext, 1–2000 Unicode code points, newline/tab allowed, other controls rejected. `client_idempotency_key` omitted from API JSON.

## Message Idempotency

`Idempotency-Key` 16–128 ASCII. Unique index on conversation+sender+key. Same body replay 200; different body 409. Duplicate-key race handled.

## Chat Lifecycle

Writable: pending/confirmed/in_progress. Read-only: completed/declined/cancelled (`409 conversation_read_only`). History retained.

## Message Pagination

Default latest 50 chronological. `before` older, `after` newer. Both: `400 invalid_message_cursor`. Keyset on `_id`.

## REST Polling

Flutter `Timer.periodic` 5s while chat mounted. `inFlightPoll` prevents overlap. Timer cancelled on controller dispose. Background poll errors do not spam dialogs.

## Notifications

In-app feed, unread count, mark one, mark all, `_id` descending keyset. Available to customer, cleaner, admin.

## Notification Dedupe

Unique `(user_id, dedupe_key)`. Duplicate create is already-delivered.

## Notification Integrations

Booking requested/confirmed/declined/cancelled/started/completed; payment paid/failed/refunded (after valid webhook transition only); first message to the other participant; first review to cleaner. Idempotent replays do not duplicate.

## Notification Consistency

Best-effort after successful primary mutation. Unexpected notification failure does not roll back the primary operation. No outbox. Exactly-once is not claimed.

## Reviews

Completed-booking customer only. One review per booking. Integer rating 1–5. Optional comment. Payment status not required. `verified_booking` computed.

## Review Moderation

New reviews published. Admin hide/unhide. Hide already-hidden: idempotent 200 without overwriting reason. Customer edit of hidden review stays hidden.

## Discovery Review Integration

Batched `aggregateForCleanerIds` for list. Detail latest 10 published. `rating_average` null and `review_count` 0 when none. Hidden excluded. No N+1. No stored counters on `cleaner_profiles`.

## Discovery Review Privacy

Public reviewer name is `Verified customer`. No customer_user_id, email, phone, address, booking notes, or payment data.

## MongoDB Indexes

conversations: `conversations_booking_unique`, `conversations_customer_last_message`, `conversations_cleaner_last_message`

conversation_members: `conversation_members_conversation_user_unique`

Omitted: `conversation_members_user_conversation` (redundant for chosen queries)

messages: `messages_conversation_id_desc`, `messages_sender_idempotency_unique`

notifications: `notifications_user_id_desc`, `notifications_user_read_id_desc`, `notifications_user_dedupe_unique`

reviews: `reviews_booking_unique`, `reviews_cleaner_status_id_desc`, `reviews_customer_id_desc`, `reviews_status_rating_id_desc`

Live ensure verified these names. Index metadata only.

## Backend Tests

`dart analyze`: No issues found. `dart test`: **416 passed**. Atlas-free fakes/in-memory seams.

## Backend Routes

See `dart pub global run dart_frog_cli:dart_frog list` output recorded in the TASK 017 RESULT response.

## Flutter Chat Experience

Customer/cleaner booking chat routes. `BookingChatScreen` with other-party name, messages, composer. Terminal bookings show read-only copy. Booking detail: Message Cleaner / Message Customer.

## Flutter Notification Experience

`/notifications` shared. Center with mark one/all, load more, unread filter. Home link with unread count. Explicit resource mapping; unknown resources stay in the center.

## Flutter Customer Review Experience

Completed bookings: Leave Review / Edit Review. Stars 1–5, optional comment. Hidden note does not imply republish.

## Flutter Cleaner Review Experience

My Reviews. Verified customer label. All/Published/Hidden. Load more. No customer contact data.

## Flutter Admin Moderation Experience

Review Moderation list/detail/hide/unhide. Hide requires a reason.

## Flutter Discovery Experience

List/detail/comparison show rating average and review count. Detail shows latest published reviews as Verified customer. No fabricated ratings.

## Flutter State

Focused Riverpod controllers. Chat/notification/review state is not in AuthController.

## Flutter Routing

`/customer/bookings/:bookingId/chat`, `/customer/bookings/:bookingId/review`, `/cleaner/bookings/:bookingId/chat`, `/cleaner/reviews`, `/notifications`, `/admin/reviews`, `/admin/reviews/:reviewId`. Role prefix guards remain UX only.

## Flutter Tests

**302 passed**. Coverage: chat API/controller/screens, notification API/controller/screens, review API/controllers/screens, router role gating, discovery ratings, existing auth/payment/booking regressions.

## Flutter Static Analysis

No issues found.

## Android Debug Build

`flutter build apk --debug` succeeded. APK not tracked. Application ID, release signing, and production network security unchanged.

## Live Backend Verification

GET `/` 200; GET `/api/v1/health` 200; GET `/api/v1/ready` 200; GET `/api/v1/services` 200. No protected TASK 017 route invoked live.

## Live Data Safety

Live Atlas mutation: approved index metadata only. No live conversations, members, messages, notifications, reviews, users, bookings, payments, addresses, availability, or sessions created by TASK 017.

## Documentation

Created collection docs, chat/notification/review APIs, architecture doc, ADR-015, cursor report, and updated indexes/READMEs. Does not claim WebSockets, push, or outbox exactly-once.

## Security Verification

Chat ownership and foreign 404; persisted user authority; sender not body-overridable; admin cannot silently inspect chat; no email/phone/address/token leak; terminal read-only; notification ownership; body cannot choose user_id; deterministic dedupe; safe contents; no arbitrary navigation URL trust; completed-booking customer reviews only; one review per booking; no ownership/moderation override; hidden absent from discovery; admin-only moderation; neutral public identity; no customer contact/address/payment public; existing auth/payment security intact; no new auth stack; no secrets in Flutter; `backend/.env` ignored.

## Git Status

Uncommitted, unstaged. `git check-ignore -v backend/.env` → `.gitignore:8:.env`.

## Issues / Warnings

Power-loss recovery as documented above. Direct `dart_frog` PATH issue remains; use the global CLI invocation. Non-TTY `dart_frog dev` StdinException remains; production-build fallback used.

## Final Statement

Booking-scoped chat, persistent in-app notifications, verified reviews, discovery rating integration, and admin review moderation are complete and ready for ChatGPT review. WebSockets, push notifications, disputes, and payouts were not implemented. TASK 018 was not started. TASK 017 is uncommitted.
