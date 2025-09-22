
;; title: SupplyMaster
;; version: 1.0.0
;; summary: Supply chain tracking smart contract for unified multi-industry product tracking and verification
;; description: A comprehensive supply chain management system that enables product tracking, verification, and lifecycle management across multiple industries

;; traits
;;

;; token definitions
;;

;; constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u401))
(define-constant ERR_PRODUCT_NOT_FOUND (err u404))
(define-constant ERR_PRODUCT_ALREADY_EXISTS (err u409))
(define-constant ERR_INVALID_STATUS (err u400))
(define-constant ERR_INVALID_PARTICIPANT (err u402))

;; Product status constants
(define-constant STATUS_CREATED u1)
(define-constant STATUS_IN_TRANSIT u2)
(define-constant STATUS_DELIVERED u3)
(define-constant STATUS_VERIFIED u4)
(define-constant STATUS_RECALLED u5)

;; data vars
(define-data-var next-product-id uint u1)

;; data maps
;; Product registry - maps product ID to product details
(define-map products
  { product-id: uint }
  {
    name: (string-ascii 100),
    description: (string-ascii 500),
    manufacturer: principal,
    created-at: uint,
    status: uint,
    current-owner: principal,
    industry: (string-ascii 50),
    batch-number: (string-ascii 50),
    expiry-date: (optional uint)
  }
)

;; Supply chain events - tracks all events for a product
(define-map supply-chain-events
  { event-id: uint }
  {
    product-id: uint,
    event-type: (string-ascii 50),
    timestamp: uint,
    location: (string-ascii 100),
    actor: principal,
    details: (string-ascii 300)
  }
)

;; Event counter for unique event IDs
(define-data-var next-event-id uint u1)

;; Authorized participants (manufacturers, distributors, retailers, etc.)
(define-map authorized-participants
  { participant: principal }
  {
    name: (string-ascii 100),
    role: (string-ascii 50),
    authorized-by: principal,
    authorized-at: uint
  }
)

;; Product verification records
(define-map verifications
  { product-id: uint, verifier: principal }
  {
    verified-at: uint,
    verification-status: bool,
    notes: (string-ascii 300)
  }
)

;; public functions

;; Authorize a new participant in the supply chain
(define-public (authorize-participant (participant principal) (name (string-ascii 100)) (role (string-ascii 50)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set authorized-participants
      { participant: participant }
      {
        name: name,
        role: role,
        authorized-by: tx-sender,
        authorized-at: block-height
      }
    )
    (ok participant)
  )
)

;; Create a new product in the supply chain
(define-public (create-product
  (name (string-ascii 100))
  (description (string-ascii 500))
  (industry (string-ascii 50))
  (batch-number (string-ascii 50))
  (expiry-date (optional uint))
)
  (let
    (
      (product-id (var-get next-product-id))
      (participant-info (map-get? authorized-participants { participant: tx-sender }))
    )
    (asserts! (is-some participant-info) ERR_UNAUTHORIZED)
    (asserts! (is-none (map-get? products { product-id: product-id })) ERR_PRODUCT_ALREADY_EXISTS)

    ;; Create the product
    (map-set products
      { product-id: product-id }
      {
        name: name,
        description: description,
        manufacturer: tx-sender,
        created-at: block-height,
        status: STATUS_CREATED,
        current-owner: tx-sender,
        industry: industry,
        batch-number: batch-number,
        expiry-date: expiry-date
      }
    )

    ;; Record the creation event
    (unwrap-panic (add-supply-chain-event
      product-id
      "CREATED"
      "Manufacturing facility"
      (concat "Product created by manufacturer: " name)
    ))

    ;; Increment product ID counter
    (var-set next-product-id (+ product-id u1))
    (ok product-id)
  )
)

;; Transfer product ownership
(define-public (transfer-product (product-id uint) (new-owner principal) (location (string-ascii 100)))
  (let
    (
      (product-info (unwrap! (map-get? products { product-id: product-id }) ERR_PRODUCT_NOT_FOUND))
      (participant-info (map-get? authorized-participants { participant: tx-sender }))
      (new-owner-info (map-get? authorized-participants { participant: new-owner }))
    )
    (asserts! (is-some participant-info) ERR_UNAUTHORIZED)
    (asserts! (is-some new-owner-info) ERR_INVALID_PARTICIPANT)
    (asserts! (is-eq (get current-owner product-info) tx-sender) ERR_UNAUTHORIZED)

    ;; Update product ownership
    (map-set products
      { product-id: product-id }
      (merge product-info { current-owner: new-owner, status: STATUS_IN_TRANSIT })
    )

    ;; Record the transfer event
    (unwrap-panic (add-supply-chain-event
      product-id
      "TRANSFERRED"
      location
      (concat "Ownership transferred to: " (unwrap-panic (get name new-owner-info)))
    ))

    (ok true)
  )
)

;; Update product status
(define-public (update-product-status (product-id uint) (new-status uint) (location (string-ascii 100)) (notes (string-ascii 300)))
  (let
    (
      (product-info (unwrap! (map-get? products { product-id: product-id }) ERR_PRODUCT_NOT_FOUND))
      (participant-info (map-get? authorized-participants { participant: tx-sender }))
    )
    (asserts! (is-some participant-info) ERR_UNAUTHORIZED)
    (asserts! (or (is-eq (get current-owner product-info) tx-sender) (is-eq tx-sender CONTRACT_OWNER)) ERR_UNAUTHORIZED)
    (asserts! (<= new-status STATUS_RECALLED) ERR_INVALID_STATUS)

    ;; Update product status
    (map-set products
      { product-id: product-id }
      (merge product-info { status: new-status })
    )

    ;; Record the status update event
    (unwrap-panic (add-supply-chain-event
      product-id
      (status-to-string new-status)
      location
      notes
    ))

    (ok true)
  )
)

;; Verify a product
(define-public (verify-product (product-id uint) (verification-status bool) (notes (string-ascii 300)))
  (let
    (
      (product-info (unwrap! (map-get? products { product-id: product-id }) ERR_PRODUCT_NOT_FOUND))
      (participant-info (map-get? authorized-participants { participant: tx-sender }))
    )
    (asserts! (is-some participant-info) ERR_UNAUTHORIZED)

    ;; Record verification
    (map-set verifications
      { product-id: product-id, verifier: tx-sender }
      {
        verified-at: block-height,
        verification-status: verification-status,
        notes: notes
      }
    )

    ;; If verified successfully, update product status
    (if verification-status
      (begin
        (map-set products
          { product-id: product-id }
          (merge product-info { status: STATUS_VERIFIED })
        )
        (unwrap-panic (add-supply-chain-event
          product-id
          "VERIFIED"
          "Verification facility"
          notes
        ))
      )
      (unwrap-panic (add-supply-chain-event
        product-id
        "VERIFICATION_FAILED"
        "Verification facility"
        notes
      ))
    )

    (ok verification-status)
  )
)

;; Add a supply chain event (private helper)
(define-private (add-supply-chain-event (product-id uint) (event-type (string-ascii 50)) (location (string-ascii 100)) (details (string-ascii 300)))
  (let
    (
      (event-id (var-get next-event-id))
    )
    (map-set supply-chain-events
      { event-id: event-id }
      {
        product-id: product-id,
        event-type: event-type,
        timestamp: block-height,
        location: location,
        actor: tx-sender,
        details: details
      }
    )
    (var-set next-event-id (+ event-id u1))
    (ok event-id)
  )
)

;; read only functions

;; Get product information
(define-read-only (get-product (product-id uint))
  (map-get? products { product-id: product-id })
)

;; Get participant information
(define-read-only (get-participant (participant principal))
  (map-get? authorized-participants { participant: participant })
)

;; Get supply chain event
(define-read-only (get-supply-chain-event (event-id uint))
  (map-get? supply-chain-events { event-id: event-id })
)

;; Get verification record
(define-read-only (get-verification (product-id uint) (verifier principal))
  (map-get? verifications { product-id: product-id, verifier: verifier })
)

;; Get current product count
(define-read-only (get-product-count)
  (- (var-get next-product-id) u1)
)

;; Get current event count
(define-read-only (get-event-count)
  (- (var-get next-event-id) u1)
)

;; Check if product exists
(define-read-only (product-exists (product-id uint))
  (is-some (map-get? products { product-id: product-id }))
)

;; Check if participant is authorized
(define-read-only (is-authorized-participant (participant principal))
  (is-some (map-get? authorized-participants { participant: participant }))
)

;; Get product status as string
(define-read-only (get-product-status-string (product-id uint))
  (match (map-get? products { product-id: product-id })
    product-info (ok (status-to-string (get status product-info)))
    ERR_PRODUCT_NOT_FOUND
  )
)

;; private functions

;; Convert status code to string
(define-private (status-to-string (status uint))
  (if (is-eq status STATUS_CREATED)
    "CREATED"
    (if (is-eq status STATUS_IN_TRANSIT)
      "IN_TRANSIT"
      (if (is-eq status STATUS_DELIVERED)
        "DELIVERED"
        (if (is-eq status STATUS_VERIFIED)
          "VERIFIED"
          (if (is-eq status STATUS_RECALLED)
            "RECALLED"
            "UNKNOWN"
          )
        )
      )
    )
  )
)
