;; Quota Trading Contract
;; Facilitates buying and selling of fishing rights

(define-data-var admin principal tx-sender)

;; Map to track entity registration status (simplified from quota-allocation)
(define-map registered-entities
  principal
  { active: bool }
)

;; Map to track entity quotas (simplified from quota-allocation)
(define-map entity-quotas
  { entity: principal, species: (string-ascii 64) }
  { amount: uint, season: uint }
)

;; Structure for quota listings
(define-map quota-listings
  uint
  {
    seller: principal,
    species: (string-ascii 64),
    amount: uint,
    price: uint,
    season: uint,
    active: bool
  }
)

;; Counter for listing IDs
(define-data-var next-listing-id uint u1)

;; Register an entity (admin only)
(define-public (register-entity (entity principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1))
    (map-set registered-entities entity { active: true })
    (ok true)
  )
)

;; Set quota for an entity (admin only)
(define-public (set-quota (entity principal) (species (string-ascii 64)) (amount uint) (season uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u2))
    (map-set entity-quotas { entity: entity, species: species } { amount: amount, season: season })
    (ok true)
  )
)

;; Create a new quota listing
(define-public (create-listing
  (species (string-ascii 64))
  (amount uint)
  (price uint)
  (season uint)
)
  (let (
    (entity tx-sender)
    (quota (default-to { amount: u0, season: u0 }
            (map-get? entity-quotas { entity: entity, species: species })))
    (listing-id (var-get next-listing-id))
  )
    (asserts! (is-some (map-get? registered-entities entity)) (err u3))
    (asserts! (>= (get amount quota) amount) (err u4))
    (asserts! (is-eq (get season quota) season) (err u5))

    ;; Create the listing
    (map-set quota-listings
      listing-id
      {
        seller: entity,
        species: species,
        amount: amount,
        price: price,
        season: season,
        active: true
      }
    )

    ;; Increment the listing ID counter
    (var-set next-listing-id (+ listing-id u1))

    (ok listing-id)
  )
)

;; Purchase a quota listing
(define-public (purchase-listing (listing-id uint))
  (let (
    (buyer tx-sender)
    (listing (unwrap! (map-get? quota-listings listing-id) (err u6)))
  )
    (asserts! (is-some (map-get? registered-entities buyer)) (err u7))
    (asserts! (not (is-eq buyer (get seller listing))) (err u8))
    (asserts! (get active listing) (err u9))

    ;; Transfer STX from buyer to seller
    (try! (stx-transfer? (get price listing) buyer (get seller listing)))

    ;; Update the listing to inactive
    (map-set quota-listings
      listing-id
      (merge listing { active: false })
    )

    ;; Update quota for buyer (add)
    (let (
      (buyer-quota (default-to { amount: u0, season: (get season listing) }
                   (map-get? entity-quotas { entity: buyer, species: (get species listing) })))
      (new-amount (+ (get amount buyer-quota) (get amount listing)))
    )
      (map-set entity-quotas
        { entity: buyer, species: (get species listing) }
        { amount: new-amount, season: (get season listing) })
    )

    ;; Update quota for seller (subtract)
    (let (
      (seller-quota (default-to { amount: u0, season: (get season listing) }
                    (map-get? entity-quotas { entity: (get seller listing), species: (get species listing) })))
      (new-amount (- (get amount seller-quota) (get amount listing)))
    )
      (map-set entity-quotas
        { entity: (get seller listing), species: (get species listing) }
        { amount: new-amount, season: (get season listing) })
    )

    (ok true)
  )
)

;; Cancel a listing
(define-public (cancel-listing (listing-id uint))
  (let (
    (listing (unwrap! (map-get? quota-listings listing-id) (err u10)))
  )
    (asserts! (is-eq tx-sender (get seller listing)) (err u11))
    (asserts! (get active listing) (err u12))

    ;; Update the listing to inactive
    (map-set quota-listings
      listing-id
      (merge listing { active: false })
    )

    (ok true)
  )
)

;; Get listing details
(define-read-only (get-listing (listing-id uint))
  (map-get? quota-listings listing-id)
)

;; Get quota for an entity
(define-read-only (get-quota (entity principal) (species (string-ascii 64)))
  (default-to { amount: u0, season: u0 }
    (map-get? entity-quotas { entity: entity, species: species }))
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u13))
    (var-set admin new-admin)
    (ok true)
  )
)

