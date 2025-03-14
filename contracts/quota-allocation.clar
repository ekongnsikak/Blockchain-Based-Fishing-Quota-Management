;; Quota Allocation Contract
;; Manages the allocation of fishing quotas to vessels or companies

(define-data-var admin principal tx-sender)

;; Map of vessel/company to their allocated quota by species
(define-map quotas
  { owner: principal, species: (string-ascii 64) }
  { amount: uint, season: uint }
)

;; List of all registered fishing entities
(define-map registered-entities
  principal
  { name: (string-ascii 64), active: bool }
)

;; Initialize the contract
(define-public (initialize)
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1))
    (ok true)
  )
)

;; Register a new fishing entity
(define-public (register-entity (entity principal) (name (string-ascii 64)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u2))
    (map-set registered-entities entity { name: name, active: true })
    (ok true)
  )
)

;; Allocate quota to a fishing entity
(define-public (allocate-quota (entity principal) (species (string-ascii 64)) (amount uint) (season uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u3))
    (asserts! (is-some (map-get? registered-entities entity)) (err u4))
    (map-set quotas { owner: entity, species: species } { amount: amount, season: season })
    (ok true)
  )
)

;; Get quota for a specific entity and species
(define-read-only (get-quota (entity principal) (species (string-ascii 64)))
  (default-to { amount: u0, season: u0 }
    (map-get? quotas { owner: entity, species: species }))
)

;; Check if an entity is registered
(define-read-only (is-registered (entity principal))
  (is-some (map-get? registered-entities entity))
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u5))
    (var-set admin new-admin)
    (ok true)
  )
)

