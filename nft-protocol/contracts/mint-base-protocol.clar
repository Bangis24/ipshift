;; Virtual IP Rights Exchange - Stage 1 MVP
;; Basic platform for intellectual property registration with simple ownership

;; System error definitions
(define-constant ACCESS-DENIED-CODE (err u201))
(define-constant ITEM-NOT-FOUND-CODE (err u204))
(define-constant CONTENT-SIZE-LIMIT-CODE (err u206))
(define-constant STORAGE-PATH-EMPTY-CODE (err u213))
(define-constant METADATA-EMPTY-CODE (err u214))

;; Core data structures
(define-map intellectual-property-vault
  { item-handle: uint }
  {
    originator: principal,
    data-volume: uint,
    cdn-path: (string-ascii 30),
    content-summary: (string-ascii 20),
    market-status: (string-ascii 20)
  }
)

(define-map client-acquisition-ledger
  principal
  (list 10 uint)
)

;; Core business logic implementations
(define-public (mint-virtual-asset (data-volume uint) (cdn-path (string-ascii 30)) 
                             (content-summary (string-ascii 20)))
  (let ((item-handle (+ (var-get registry-sequence) u1)))
    ;; Input validation
    (asserts! (> data-volume u0) CONTENT-SIZE-LIMIT-CODE)
    (asserts! (> (len cdn-path) u0) STORAGE-PATH-EMPTY-CODE)
    (asserts! (> (len content-summary) u0) METADATA-EMPTY-CODE)
    
    ;; Register the new intellectual property asset
    (map-set intellectual-property-vault 
      { item-handle: item-handle }
      {
        originator: tx-sender,
        data-volume: data-volume,
        cdn-path: cdn-path,
        content-summary: content-summary,
        market-status: "REGISTERED"
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

;; System query interfaces
(define-read-only (query-asset-metadata (item-handle uint))
  (map-get? intellectual-property-vault { item-handle: item-handle })
)

(define-read-only (list-owned-assets (entity principal))
  (default-to (list) (map-get? client-acquisition-ledger entity))
)

;; System initialization
(define-data-var registry-sequence uint u0)