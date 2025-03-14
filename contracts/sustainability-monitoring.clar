;; Sustainability Monitoring Contract
;; Tracks fish populations and adjusts quotas

(define-data-var admin principal tx-sender)

;; Map to track sustainability metrics by species
(define-map sustainability-metrics
  { species: (string-ascii 64), season: uint }
  {
    population-estimate: uint,
    sustainable-catch-limit: uint,
    status: (string-ascii 10) ;; "healthy", "warning", "critical"
  }
)

;; Map to track total catches (simplified from catch-reporting)
(define-map total-catches
  { species: (string-ascii 64), season: uint }
  { amount: uint }
)

;; Set total catch data (admin only)
(define-public (set-total-catch (species (string-ascii 64)) (season uint) (amount uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1))
    (map-set total-catches { species: species, season: season } { amount: amount })
    (ok true)
  )
)

;; Initialize sustainability metrics for a species
(define-public (set-sustainability-metrics
  (species (string-ascii 64))
  (season uint)
  (population-estimate uint)
  (sustainable-catch-limit uint)
  (status (string-ascii 10))
)
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u2))
    (map-set sustainability-metrics
      { species: species, season: season }
      {
        population-estimate: population-estimate,
        sustainable-catch-limit: sustainable-catch-limit,
        status: status
      }
    )
    (ok true)
  )
)

;; Update sustainability status based on reported catches
(define-public (update-sustainability-status (species (string-ascii 64)) (season uint))
  (let (
    (metrics (default-to
              { population-estimate: u0, sustainable-catch-limit: u0, status: "unknown" }
              (map-get? sustainability-metrics { species: species, season: season })))
    (total-catch (default-to { amount: u0 }
                  (map-get? total-catches { species: species, season: season })))
    (new-status (if (>= (get amount total-catch) (get sustainable-catch-limit metrics))
                   "critical"
                   (if (>= (get amount total-catch) (/ (get sustainable-catch-limit metrics) u2))
                      "warning"
                      "healthy")))
  )
    (asserts! (is-eq tx-sender (var-get admin)) (err u3))

    (map-set sustainability-metrics
      { species: species, season: season }
      {
        population-estimate: (get population-estimate metrics),
        sustainable-catch-limit: (get sustainable-catch-limit metrics),
        status: new-status
      }
    )

    (ok true)
  )
)

;; Get sustainability metrics for a species
(define-read-only (get-sustainability-metrics (species (string-ascii 64)) (season uint))
  (default-to
    { population-estimate: u0, sustainable-catch-limit: u0, status: "unknown" }
    (map-get? sustainability-metrics { species: species, season: season }))
)

;; Get total catch for a species
(define-read-only (get-total-catch (species (string-ascii 64)) (season uint))
  (default-to { amount: u0 }
    (map-get? total-catches { species: species, season: season }))
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u4))
    (var-set admin new-admin)
    (ok true)
  )
)

