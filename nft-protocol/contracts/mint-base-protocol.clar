;; Virtual IP Rights Exchange - A decentralized platform for intellectual property trading
;; Enables creators to mint and trade their digital intellectual property with robust royalty tracking

;; System error definitions
(define-constant ACCESS-DENIED-CODE (err u201))
(define-constant ALREADY-CLAIMED-CODE (err u202))
(define-constant FUNDS-DEFICIENT-CODE (err u203))
(define-constant ITEM-NOT-FOUND-CODE (err u204))
(define-constant TRANSFER-PENDING-CODE (err u205))
(define-constant CONTENT-SIZE-LIMIT-CODE (err u206))
(define-constant COMMISSION-BOUNDS-CODE (err u207))
(define-constant VALIDITY-DURATION-CODE (err u208))
(define-constant INVALID-ITEM-REFERENCE-CODE (err u209))
(define-constant GRADE-BOUNDS-CODE (err u210))
(define-constant WITHDRAWN-STATUS-CODE (err u211))
(define-constant QUANTUM-TOO-SMALL-CODE (err u212))
(define-constant STORAGE-PATH-EMPTY-CODE (err u213))
(define-constant METADATA-EMPTY-CODE (err u214))
(define-constant SYSTEM-MAX-VALUE u2000000000)

;; Core data structures
(define-map intellectual-property-vault
  { item-handle: uint }
  {
    originator: principal,
    current-rights-holder: (optional principal),
    data-volume: uint,
    creator-commission: uint,
    rights-duration: uint,
    premium-classification: uint,
    acquisition-timestamp: (optional uint),
    cdn-path: (string-ascii 30),
    content-summary: (string-ascii 20),
    market-status: (string-ascii 20)
  }
)

(define-map wallet-ledger principal uint)

(define-map creator-merit-index principal uint)

(define-map client-acquisition-ledger
  principal
  (list 10 uint)
)

;; Core business logic implementations
(define-public (mint-virtual-asset (data-volume uint) (creator-commission uint) (rights-duration uint) 
                             (premium-classification uint) (cdn-path (string-ascii 30)) 
                             (content-summary (string-ascii 20)))
  (let ((item-handle (+ (var-get registry-sequence) u1)))
    ;; Input validation suite
    (asserts! (> data-volume u0) CONTENT-SIZE-LIMIT-CODE)
    (asserts! (<= creator-commission u50) COMMISSION-BOUNDS-CODE)
    (asserts! (and (> rights-duration u0) (<= rights-duration u10000)) VALIDITY-DURATION-CODE)
    (asserts! (and (>= premium-classification u1) (<= premium-classification u5)) GRADE-BOUNDS-CODE)
    ;; Path and metadata validation
    (asserts! (> (len cdn-path) u0) STORAGE-PATH-EMPTY-CODE)
    (asserts! (> (len content-summary) u0) METADATA-EMPTY-CODE)
    
    ;; Register the new intellectual property asset
    (map-set intellectual-property-vault 
      { item-handle: item-handle }
      {
        originator: tx-sender,
        current-rights-holder: none,
        data-volume: data-volume,
        creator-commission: creator-commission,
        rights-duration: rights-duration,
        premium-classification: premium-classification,
        acquisition-timestamp: none,
        cdn-path: cdn-path,
        content-summary: content-summary,
        market-status: "LISTED"
      }
    )
    
    ;; Update the originator's portfolio record
    (let 
      (
        (existing-portfolio (default-to (list) (map-get? client-acquisition-ledger tx-sender)))
        (refreshed-portfolio (unwrap-panic (as-max-len? (concat (list item-handle) existing-portfolio) u10)))
      )
      ;; Maintain at most 10 most recent creations
      (map-set client-acquisition-ledger tx-sender refreshed-portfolio)
    )
    
    (var-set registry-sequence item-handle)
    (ok item-handle)
  )
)

(define-public (acquire-rights (item-handle uint))
  (let (
    (asset-details (unwrap! (map-get? intellectual-property-vault { item-handle: item-handle }) ITEM-NOT-FOUND-CODE))
    (acquirer-funds (default-to u0 (map-get? wallet-ledger tx-sender)))
  )
    ;; Validate transaction parameters
    (asserts! (<= item-handle (var-get registry-sequence)) INVALID-ITEM-REFERENCE-CODE)
    (asserts! (is-none (get current-rights-holder asset-details)) ALREADY-CLAIMED-CODE)
    (asserts! (is-eq (get market-status asset-details) "LISTED") ITEM-NOT-FOUND-CODE)
    (asserts! (>= acquirer-funds (get data-volume asset-details)) FUNDS-DEFICIENT-CODE)
    
    ;; Update asset ownership records
    (map-set intellectual-property-vault { item-handle: item-handle }
      (merge asset-details { 
        current-rights-holder: (some tx-sender),
        acquisition-timestamp: (some block-height),
        market-status: "RIGHTS_TRANSFERRED"
      })
    )
    
    ;; Execute financial transactions
    (map-set wallet-ledger tx-sender (- acquirer-funds (get data-volume asset-details)))
    (map-set wallet-ledger (get originator asset-details) 
      (+ (default-to u0 (map-get? wallet-ledger (get originator asset-details))) (get data-volume asset-details)))
    
    (ok true)
  )
)

(define-public (finalize-acquisition (item-handle uint))
  (let (
    (asset-details (unwrap! (map-get? intellectual-property-vault { item-handle: item-handle }) ITEM-NOT-FOUND-CODE))
    (rights-holder-balance (default-to u0 (map-get? wallet-ledger tx-sender)))
    (initial-payment (get data-volume asset-details))
    (royalty-component (/ (* (get data-volume asset-details) (get creator-commission asset-details)) u100))
    (premium-surcharge (/ (* initial-payment (get premium-classification asset-details)) u100))
    (aggregate-cost (+ initial-payment royalty-component premium-surcharge))
  )
    ;; Comprehensive validation checks
    (asserts! (<= item-handle (var-get registry-sequence)) INVALID-ITEM-REFERENCE-CODE)
    (asserts! (is-eq (get current-rights-holder asset-details) (some tx-sender)) ACCESS-DENIED-CODE)
    (asserts! (is-eq (get market-status asset-details) "RIGHTS_TRANSFERRED") ITEM-NOT-FOUND-CODE)
    (asserts! (>= (- block-height (unwrap! (get acquisition-timestamp asset-details) ITEM-NOT-FOUND-CODE)) 
                (get rights-duration asset-details)) TRANSFER-PENDING-CODE)
    (asserts! (>= rights-holder-balance aggregate-cost) FUNDS-DEFICIENT-CODE)
    
    ;; Execute royalty payment
    (map-set wallet-ledger tx-sender (- rights-holder-balance aggregate-cost))
    (map-set wallet-ledger (get originator asset-details) 
      (+ (default-to u0 (map-get? wallet-ledger (get originator asset-details))) 
         aggregate-cost)
    )
    
    ;; Update creator's reputation score
    (let ((merit-score (default-to u0 (map-get? creator-merit-index 
                        (get originator asset-details)))))
      (map-set creator-merit-index
        (get originator asset-details)
        (+ merit-score u1)
      )
    )
    
    ;; Update asset lifecycle status
    (map-set intellectual-property-vault { item-handle: item-handle } 
      (merge asset-details { market-status: "ACQUISITION_COMPLETE" }))
    (ok true)
  )
)

(define-public (withdraw-from-market (item-handle uint))
  (let (
    (asset-details (unwrap! (map-get? intellectual-property-vault { item-handle: item-handle }) ITEM-NOT-FOUND-CODE))
  )
    ;; Security validations
    (asserts! (<= item-handle (var-get registry-sequence)) INVALID-ITEM-REFERENCE-CODE)
    (asserts! (is-eq (get originator asset-details) tx-sender) ACCESS-DENIED-CODE)
    (asserts! (is-eq (get market-status asset-details) "LISTED") ITEM-NOT-FOUND-CODE)
    
    ;; Change market status
    (map-set intellectual-property-vault { item-handle: item-handle } 
      (merge asset-details { market-status: "WITHDRAWN" }))
    (ok true)
  )
)

(define-public (fund-account (quantum uint))
  (let (
    (existing-balance (default-to u0 (map-get? wallet-ledger tx-sender)))
  )
    ;; Input validation
    (asserts! (> quantum u0) QUANTUM-TOO-SMALL-CODE)
    (asserts! (<= quantum SYSTEM-MAX-VALUE) QUANTUM-TOO-SMALL-CODE)
    (asserts! (<= (+ existing-balance quantum) SYSTEM-MAX-VALUE) QUANTUM-TOO-SMALL-CODE)
    
    ;; Update account balance
    (map-set wallet-ledger tx-sender (+ existing-balance quantum))
    (ok true)
  )
)

;; System query interfaces
(define-read-only (query-asset-metadata (item-handle uint))
  (map-get? intellectual-property-vault { item-handle: item-handle })
)

(define-read-only (view-account-balance (entity principal))
  (default-to u0 (map-get? wallet-ledger entity))
)

(define-read-only (fetch-creator-standing (creator principal))
  (default-to u0 (map-get? creator-merit-index creator))
)

(define-read-only (list-owned-assets (entity principal))
  (default-to (list) (map-get? client-acquisition-ledger entity))
)

;; Premium tier calculation
(define-read-only (compute-premium-factor (premium-classification uint))
  (if (and (>= premium-classification u1) (<= premium-classification u5))
      (* premium-classification u1)
      u0)  ;; Failsafe default for invalid parameters
)

;; System initialization
(define-data-var registry-sequence uint u0)