(define-constant ERR_NOT_CAMPAIGN_CREATOR (err u400))
(define-constant ERR_CAMPAIGN_NOT_FOUND (err u401))
(define-constant ERR_MILESTONE_NOT_FOUND (err u402))
(define-constant ERR_INVALID_PERCENTAGE (err u403))
(define-constant ERR_MILESTONE_ALREADY_COMPLETED (err u404))
(define-constant ERR_INSUFFICIENT_PROGRESS (err u405))
(define-constant ERR_DUPLICATE_MILESTONE (err u406))

(define-data-var next-milestone-id uint u1)

(define-map campaign-milestones
  { campaign-id: uint, milestone-id: uint }
  {
    title: (string-ascii 60),
    description: (string-ascii 150),
    target-percentage: uint,
    funds-to-unlock: uint,
    is-completed: bool,
    completed-at: (optional uint),
    proof-notes: (optional (string-ascii 100))
  }
)

(define-map campaign-milestone-count uint uint)

(define-map milestone-achievements
  { campaign-id: uint, milestone-id: uint, supporter: principal }
  { celebrated-at: uint }
)

(define-public (create-milestone
  (campaign-id uint)
  (title (string-ascii 60))
  (description (string-ascii 150))
  (target-percentage uint)
)
  (let (
    (campaign (unwrap! (contract-call? .refugee-community-fundraising get-campaign campaign-id) ERR_CAMPAIGN_NOT_FOUND))
    (milestone-count (default-to u0 (map-get? campaign-milestone-count campaign-id)))
    (milestone-id milestone-count)
    (funds-to-unlock (/ (* (get goal-amount campaign) target-percentage) u100))
  )
    (asserts! (is-eq tx-sender (get creator campaign)) ERR_NOT_CAMPAIGN_CREATOR)
    (asserts! (and (> target-percentage u0) (<= target-percentage u100)) ERR_INVALID_PERCENTAGE)
    (map-set campaign-milestones { campaign-id: campaign-id, milestone-id: milestone-id } {
      title: title,
      description: description,
      target-percentage: target-percentage,
      funds-to-unlock: funds-to-unlock,
      is-completed: false,
      completed-at: none,
      proof-notes: none
    })
    (map-set campaign-milestone-count campaign-id (+ milestone-count u1))
    (ok milestone-id)
  )
)

(define-public (complete-milestone
  (campaign-id uint)
  (milestone-id uint)
  (proof-notes (string-ascii 100))
)
  (let (
    (campaign (unwrap! (contract-call? .refugee-community-fundraising get-campaign campaign-id) ERR_CAMPAIGN_NOT_FOUND))
    (milestone (unwrap! (map-get? campaign-milestones { campaign-id: campaign-id, milestone-id: milestone-id }) ERR_MILESTONE_NOT_FOUND))
  )
    (asserts! (is-eq tx-sender (get creator campaign)) ERR_NOT_CAMPAIGN_CREATOR)
    (asserts! (not (get is-completed milestone)) ERR_MILESTONE_ALREADY_COMPLETED)
    (asserts! (>= (get raised-amount campaign) (get funds-to-unlock milestone)) ERR_INSUFFICIENT_PROGRESS)
    (map-set campaign-milestones { campaign-id: campaign-id, milestone-id: milestone-id }
      (merge milestone {
        is-completed: true,
        completed-at: (some stacks-block-height),
        proof-notes: (some proof-notes)
      })
    )
    (ok true)
  )
)

(define-read-only (get-milestone (campaign-id uint) (milestone-id uint))
  (map-get? campaign-milestones { campaign-id: campaign-id, milestone-id: milestone-id })
)

(define-read-only (get-campaign-progress (campaign-id uint))
  (let ((milestone-count (default-to u0 (map-get? campaign-milestone-count campaign-id))))
    { total-milestones: milestone-count }
  )
)
