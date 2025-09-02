;; Sustainability Validator Contract
;; Manages certification validation, consumer transparency, and sustainability scoring

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_CERTIFICATION_NOT_FOUND (err u201))
(define-constant ERR_INVALID_RATING (err u202))
(define-constant ERR_VALIDATOR_NOT_FOUND (err u203))
(define-constant ERR_ALREADY_CERTIFIED (err u204))
(define-constant ERR_EXPIRED_CERTIFICATION (err u205))
(define-constant ERR_INSUFFICIENT_DATA (err u206))
(define-constant ERR_CONSUMER_NOT_FOUND (err u207))

;; Data Variables
(define-data-var next-certification-id uint u1)
(define-data-var next-validator-id uint u1)
(define-data-var next-consumer-id uint u1)
(define-data-var next-feedback-id uint u1)

;; Certification Types
(define-constant CERT_ORGANIC u1)
(define-constant CERT_FAIR_TRADE u2)
(define-constant CERT_OEKO_TEX u3)
(define-constant CERT_CRADLE_TO_CRADLE u4)
(define-constant CERT_GOTS u5) ;; Global Organic Textile Standard
(define-constant CERT_REACH u6)
(define-constant CERT_CARBON_NEUTRAL u7)
(define-constant CERT_WATER_STEWARDSHIP u8)
(define-constant CERT_B_CORP u9)
(define-constant CERT_RECYCLED_CONTENT u10)

;; Data Maps

;; Certification Authority Information
(define-map certification-authorities
  uint
  {
    name: (string-ascii 50),
    accreditation-body: (string-ascii 50),
    certification-types: (list 10 uint),
    validity-period-days: uint,
    contact-info: (string-ascii 100),
    reputation-score: uint,
    active-status: bool,
    registered-at: uint
  }
)

;; Product Certifications
(define-map product-certifications
  uint ;; certification-id
  {
    product-id: uint,
    certification-type: uint,
    certifying-authority: uint,
    issue-date: uint,
    expiry-date: uint,
    certification-number: (string-ascii 30),
    verification-hash: (string-ascii 64),
    audit-score: uint,
    valid-status: bool
  }
)

;; Sustainability Validators (Third-party auditors)
(define-map sustainability-validators
  uint
  {
    name: (string-ascii 50),
    specialization: (string-ascii 50),
    credentials: (list 5 (string-ascii 30)),
    validation-count: uint,
    success-rate: uint,
    contact-info: (string-ascii 100),
    active-status: bool,
    registered-at: uint
  }
)

;; Consumer Transparency Records
(define-map consumer-transparency
  uint ;; product-id
  {
    sustainability-label: (string-ascii 20),
    environmental-score: uint,
    social-score: uint,
    transparency-level: uint,
    qr-code-data: (string-ascii 100),
    consumer-accessible: bool,
    last-updated: uint,
    verification-status: bool
  }
)

;; Consumer Feedback and Ratings
(define-map consumer-feedback
  uint
  {
    product-id: uint,
    consumer-id: uint,
    sustainability-rating: uint,
    transparency-rating: uint,
    overall-satisfaction: uint,
    feedback-text: (string-ascii 200),
    verified-purchase: bool,
    feedback-date: uint
  }
)

;; Consumer Education Content
(define-map education-content
  uint ;; content-id
  {
    title: (string-ascii 100),
    content-type: (string-ascii 20),
    sustainability-topic: (string-ascii 50),
    difficulty-level: uint,
    engagement-count: uint,
    educational-value: uint,
    created-at: uint,
    active-status: bool
  }
)

;; Sustainability Impact Metrics
(define-map impact-metrics
  uint ;; product-id
  {
    carbon-footprint-reduction: uint,
    water-saved-liters: uint,
    waste-diverted-kg: uint,
    renewable-energy-used: uint,
    circular-materials-percentage: uint,
    biodiversity-impact-score: uint,
    social-impact-score: uint,
    economic-benefit-score: uint
  }
)

;; Compliance Monitoring
(define-map compliance-records
  uint ;; product-id
  {
    last-audit-date: uint,
    compliance-percentage: uint,
    violations-count: uint,
    corrective-actions: (list 5 (string-ascii 50)),
    next-audit-due: uint,
    compliance-officer: principal,
    risk-level: uint
  }
)

;; Consumer Registry
(define-map consumer-registry
  uint
  {
    wallet-address: principal,
    sustainability-preferences: {
      organic-preference: bool,
      fair-trade-preference: bool,
      local-sourcing-preference: bool,
      recycled-content-preference: bool
    },
    education-level: uint,
    engagement-score: uint,
    feedback-count: uint,
    registered-at: uint
  }
)

;; Public Functions

;; Register a new certification authority
(define-public (register-certification-authority
  (name (string-ascii 50))
  (accreditation-body (string-ascii 50))
  (cert-types (list 10 uint))
  (validity-days uint)
  (contact-info (string-ascii 100))
)
  (let ((authority-id (var-get next-validator-id)))
    (map-set certification-authorities authority-id {
      name: name,
      accreditation-body: accreditation-body,
      certification-types: cert-types,
      validity-period-days: validity-days,
      contact-info: contact-info,
      reputation-score: u50,
      active-status: true,
      registered-at: block-height
    })
    (var-set next-validator-id (+ authority-id u1))
    (ok authority-id)
  )
)

;; Issue a new certification for a product
(define-public (issue-certification
  (product-id uint)
  (cert-type uint)
  (certifying-authority uint)
  (cert-number (string-ascii 30))
  (verification-hash (string-ascii 64))
  (audit-score uint)
)
  (let ((cert-id (var-get next-certification-id)))
    (asserts! (<= audit-score u100) ERR_INVALID_RATING)
    (asserts! (is-some (map-get? certification-authorities certifying-authority)) ERR_VALIDATOR_NOT_FOUND)
    
    (match (map-get? certification-authorities certifying-authority)
      authority-data
      (let ((validity-days (get validity-period-days authority-data))
            (expiry-date (+ block-height validity-days)))
        (map-set product-certifications cert-id {
          product-id: product-id,
          certification-type: cert-type,
          certifying-authority: certifying-authority,
          issue-date: block-height,
          expiry-date: expiry-date,
          certification-number: cert-number,
          verification-hash: verification-hash,
          audit-score: audit-score,
          valid-status: true
        })
        (var-set next-certification-id (+ cert-id u1))
        (ok cert-id)
      )
      ERR_VALIDATOR_NOT_FOUND
    )
  )
)

;; Validate a certification's authenticity
(define-public (validate-certification (cert-id uint) (verification-hash (string-ascii 64)))
  (match (map-get? product-certifications cert-id)
    cert-data
    (let ((stored-hash (get verification-hash cert-data))
          (expiry-date (get expiry-date cert-data)))
      (if (and (is-eq stored-hash verification-hash) (> expiry-date block-height))
        (ok true)
        (ok false)
      )
    )
    ERR_CERTIFICATION_NOT_FOUND
  )
)

;; Register sustainability validator
(define-public (register-validator
  (name (string-ascii 50))
  (specialization (string-ascii 50))
  (credentials (list 5 (string-ascii 30)))
  (contact-info (string-ascii 100))
)
  (let ((validator-id (var-get next-validator-id)))
    (map-set sustainability-validators validator-id {
      name: name,
      specialization: specialization,
      credentials: credentials,
      validation-count: u0,
      success-rate: u0,
      contact-info: contact-info,
      active-status: true,
      registered-at: block-height
    })
    (var-set next-validator-id (+ validator-id u1))
    (ok validator-id)
  )
)

;; Create consumer transparency record
(define-public (create-transparency-record
  (product-id uint)
  (sustainability-label (string-ascii 20))
  (environmental-score uint)
  (social-score uint)
  (qr-code-data (string-ascii 100))
)
  (begin
    (asserts! (<= environmental-score u100) ERR_INVALID_RATING)
    (asserts! (<= social-score u100) ERR_INVALID_RATING)
    
    (let ((transparency-level (/ (+ environmental-score social-score) u2)))
      (map-set consumer-transparency product-id {
        sustainability-label: sustainability-label,
        environmental-score: environmental-score,
        social-score: social-score,
        transparency-level: transparency-level,
        qr-code-data: qr-code-data,
        consumer-accessible: true,
        last-updated: block-height,
        verification-status: (>= transparency-level u70)
      })
      (ok transparency-level)
    )
  )
)

;; Register consumer
(define-public (register-consumer
  (organic-pref bool)
  (fair-trade-pref bool)
  (local-pref bool)
  (recycled-pref bool)
)
  (let ((consumer-id (var-get next-consumer-id)))
    (map-set consumer-registry consumer-id {
      wallet-address: tx-sender,
      sustainability-preferences: {
        organic-preference: organic-pref,
        fair-trade-preference: fair-trade-pref,
        local-sourcing-preference: local-pref,
        recycled-content-preference: recycled-pref
      },
      education-level: u0,
      engagement-score: u0,
      feedback-count: u0,
      registered-at: block-height
    })
    (var-set next-consumer-id (+ consumer-id u1))
    (ok consumer-id)
  )
)

;; Submit consumer feedback
(define-public (submit-feedback
  (product-id uint)
  (consumer-id uint)
  (sustainability-rating uint)
  (transparency-rating uint)
  (overall-satisfaction uint)
  (feedback-text (string-ascii 200))
  (verified-purchase bool)
)
  (let ((feedback-id (var-get next-feedback-id)))
    (asserts! (<= sustainability-rating u5) ERR_INVALID_RATING)
    (asserts! (<= transparency-rating u5) ERR_INVALID_RATING)
    (asserts! (<= overall-satisfaction u5) ERR_INVALID_RATING)
    (asserts! (is-some (map-get? consumer-registry consumer-id)) ERR_CONSUMER_NOT_FOUND)
    
    (map-set consumer-feedback feedback-id {
      product-id: product-id,
      consumer-id: consumer-id,
      sustainability-rating: sustainability-rating,
      transparency-rating: transparency-rating,
      overall-satisfaction: overall-satisfaction,
      feedback-text: feedback-text,
      verified-purchase: verified-purchase,
      feedback-date: block-height
    })
    
    ;; Update consumer feedback count
    (match (map-get? consumer-registry consumer-id)
      consumer-data
      (map-set consumer-registry consumer-id 
        (merge consumer-data {feedback-count: (+ (get feedback-count consumer-data) u1)}))
      true
    )
    
    (var-set next-feedback-id (+ feedback-id u1))
    (ok feedback-id)
  )
)

;; Record sustainability impact metrics
(define-public (record-impact-metrics
  (product-id uint)
  (carbon-reduction uint)
  (water-saved uint)
  (waste-diverted uint)
  (renewable-energy uint)
  (circular-materials-pct uint)
  (biodiversity-score uint)
  (social-impact uint)
  (economic-benefit uint)
)
  (begin
    (asserts! (<= circular-materials-pct u100) ERR_INVALID_RATING)
    (asserts! (<= biodiversity-score u100) ERR_INVALID_RATING)
    (asserts! (<= social-impact u100) ERR_INVALID_RATING)
    (asserts! (<= economic-benefit u100) ERR_INVALID_RATING)
    
    (map-set impact-metrics product-id {
      carbon-footprint-reduction: carbon-reduction,
      water-saved-liters: water-saved,
      waste-diverted-kg: waste-diverted,
      renewable-energy-used: renewable-energy,
      circular-materials-percentage: circular-materials-pct,
      biodiversity-impact-score: biodiversity-score,
      social-impact-score: social-impact,
      economic-benefit-score: economic-benefit
    })
    (ok true)
  )
)

;; Update compliance monitoring
(define-public (update-compliance-record
  (product-id uint)
  (compliance-pct uint)
  (violations uint)
  (corrective-actions (list 5 (string-ascii 50)))
  (risk-level uint)
)
  (begin
    (asserts! (<= compliance-pct u100) ERR_INVALID_RATING)
    (asserts! (<= risk-level u5) ERR_INVALID_RATING)
    
    (map-set compliance-records product-id {
      last-audit-date: block-height,
      compliance-percentage: compliance-pct,
      violations-count: violations,
      corrective-actions: corrective-actions,
      next-audit-due: (+ block-height u365), ;; Next audit in 365 blocks
      compliance-officer: tx-sender,
      risk-level: risk-level
    })
    (ok true)
  )
)

;; Calculate comprehensive sustainability score
(define-public (calculate-comprehensive-score (product-id uint))
  (let (
    (transparency-data (map-get? consumer-transparency product-id))
    (impact-data (map-get? impact-metrics product-id))
    (compliance-data (map-get? compliance-records product-id))
  )
    (match transparency-data
      trans-data
      (match impact-data
        impact-data-val
        (match compliance-data
          comp-data
          (let (
            (env-score (get environmental-score trans-data))
            (social-score (get social-score trans-data))
            (biodiversity-score (get biodiversity-impact-score impact-data-val))
            (circular-score (get circular-materials-percentage impact-data-val))
            (compliance-score (get compliance-percentage comp-data))
            
            ;; Weighted comprehensive score calculation
            (comprehensive-score (/ (+ 
              (* env-score u3)
              (* social-score u2)
              (* biodiversity-score u2)
              (* circular-score u2)
              (* compliance-score u1)
            ) u10))
          )
            (ok comprehensive-score)
          )
          ;; If compliance data missing, use reduced calculation
          (let (
            (env-score (get environmental-score trans-data))
            (social-score (get social-score trans-data))
            (biodiversity-score (get biodiversity-impact-score impact-data-val))
            (circular-score (get circular-materials-percentage impact-data-val))
            (reduced-score (/ (+ (* env-score u3) (* social-score u3) (* biodiversity-score u2) (* circular-score u2)) u10))
          )
            (ok reduced-score)
          )
        )
        ;; If impact data missing, use basic calculation
        (ok (/ (+ (get environmental-score trans-data) (get social-score trans-data)) u2))
      )
      ERR_INSUFFICIENT_DATA
    )
  )
)

;; Read-only functions

;; Get certification details
(define-read-only (get-certification (cert-id uint))
  (map-get? product-certifications cert-id)
)

;; Get certification authority details
(define-read-only (get-certification-authority (authority-id uint))
  (map-get? certification-authorities authority-id)
)

;; Get validator information
(define-read-only (get-validator (validator-id uint))
  (map-get? sustainability-validators validator-id)
)

;; Get consumer transparency information
(define-read-only (get-transparency-info (product-id uint))
  (map-get? consumer-transparency product-id)
)

;; Get consumer feedback
(define-read-only (get-feedback (feedback-id uint))
  (map-get? consumer-feedback feedback-id)
)

;; Get impact metrics
(define-read-only (get-impact-metrics (product-id uint))
  (map-get? impact-metrics product-id)
)

;; Get compliance record
(define-read-only (get-compliance-record (product-id uint))
  (map-get? compliance-records product-id)
)

;; Get consumer information
(define-read-only (get-consumer (consumer-id uint))
  (map-get? consumer-registry consumer-id)
)

;; Check if certification is valid
(define-read-only (is-certification-valid (cert-id uint))
  (match (map-get? product-certifications cert-id)
    cert-data
    (and (get valid-status cert-data) (> (get expiry-date cert-data) block-height))
    false
  )
)

;; Get product sustainability grade
(define-read-only (get-sustainability-grade (product-id uint))
  (match (map-get? consumer-transparency product-id)
    transparency-data
    (let ((score (get transparency-level transparency-data)))
      (if (>= score u90)
        "A+"
        (if (>= score u80)
          "A"
          (if (>= score u70)
            "B"
            (if (>= score u60)
              "C"
              "D"
            )
          )
        )
      )
    )
    "Not Rated"
  )
)

;; Check product certifications count
(define-read-only (get-certification-count (product-id uint))
  (fold count-valid-certifications (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10) u0)
)

;; Helper function for counting certifications
(define-private (count-valid-certifications (cert-id uint) (count uint))
  (if (is-certification-valid cert-id)
    (+ count u1)
    count
  )
)

;; Get next available IDs
(define-read-only (get-next-certification-id) (var-get next-certification-id))
(define-read-only (get-next-validator-id) (var-get next-validator-id))
(define-read-only (get-next-consumer-id) (var-get next-consumer-id))
(define-read-only (get-next-feedback-id) (var-get next-feedback-id))
