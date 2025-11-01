(define-constant ERR_NOT_VERIFIED_REFUGEE (err u300))
(define-constant ERR_CAMPAIGN_NOT_FOUND (err u301))
(define-constant ERR_INVALID_GOAL (err u302))
(define-constant ERR_CAMPAIGN_CLOSED (err u303))
(define-constant ERR_INSUFFICIENT_CAMPAIGN_FUNDS (err u304))
(define-constant ERR_UNAUTHORIZED_WITHDRAWAL (err u305))
(define-constant ERR_INVALID_DONATION (err u306))

(define-data-var next-campaign-id uint u1)
(define-data-var total-campaigns-created uint u0)
(define-data-var total-community-donations uint u0)

(define-map fundraising-campaigns
  uint
  {
    creator: principal,
    title: (string-ascii 60),
    story: (string-ascii 200),
    goal-amount: uint,
    raised-amount: uint,
    donor-count: uint,
    created-at: uint,
    is-active: bool,
    category: (string-ascii 30)
  }
)

(define-map campaign-donations
  { campaign-id: uint, donor: principal }
  {
    total-donated: uint,
    donation-count: uint,
    first-donation-block: uint
  }
)

(define-map campaign-balances uint uint)

(define-public (create-campaign
  (title (string-ascii 60))
  (story (string-ascii 200))
  (goal-amount uint)
  (category (string-ascii 30))
)
  (let ((campaign-id (var-get next-campaign-id)))
    (asserts! (> goal-amount u0) ERR_INVALID_GOAL)
    (asserts! (is-verified-refugee-check tx-sender) ERR_NOT_VERIFIED_REFUGEE)
    (map-set fundraising-campaigns campaign-id {
      creator: tx-sender,
      title: title,
      story: story,
      goal-amount: goal-amount,
      raised-amount: u0,
      donor-count: u0,
      created-at: stacks-block-height,
      is-active: true,
      category: category
    })
    (map-set campaign-balances campaign-id u0)
    (var-set next-campaign-id (+ campaign-id u1))
    (var-set total-campaigns-created (+ (var-get total-campaigns-created) u1))
    (ok campaign-id)
  )
)

(define-public (donate-to-campaign (campaign-id uint) (amount uint))
  (let (
    (campaign (unwrap! (map-get? fundraising-campaigns campaign-id) ERR_CAMPAIGN_NOT_FOUND))
    (current-balance (default-to u0 (map-get? campaign-balances campaign-id)))
    (donor-history (map-get? campaign-donations { campaign-id: campaign-id, donor: tx-sender }))
  )
    (asserts! (get is-active campaign) ERR_CAMPAIGN_CLOSED)
    (asserts! (> amount u0) ERR_INVALID_DONATION)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set campaign-balances campaign-id (+ current-balance amount))
    (map-set fundraising-campaigns campaign-id
      (merge campaign {
        raised-amount: (+ (get raised-amount campaign) amount),
        donor-count: (if (is-none donor-history) (+ (get donor-count campaign) u1) (get donor-count campaign))
      })
    )
    (map-set campaign-donations { campaign-id: campaign-id, donor: tx-sender }
      (if (is-some donor-history)
        (let ((history (unwrap-panic donor-history)))
          { total-donated: (+ (get total-donated history) amount),
            donation-count: (+ (get donation-count history) u1),
            first-donation-block: (get first-donation-block history) })
        { total-donated: amount, donation-count: u1, first-donation-block: stacks-block-height }
      )
    )
    (var-set total-community-donations (+ (var-get total-community-donations) amount))
    (ok true)
  )
)

(define-public (withdraw-campaign-funds (campaign-id uint) (amount uint))
  (let (
    (campaign (unwrap! (map-get? fundraising-campaigns campaign-id) ERR_CAMPAIGN_NOT_FOUND))
    (balance (default-to u0 (map-get? campaign-balances campaign-id)))
  )
    (asserts! (is-eq tx-sender (get creator campaign)) ERR_UNAUTHORIZED_WITHDRAWAL)
    (asserts! (<= amount balance) ERR_INSUFFICIENT_CAMPAIGN_FUNDS)
    (try! (as-contract (stx-transfer? amount tx-sender (get creator campaign))))
    (map-set campaign-balances campaign-id (- balance amount))
    (ok true)
  )
)

(define-public (close-campaign (campaign-id uint))
  (let ((campaign (unwrap! (map-get? fundraising-campaigns campaign-id) ERR_CAMPAIGN_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get creator campaign)) ERR_UNAUTHORIZED_WITHDRAWAL)
    (map-set fundraising-campaigns campaign-id (merge campaign { is-active: false }))
    (ok true)
  )
)

(define-read-only (get-campaign (campaign-id uint))
  (map-get? fundraising-campaigns campaign-id)
)

(define-read-only (get-campaign-balance (campaign-id uint))
  (default-to u0 (map-get? campaign-balances campaign-id))
)

(define-read-only (get-donor-contribution (campaign-id uint) (donor principal))
  (map-get? campaign-donations { campaign-id: campaign-id, donor: donor })
)

(define-read-only (get-fundraising-stats)
  {
    total-campaigns: (var-get total-campaigns-created),
    total-donations: (var-get total-community-donations),
    next-campaign-id: (var-get next-campaign-id)
  }
)

(define-read-only (is-verified-refugee-check (address principal))
  (contract-call? .Refugee-ID-and-Fund-Access is-refugee-verified address)
)
