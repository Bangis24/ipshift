;; Virtual IP Rights Exchange - Stage 2
;; Adds marketplace functionality for intellectual property trading

;; System error definitions
(define-constant ACCESS-DENIED-CODE (err u201))
(define-constant ALREADY-CLAIMED-CODE (err u202))
(define-constant FUNDS-DEFICIENT-CODE (err u203))
(define-constant ITEM-NOT-FOUND-CODE (err u204))
(define-constant CONTENT-SIZE-LIMIT-CODE (err u206))
(define-constant INVALID-ITEM-REFERENCE-CODE (err u209))
(define-constant STORAGE-PATH-EMPTY-CODE (err u213))
(define-constant METADATA-EMPTY-CODE (err u214))
(define-constant QUANTUM-TOO-SMALL-CODE (err u212))
(define-constant SYSTEM-MAX-VALUE u2000000000)

;; Core data structures
(define-map intellectual-property-vault
  { item-handle: uint }
  {
    originator: principal,
    current-rights-holder: (optional principal),
    data-volume: uint,
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
(define-public (mint-virtual-asset (data-volume uint) (cdn-path (string-ascii 30)) 
                             (content-summary (string-ascii 20)))
  (let ((item-handle (+ (var-get registry-sequence) u1)))
    ;; Input validation suite
    (asserts! (> data-volume u0) CONTENT-SIZE-LIMIT-CODE)
    (asserts! (> (len cdn-path) u0) STORAGE-PATH-EMPTY-CODE)
    (asserts! (> (len content-summary) u0) METADATA-EMPTY-CODE)
    
    ;; Register the new intellectual property asset
    (map-set intellectual-property-vault 
      { item-handle: item-handle }
      {
        originator: tx-sender,
        current-rights-holder: none,
        data-volume: data-volume,
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
        market-status: "RIGHTS_TRANSFERRED"
      })
    )
    
    ;; Execute financial transactions
    (map-set wallet-ledger tx-sender (- acquirer-funds (get data-volume asset-details)))
    (map-set wallet-ledger (get originator asset-details) 
      (+ (default-to u0 (map-get? wallet-ledger (get originator asset-details))) (get data-volume asset-details)))
    
    ;; Update creator's reputation score
    (let ((merit-score (default-to u0 (map-get? creator-merit-index 
                        (get originator asset-details)))))
      (map-set creator-merit-index
        (get originator asset-details)
        (+ merit-score u1)
      )
    )
    
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

;; System initialization
(define-data-var registry-sequence uint u0)