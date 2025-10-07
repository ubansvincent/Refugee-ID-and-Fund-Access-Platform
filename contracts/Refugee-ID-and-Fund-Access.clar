

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_REGISTERED (err u101))
(define-constant ERR_NOT_REGISTERED (err u102))
(define-constant ERR_INSUFFICIENT_FUNDS (err u103))
(define-constant ERR_INVALID_AMOUNT (err u104))
(define-constant ERR_ALREADY_VERIFIED (err u105))
(define-constant ERR_NOT_VERIFIED (err u106))
(define-constant ERR_INVALID_RECIPIENT (err u107))
(define-constant ERR_PENDING_APPROVAL (err u108))
(define-constant ERR_ALREADY_APPROVED (err u109))
(define-constant ERR_NOT_AUTHORIZED_SIGNER (err u110))

(define-constant ERR_ALERT_NOT_FOUND (err u111))
(define-constant ERR_INVALID_ALERT_TYPE (err u112))
(define-constant ERR_ALERT_RESOLVED (err u113))

(define-data-var next-alert-id uint u1)

(define-data-var multisig-threshold uint u10000)
(define-data-var required-signatures uint u2)
(define-data-var next-proposal-id uint u1)

(define-data-var total-refugees uint u0)
(define-data-var total-aid-distributed uint u0)
(define-data-var contract-balance uint u0)

(define-map refugee-profiles
  principal
  {
    name: (string-ascii 50),
    age: uint,
    country-of-origin: (string-ascii 30),
    current-location: (string-ascii 50),
    family-size: uint,
    registration-block: uint,
    is-verified: bool,
    total-aid-received: uint,
    emergency-contact: (string-ascii 100)
  }
)

(define-map verifiers
  principal
  {
    name: (string-ascii 50),
    organization: (string-ascii 50),
    is-active: bool,
    verifications-count: uint
  }
)

(define-map aid-distributions
  uint
  {
    recipient: principal,
    amount: uint,
    distributor: principal,
    block-height: uint,
    purpose: (string-ascii 100)
  }
)

(define-data-var next-distribution-id uint u1)

(define-public (register-refugee 
  (name (string-ascii 50))
  (age uint)
  (country-of-origin (string-ascii 30))
  (current-location (string-ascii 50))
  (family-size uint)
  (emergency-contact (string-ascii 100))
)
  (let ((existing-profile (map-get? refugee-profiles tx-sender)))
    (if (is-some existing-profile)
      ERR_ALREADY_REGISTERED
      (begin
        (map-set refugee-profiles tx-sender {
          name: name,
          age: age,
          country-of-origin: country-of-origin,
          current-location: current-location,
          family-size: family-size,
          registration-block: stacks-block-height,
          is-verified: false,
          total-aid-received: u0,
          emergency-contact: emergency-contact
        })
        (var-set total-refugees (+ (var-get total-refugees) u1))
        (ok true)
      )
    )
  )
)

(define-public (register-verifier 
  (name (string-ascii 50))
  (organization (string-ascii 50))
)
  (let ((existing-verifier (map-get? verifiers tx-sender)))
    (if (is-some existing-verifier)
      ERR_ALREADY_REGISTERED
      (begin
        (map-set verifiers tx-sender {
          name: name,
          organization: organization,
          is-active: true,
          verifications-count: u0
        })
        (ok true)
      )
    )
  )
)

(define-public (verify-refugee (refugee-address principal))
  (let (
    (verifier-info (map-get? verifiers tx-sender))
    (refugee-info (map-get? refugee-profiles refugee-address))
  )
    (if (and (is-some verifier-info) (is-some refugee-info))
      (let (
        (verifier-data (unwrap-panic verifier-info))
        (refugee-data (unwrap-panic refugee-info))
      )
        (if (get is-verified refugee-data)
          ERR_ALREADY_VERIFIED
          (begin
            (map-set refugee-profiles refugee-address 
              (merge refugee-data { is-verified: true })
            )
            (map-set verifiers tx-sender 
              (merge verifier-data { 
                verifications-count: (+ (get verifications-count verifier-data) u1) 
              })
            )
            (ok true)
          )
        )
      )
      ERR_UNAUTHORIZED
    )
  )
)

(define-public (deposit-funds)
  (let ((amount (stx-get-balance tx-sender)))
    (if (> amount u0)
      (begin
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        (var-set contract-balance (+ (var-get contract-balance) amount))
        (ok amount)
      )
      ERR_INVALID_AMOUNT
    )
  )
)

(define-public (distribute-aid 
  (recipient principal) 
  (amount uint) 
  (purpose (string-ascii 100))
)
  (let (
    (recipient-info (map-get? refugee-profiles recipient))
    (current-balance (var-get contract-balance))
    (distribution-id (var-get next-distribution-id))
  )
    (if (is-none recipient-info)
      ERR_NOT_REGISTERED
      (let ((recipient-data (unwrap-panic recipient-info)))
        (if (not (get is-verified recipient-data))
          ERR_NOT_VERIFIED
          (if (> amount current-balance)
            ERR_INSUFFICIENT_FUNDS
            (if (<= amount u0)
              ERR_INVALID_AMOUNT
              (begin
                (try! (as-contract (stx-transfer? amount tx-sender recipient)))
                (var-set contract-balance (- current-balance amount))
                (var-set total-aid-distributed (+ (var-get total-aid-distributed) amount))
                (map-set refugee-profiles recipient 
                  (merge recipient-data { 
                    total-aid-received: (+ (get total-aid-received recipient-data) amount) 
                  })
                )
                (map-set aid-distributions distribution-id {
                  recipient: recipient,
                  amount: amount,
                  distributor: tx-sender,
                  block-height: stacks-block-height,
                  purpose: purpose
                })
                (var-set next-distribution-id (+ distribution-id u1))
                (ok distribution-id)
              )
            )
          )
        )
      )
    )
  )
)

(define-public (update-location (new-location (string-ascii 50)))
  (let ((refugee-info (map-get? refugee-profiles tx-sender)))
    (if (is-some refugee-info)
      (let ((refugee-data (unwrap-panic refugee-info)))
        (map-set refugee-profiles tx-sender 
          (merge refugee-data { current-location: new-location })
        )
        (ok true)
      )
      ERR_NOT_REGISTERED
    )
  )
)

(define-public (emergency-withdraw)
  (if (is-eq tx-sender CONTRACT_OWNER)
    (let ((balance (var-get contract-balance)))
      (if (> balance u0)
        (begin
          (try! (as-contract (stx-transfer? balance tx-sender CONTRACT_OWNER)))
          (var-set contract-balance u0)
          (ok balance)
        )
        ERR_INSUFFICIENT_FUNDS
      )
    )
    ERR_UNAUTHORIZED
  )
)

(define-read-only (get-refugee-profile (refugee-address principal))
  (map-get? refugee-profiles refugee-address)
)

(define-read-only (get-verifier-info (verifier-address principal))
  (map-get? verifiers verifier-address)
)

(define-read-only (get-aid-distribution (distribution-id uint))
  (map-get? aid-distributions distribution-id)
)

(define-read-only (get-contract-stats)
  {
    total-refugees: (var-get total-refugees),
    total-aid-distributed: (var-get total-aid-distributed),
    contract-balance: (var-get contract-balance),
    next-distribution-id: (var-get next-distribution-id)
  }
)

(define-read-only (is-refugee-verified (refugee-address principal))
  (match (map-get? refugee-profiles refugee-address)
    refugee-data (get is-verified refugee-data)
    false
  )
)

(define-read-only (get-refugee-aid-total (refugee-address principal))
  (match (map-get? refugee-profiles refugee-address)
    refugee-data (get total-aid-received refugee-data)
    u0
  )
)

(define-read-only (is-active-verifier (verifier-address principal))
  (match (map-get? verifiers verifier-address)
    verifier-data (get is-active verifier-data)
    false
  )
)

(define-map authorized-signers principal bool)
(define-map aid-proposals uint {
  recipient: principal,
  amount: uint,
  purpose: (string-ascii 100),
  proposer: principal,
  approvals: uint,
  executed: bool,
  created-at: uint
})
(define-map proposal-approvals { proposal-id: uint, signer: principal } bool)

(define-public (add-authorized-signer (signer principal))
  (if (is-eq tx-sender CONTRACT_OWNER)
    (begin
      (map-set authorized-signers signer true)
      (ok true))
    ERR_UNAUTHORIZED))

(define-public (propose-large-aid (recipient principal) (amount uint) (purpose (string-ascii 100)))
  (if (and (>= amount (var-get multisig-threshold)) (default-to false (map-get? authorized-signers tx-sender)))
    (let ((proposal-id (var-get next-proposal-id)))
      (map-set aid-proposals proposal-id {
        recipient: recipient,
        amount: amount,
        purpose: purpose,
        proposer: tx-sender,
        approvals: u0,
        executed: false,
        created-at: stacks-block-height
      })
      (var-set next-proposal-id (+ proposal-id u1))
      (ok proposal-id))
    ERR_UNAUTHORIZED))

(define-public (approve-aid-proposal (proposal-id uint))
  (let ((proposal (map-get? aid-proposals proposal-id))
        (is-signer (default-to false (map-get? authorized-signers tx-sender)))
        (already-approved (default-to false (map-get? proposal-approvals { proposal-id: proposal-id, signer: tx-sender }))))
    (if (and (is-some proposal) is-signer (not already-approved))
      (let ((proposal-data (unwrap-panic proposal)))
        (if (not (get executed proposal-data))
          (begin
            (map-set proposal-approvals { proposal-id: proposal-id, signer: tx-sender } true)
            (map-set aid-proposals proposal-id (merge proposal-data { approvals: (+ (get approvals proposal-data) u1) }))
            (ok true))
          ERR_UNAUTHORIZED))
      ERR_ALREADY_APPROVED)))

(define-public (execute-approved-proposal (proposal-id uint))
  (let ((proposal (map-get? aid-proposals proposal-id)))
    (if (is-some proposal)
      (let ((proposal-data (unwrap-panic proposal)))
        (if (and (>= (get approvals proposal-data) (var-get required-signatures)) (not (get executed proposal-data)))
          (begin
            (try! (distribute-aid (get recipient proposal-data) (get amount proposal-data) (get purpose proposal-data)))
            (map-set aid-proposals proposal-id (merge proposal-data { executed: true }))
            (ok true))
          ERR_UNAUTHORIZED))
      ERR_NOT_REGISTERED)))

(define-read-only (get-proposal (proposal-id uint))
  (map-get? aid-proposals proposal-id))

(define-read-only (has-approved-proposal (proposal-id uint) (signer principal))
  (default-to false (map-get? proposal-approvals { proposal-id: proposal-id, signer: signer })))


(define-map emergency-alerts
  uint
  {
    reporter: principal,
    alert-type: (string-ascii 20),
    severity: uint,
    location: (string-ascii 50),
    description: (string-ascii 200),
    timestamp: uint,
    is-resolved: bool,
    responder: (optional principal),
    resolution-notes: (optional (string-ascii 100))
  }
)

(define-map authorized-responders principal bool)

(define-map alert-responses
  { alert-id: uint, responder: principal }
  {
    response-time: uint,
    action-taken: (string-ascii 150),
    resources-provided: uint
  }
)

(define-public (register-responder (responder principal))
  (if (is-eq tx-sender CONTRACT_OWNER)
    (begin
      (map-set authorized-responders responder true)
      (ok true)
    )
    ERR_UNAUTHORIZED
  )
)

(define-public (broadcast-emergency 
  (alert-type (string-ascii 20))
  (severity uint)
  (location (string-ascii 50))
  (description (string-ascii 200))
)
  (let ((refugee-info (map-get? refugee-profiles tx-sender)))
    (if (and (is-some refugee-info) (get is-verified (unwrap-panic refugee-info)))
      (let ((alert-id (var-get next-alert-id)))
        (map-set emergency-alerts alert-id {
          reporter: tx-sender,
          alert-type: alert-type,
          severity: severity,
          location: location,
          description: description,
          timestamp: stacks-block-height,
          is-resolved: false,
          responder: none,
          resolution-notes: none
        })
        (var-set next-alert-id (+ alert-id u1))
        (ok alert-id)
      )
      ERR_NOT_VERIFIED
    )
  )
)

(define-public (respond-to-alert 
  (alert-id uint)
  (action-taken (string-ascii 150))
  (resources-provided uint)
)
  (let ((alert-info (map-get? emergency-alerts alert-id)))
    (if (and (is-some alert-info) (default-to false (map-get? authorized-responders tx-sender)))
      (let ((alert-data (unwrap-panic alert-info)))
        (if (get is-resolved alert-data)
          ERR_ALERT_RESOLVED
          (begin
            (map-set alert-responses { alert-id: alert-id, responder: tx-sender } {
              response-time: stacks-block-height,
              action-taken: action-taken,
              resources-provided: resources-provided
            })
            (ok true)
          )
        )
      )
      ERR_UNAUTHORIZED
    )
  )
)

(define-public (resolve-alert (alert-id uint) (resolution-notes (string-ascii 100)))
  (let ((alert-info (map-get? emergency-alerts alert-id)))
    (if (and (is-some alert-info) (default-to false (map-get? authorized-responders tx-sender)))
      (let ((alert-data (unwrap-panic alert-info)))
        (map-set emergency-alerts alert-id 
          (merge alert-data { 
            is-resolved: true, 
            responder: (some tx-sender),
            resolution-notes: (some resolution-notes)
          })
        )
        (ok true)
      )
      ERR_UNAUTHORIZED
    )
  )
)

(define-read-only (get-emergency-alert (alert-id uint))
  (map-get? emergency-alerts alert-id)
)

(define-read-only (get-alert-response (alert-id uint) (responder principal))
  (map-get? alert-responses { alert-id: alert-id, responder: responder })
)
