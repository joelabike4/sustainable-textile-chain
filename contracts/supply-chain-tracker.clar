;; Sustainable Textile Supply Chain Tracker
;; This contract manages the complete lifecycle of textile products from fiber sourcing to consumer delivery

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_PRODUCT_NOT_FOUND (err u101))
(define-constant ERR_SUPPLIER_NOT_FOUND (err u102))
(define-constant ERR_INVALID_STAGE (err u103))
(define-constant ERR_ALREADY_EXISTS (err u104))
(define-constant ERR_INVALID_SCORE (err u105))
(define-constant ERR_INSUFFICIENT_CERTIFICATIONS (err u106))

;; Data Variables
(define-data-var next-product-id uint u1)
(define-data-var next-supplier-id uint u1)
(define-data-var next-batch-id uint u1)

;; Supply Chain Stages
(define-constant STAGE_FIBER_SOURCING u1)
(define-constant STAGE_SPINNING u2)
(define-constant STAGE_DYEING u3)
(define-constant STAGE_WEAVING u4)
(define-constant STAGE_MANUFACTURING u5)
(define-constant STAGE_QUALITY_CONTROL u6)
(define-constant STAGE_PACKAGING u7)
(define-constant STAGE_DISTRIBUTION u8)
(define-constant STAGE_RETAIL u9)

;; Data Maps

;; Supplier Information Map
(define-map suppliers
  uint
  {
    name: (string-ascii 50),
    location: (string-ascii 100),
    sustainability-score: uint,
    certifications: (list 10 (string-ascii 20)),
    compliance-status: bool,
    registered-at: uint,
    contact-info: (string-ascii 100)
  }
)

;; Product Information Map
(define-map products
  uint
  {
    name: (string-ascii 50),
    fiber-type: (string-ascii 30),
    origin-country: (string-ascii 30),
    current-stage: uint,
    sustainability-score: uint,
    created-at: uint,
    updated-at: uint,
    batch-id: uint,
    owner: principal
  }
)

;; Environmental Impact Tracking
(define-map environmental-impact
  uint ;; product-id
  {
    water-usage-liters: uint,
    carbon-footprint-kg: uint,
    energy-consumption-kwh: uint,
    chemical-usage-kg: uint,
    waste-generated-kg: uint,
    renewable-energy-percentage: uint,
    recycled-content-percentage: uint
  }
)

;; Labor Conditions Tracking
(define-map labor-conditions
  uint ;; supplier-id
  {
    worker-safety-score: uint,
    fair-wage-compliance: bool,
    working-hours-compliance: bool,
    child-labor-free: bool,
    worker-rights-score: uint,
    audit-date: uint,
    certified-fair-trade: bool
  }
)

;; Chemical Safety Tracking
(define-map chemical-safety
  uint ;; product-id
  {
    restricted-substances-free: bool,
    oeko-tex-certified: bool,
    reach-compliant: bool,
    chemical-safety-score: uint,
    test-date: uint,
    test-lab: (string-ascii 50),
    certification-number: (string-ascii 30)
  }
)

;; Production Batches
(define-map production-batches
  uint
  {
    supplier-id: uint,
    production-date: uint,
    quantity: uint,
    quality-score: uint,
    sustainability-metrics: {
      organic-certified: bool,
      recycled-content: uint,
      water-efficient: bool,
      carbon-neutral: bool
    }
  }
)

;; Supply Chain History - tracks movement through stages
(define-map supply-chain-history
  {product-id: uint, stage: uint}
  {
    timestamp: uint,
    location: (string-ascii 100),
    responsible-party: principal,
    quality-metrics: {
      temperature: uint,
      humidity: uint,
      quality-score: uint
    },
    notes: (string-ascii 200)
  }
)

;; Waste and Circular Economy Tracking
(define-map circular-economy
  uint ;; product-id
  {
    recyclable-percentage: uint,
    biodegradable-percentage: uint,
    upcycling-potential: bool,
    end-of-life-plan: (string-ascii 100),
    circular-score: uint,
    waste-reduction-achieved: uint
  }
)

;; Public Functions

;; Register a new supplier
(define-public (register-supplier 
  (name (string-ascii 50))
  (location (string-ascii 100))
  (certifications (list 10 (string-ascii 20)))
  (contact-info (string-ascii 100))
)
  (let ((supplier-id (var-get next-supplier-id)))
    (map-set suppliers supplier-id {
      name: name,
      location: location,
      sustainability-score: u0,
      certifications: certifications,
      compliance-status: false,
      registered-at: block-height,
      contact-info: contact-info
    })
    (var-set next-supplier-id (+ supplier-id u1))
    (ok supplier-id)
  )
)

;; Update supplier sustainability score
(define-public (update-supplier-score (supplier-id uint) (score uint))
  (begin
    (asserts! (<= score u100) ERR_INVALID_SCORE)
    (match (map-get? suppliers supplier-id)
      supplier-data (begin
        (map-set suppliers supplier-id (merge supplier-data {sustainability-score: score}))
        (ok true)
      )
      ERR_SUPPLIER_NOT_FOUND
    )
  )
)

;; Record labor conditions for a supplier
(define-public (record-labor-conditions
  (supplier-id uint)
  (safety-score uint)
  (fair-wage bool)
  (working-hours bool)
  (child-labor-free bool)
  (worker-rights-score uint)
  (certified-fair-trade bool)
)
  (begin
    (asserts! (<= safety-score u100) ERR_INVALID_SCORE)
    (asserts! (<= worker-rights-score u100) ERR_INVALID_SCORE)
    (asserts! (is-some (map-get? suppliers supplier-id)) ERR_SUPPLIER_NOT_FOUND)
    (map-set labor-conditions supplier-id {
      worker-safety-score: safety-score,
      fair-wage-compliance: fair-wage,
      working-hours-compliance: working-hours,
      child-labor-free: child-labor-free,
      worker-rights-score: worker-rights-score,
      audit-date: block-height,
      certified-fair-trade: certified-fair-trade
    })
    (ok true)
  )
)

;; Create a new production batch
(define-public (create-production-batch
  (supplier-id uint)
  (quantity uint)
  (organic-cert bool)
  (recycled-content uint)
  (water-efficient bool)
  (carbon-neutral bool)
)
  (let ((batch-id (var-get next-batch-id)))
    (asserts! (is-some (map-get? suppliers supplier-id)) ERR_SUPPLIER_NOT_FOUND)
    (asserts! (<= recycled-content u100) ERR_INVALID_SCORE)
    (map-set production-batches batch-id {
      supplier-id: supplier-id,
      production-date: block-height,
      quantity: quantity,
      quality-score: u0,
      sustainability-metrics: {
        organic-certified: organic-cert,
        recycled-content: recycled-content,
        water-efficient: water-efficient,
        carbon-neutral: carbon-neutral
      }
    })
    (var-set next-batch-id (+ batch-id u1))
    (ok batch-id)
  )
)

;; Register a new product
(define-public (register-product
  (name (string-ascii 50))
  (fiber-type (string-ascii 30))
  (origin-country (string-ascii 30))
  (batch-id uint)
)
  (let ((product-id (var-get next-product-id)))
    (asserts! (is-some (map-get? production-batches batch-id)) ERR_PRODUCT_NOT_FOUND)
    (map-set products product-id {
      name: name,
      fiber-type: fiber-type,
      origin-country: origin-country,
      current-stage: STAGE_FIBER_SOURCING,
      sustainability-score: u0,
      created-at: block-height,
      updated-at: block-height,
      batch-id: batch-id,
      owner: tx-sender
    })
    (var-set next-product-id (+ product-id u1))
    (ok product-id)
  )
)

;; Record environmental impact for a product
(define-public (record-environmental-impact
  (product-id uint)
  (water-usage uint)
  (carbon-footprint uint)
  (energy-consumption uint)
  (chemical-usage uint)
  (waste-generated uint)
  (renewable-energy-pct uint)
  (recycled-content-pct uint)
)
  (begin
    (asserts! (is-some (map-get? products product-id)) ERR_PRODUCT_NOT_FOUND)
    (asserts! (<= renewable-energy-pct u100) ERR_INVALID_SCORE)
    (asserts! (<= recycled-content-pct u100) ERR_INVALID_SCORE)
    (map-set environmental-impact product-id {
      water-usage-liters: water-usage,
      carbon-footprint-kg: carbon-footprint,
      energy-consumption-kwh: energy-consumption,
      chemical-usage-kg: chemical-usage,
      waste-generated-kg: waste-generated,
      renewable-energy-percentage: renewable-energy-pct,
      recycled-content-percentage: recycled-content-pct
    })
    (ok true)
  )
)

;; Record chemical safety data
(define-public (record-chemical-safety
  (product-id uint)
  (restricted-free bool)
  (oeko-tex bool)
  (reach-compliant bool)
  (safety-score uint)
  (test-lab (string-ascii 50))
  (cert-number (string-ascii 30))
)
  (begin
    (asserts! (is-some (map-get? products product-id)) ERR_PRODUCT_NOT_FOUND)
    (asserts! (<= safety-score u100) ERR_INVALID_SCORE)
    (map-set chemical-safety product-id {
      restricted-substances-free: restricted-free,
      oeko-tex-certified: oeko-tex,
      reach-compliant: reach-compliant,
      chemical-safety-score: safety-score,
      test-date: block-height,
      test-lab: test-lab,
      certification-number: cert-number
    })
    (ok true)
  )
)

;; Move product to next stage in supply chain
(define-public (advance-product-stage
  (product-id uint)
  (location (string-ascii 100))
  (quality-score uint)
  (notes (string-ascii 200))
)
  (match (map-get? products product-id)
    product-data
    (let ((current-stage (get current-stage product-data))
          (next-stage (+ current-stage u1)))
      (asserts! (<= next-stage STAGE_RETAIL) ERR_INVALID_STAGE)
      (asserts! (<= quality-score u100) ERR_INVALID_SCORE)
      
      ;; Record the stage transition
      (map-set supply-chain-history {product-id: product-id, stage: next-stage} {
        timestamp: block-height,
        location: location,
        responsible-party: tx-sender,
        quality-metrics: {
          temperature: u20,
          humidity: u50,
          quality-score: quality-score
        },
        notes: notes
      })
      
      ;; Update product current stage
      (map-set products product-id (merge product-data {
        current-stage: next-stage,
        updated-at: block-height
      }))
      
      (ok next-stage)
    )
    ERR_PRODUCT_NOT_FOUND
  )
)

;; Record circular economy data
(define-public (record-circular-economy
  (product-id uint)
  (recyclable-pct uint)
  (biodegradable-pct uint)
  (upcycling-potential bool)
  (end-of-life-plan (string-ascii 100))
  (waste-reduction uint)
)
  (begin
    (asserts! (is-some (map-get? products product-id)) ERR_PRODUCT_NOT_FOUND)
    (asserts! (<= recyclable-pct u100) ERR_INVALID_SCORE)
    (asserts! (<= biodegradable-pct u100) ERR_INVALID_SCORE)
    (let ((circular-score (/ (+ recyclable-pct biodegradable-pct) u2)))
      (map-set circular-economy product-id {
        recyclable-percentage: recyclable-pct,
        biodegradable-percentage: biodegradable-pct,
        upcycling-potential: upcycling-potential,
        end-of-life-plan: end-of-life-plan,
        circular-score: circular-score,
        waste-reduction-achieved: waste-reduction
      })
      (ok circular-score)
    )
  )
)

;; Calculate overall sustainability score for a product
(define-public (calculate-sustainability-score (product-id uint))
  (match (map-get? products product-id)
    product-data
    (let (
      (env-data (default-to 
        {water-usage-liters: u0, carbon-footprint-kg: u0, energy-consumption-kwh: u0, 
         chemical-usage-kg: u0, waste-generated-kg: u0, renewable-energy-percentage: u0, recycled-content-percentage: u0}
        (map-get? environmental-impact product-id)))
      (chem-data (default-to
        {restricted-substances-free: false, oeko-tex-certified: false, reach-compliant: false,
         chemical-safety-score: u0, test-date: u0, test-lab: "", certification-number: ""}
        (map-get? chemical-safety product-id)))
      (circular-data (default-to
        {recyclable-percentage: u0, biodegradable-percentage: u0, upcycling-potential: false,
         end-of-life-plan: "", circular-score: u0, waste-reduction-achieved: u0}
        (map-get? circular-economy product-id)))
      
      ;; Calculate component scores
      (env-score (/ (+ (get renewable-energy-percentage env-data) (get recycled-content-percentage env-data)) u2))
      (chem-score (get chemical-safety-score chem-data))
      (circular-score (get circular-score circular-data))
      
      ;; Calculate overall score (weighted average)
      (overall-score (/ (+ (* env-score u4) (* chem-score u3) (* circular-score u3)) u10))
    )
      ;; Update product with calculated score
      (map-set products product-id (merge product-data {sustainability-score: overall-score}))
      (ok overall-score)
    )
    ERR_PRODUCT_NOT_FOUND
  )
)

;; Read-only functions

;; Get product information
(define-read-only (get-product (product-id uint))
  (map-get? products product-id)
)

;; Get supplier information
(define-read-only (get-supplier (supplier-id uint))
  (map-get? suppliers supplier-id)
)

;; Get environmental impact data
(define-read-only (get-environmental-impact (product-id uint))
  (map-get? environmental-impact product-id)
)

;; Get labor conditions
(define-read-only (get-labor-conditions (supplier-id uint))
  (map-get? labor-conditions supplier-id)
)

;; Get chemical safety data
(define-read-only (get-chemical-safety (product-id uint))
  (map-get? chemical-safety product-id)
)

;; Get production batch info
(define-read-only (get-production-batch (batch-id uint))
  (map-get? production-batches batch-id)
)

;; Get supply chain history for a specific stage
(define-read-only (get-stage-history (product-id uint) (stage uint))
  (map-get? supply-chain-history {product-id: product-id, stage: stage})
)

;; Get circular economy data
(define-read-only (get-circular-economy (product-id uint))
  (map-get? circular-economy product-id)
)

;; Get complete product lifecycle data
(define-read-only (get-product-lifecycle (product-id uint))
  (let ((product (map-get? products product-id)))
    (if (is-some product)
      (some {
        product: product,
        environmental: (map-get? environmental-impact product-id),
        chemical-safety: (map-get? chemical-safety product-id),
        circular-economy: (map-get? circular-economy product-id)
      })
      none
    )
  )
)

;; Check if product meets sustainability standards
(define-read-only (meets-sustainability-standards (product-id uint))
  (match (map-get? products product-id)
    product-data
    (let ((score (get sustainability-score product-data)))
      (>= score u70) ;; 70% threshold for sustainability compliance
    )
    false
  )
)

;; Get next available IDs
(define-read-only (get-next-product-id) (var-get next-product-id))
(define-read-only (get-next-supplier-id) (var-get next-supplier-id))
(define-read-only (get-next-batch-id) (var-get next-batch-id))
