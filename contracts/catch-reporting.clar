;; Catch Reporting Contract
;; Records actual fish harvested by species

(define-data-var admin principal tx-sender)

;; Map to track reported catches
(define-map catches
  { entity: principal, species: (string-ascii 64), season: uint }
  { reported-amount: uint, timestamp: uint }
)

;; Map to track total catches by species and season
(define-map total-catches
  { species: (string-ascii 64), season: uint }
  { amount: uint }
)

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

;; Report a catch
(define-public (report-catch (species (string-ascii 64)) (amount uint) (season uint))
  (let (
    (entity tx-sender)
    (quota (default-to { amount: u0, season: u0 }
            (map-get? entity-quotas { entity: entity, species: species })))
    (current-catch (default-to { reported-amount: u0, timestamp: u0 }
                    (map-get? catches { entity: entity, species: species, season: season })))
    (total-catch (default-to { amount: u0 }
                  (map-get? total-catches { species: species, season: season })))
    (new-reported-amount (+ (get reported-amount current-catch) amount))
  )
    (asserts! (is-some (map-get? registered-entities entity)) (err u3))
    (asserts! (<= new-reported-amount (get amount quota)) (err u4))

    ;; Update individual catch record
    (map-set catches
      { entity: entity, species: species, season: season }
      { reported-amount: new-reported-amount, timestamp: block-height }
    )

    ;; Update total catch for species and season
    (map-set total-catches
      { species: species, season: season }
      { amount: (+ (get amount total-catch) amount) }
    )

    (ok true)
  )
)

;; Get reported catch for an entity
(define-read-only (get-reported-catch (entity principal) (species (string-ascii 64)) (season uint))
  (default-to { reported-amount: u0, timestamp: u0 }
    (map-get? catches { entity: entity, species: species, season: season }))
)

;; Get total catch for a species in a season
(define-read-only (get-total-catch (species (string-ascii 64)) (season uint))
  (default-to { amount: u0 }
    (map-get? total-catches { species: species, season: season }))
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u5))
    (var-set admin new-admin)
    (ok true)
  )
)

