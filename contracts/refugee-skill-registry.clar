(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_VERIFIED_REFUGEE (err u200))
(define-constant ERR_SKILL_NOT_FOUND (err u201))
(define-constant ERR_UNAUTHORIZED_VALIDATOR (err u202))
(define-constant ERR_SKILL_ALREADY_VERIFIED (err u203))
(define-constant ERR_INVALID_SKILL_LEVEL (err u204))
(define-constant ERR_MAX_SKILLS_REACHED (err u205))

(define-data-var next-skill-id uint u1)
(define-data-var total-registered-skills uint u0)

(define-map skill-validators principal bool)

(define-map refugee-skills
  { refugee: principal, skill-id: uint }
  {
    skill-category: (string-ascii 30),
    skill-name: (string-ascii 50),
    proficiency-level: uint,
    years-experience: uint,
    education-level: (string-ascii 30),
    certifications: (string-ascii 100),
    is-verified: bool,
    verified-by: (optional principal),
    verification-date: (optional uint)
  }
)

(define-map refugee-skill-count principal uint)

(define-map employment-interests
  principal
  {
    preferred-industry: (string-ascii 40),
    work-authorization: bool,
    available-hours: uint,
    preferred-location: (string-ascii 50),
    languages: (string-ascii 100)
  }
)

(define-public (register-skill-validator (validator principal))
  (if (is-eq tx-sender CONTRACT_OWNER)
    (begin
      (map-set skill-validators validator true)
      (ok true)
    )
    ERR_UNAUTHORIZED_VALIDATOR
  )
)

(define-public (register-skill
  (skill-category (string-ascii 30))
  (skill-name (string-ascii 50))
  (proficiency-level uint)
  (years-experience uint)
  (education-level (string-ascii 30))
  (certifications (string-ascii 100))
)
  (let ((refugee-skill-total (default-to u0 (map-get? refugee-skill-count tx-sender))))
    (if (< refugee-skill-total u10)
      (if (and (<= proficiency-level u5) (>= proficiency-level u1))
        (let ((skill-id (var-get next-skill-id)))
          (map-set refugee-skills { refugee: tx-sender, skill-id: skill-id } {
            skill-category: skill-category,
            skill-name: skill-name,
            proficiency-level: proficiency-level,
            years-experience: years-experience,
            education-level: education-level,
            certifications: certifications,
            is-verified: false,
            verified-by: none,
            verification-date: none
          })
          (map-set refugee-skill-count tx-sender (+ refugee-skill-total u1))
          (var-set next-skill-id (+ skill-id u1))
          (var-set total-registered-skills (+ (var-get total-registered-skills) u1))
          (ok skill-id)
        )
        ERR_INVALID_SKILL_LEVEL
      )
      ERR_MAX_SKILLS_REACHED
    )
  )
)

(define-public (verify-skill (refugee principal) (skill-id uint))
  (if (default-to false (map-get? skill-validators tx-sender))
    (let ((skill-info (map-get? refugee-skills { refugee: refugee, skill-id: skill-id })))
      (if (is-some skill-info)
        (let ((skill-data (unwrap-panic skill-info)))
          (if (get is-verified skill-data)
            ERR_SKILL_ALREADY_VERIFIED
            (begin
              (map-set refugee-skills { refugee: refugee, skill-id: skill-id }
                (merge skill-data {
                  is-verified: true,
                  verified-by: (some tx-sender),
                  verification-date: (some stacks-block-height)
                })
              )
              (ok true)
            )
          )
        )
        ERR_SKILL_NOT_FOUND
      )
    )
    ERR_UNAUTHORIZED_VALIDATOR
  )
)

(define-public (update-employment-preferences
  (preferred-industry (string-ascii 40))
  (work-authorization bool)
  (available-hours uint)
  (preferred-location (string-ascii 50))
  (languages (string-ascii 100))
)
  (begin
    (map-set employment-interests tx-sender {
      preferred-industry: preferred-industry,
      work-authorization: work-authorization,
      available-hours: available-hours,
      preferred-location: preferred-location,
      languages: languages
    })
    (ok true)
  )
)

(define-read-only (get-refugee-skill (refugee principal) (skill-id uint))
  (map-get? refugee-skills { refugee: refugee, skill-id: skill-id })
)

(define-read-only (get-refugee-skill-count (refugee principal))
  (default-to u0 (map-get? refugee-skill-count refugee))
)

(define-read-only (get-employment-interests (refugee principal))
  (map-get? employment-interests refugee)
)

(define-read-only (is-skill-validator (validator principal))
  (default-to false (map-get? skill-validators validator))
)

(define-read-only (get-skill-registry-stats)
  {
    total-skills: (var-get total-registered-skills),
    next-skill-id: (var-get next-skill-id)
  }
)
