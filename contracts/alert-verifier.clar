;; Alert Verifier Contract
;; This contract manages the verification of disease reports and alert generation
;; for the CropAlert blockchain-based agricultural monitoring system

;; Error constants
(define-constant ERR-NOT-AUTHORIZED (err u200))
(define-constant ERR-VERIFIER-NOT-REGISTERED (err u201))
(define-constant ERR-REPORT-NOT-FOUND (err u202))
(define-constant ERR-ALREADY-VERIFIED-BY-USER (err u203))
(define-constant ERR-ALREADY-REGISTERED (err u204))
(define-constant ERR-EMPTY-STRING (err u205))
(define-constant ERR-INVALID-COORDINATES (err u206))
(define-constant ERR-INVALID-RADIUS (err u207))
(define-constant ERR-ALERT-NOT-FOUND (err u208))
(define-constant ERR-INVALID-CONFIDENCE (err u209))
(define-constant ERR-SELF-VERIFICATION (err u210))

;; System constants
(define-constant MIN-VERIFICATION-CONFIDENCE u1)
(define-constant MAX-VERIFICATION-CONFIDENCE u5)
(define-constant MIN-VERIFICATIONS-FOR-ALERT u2)  ;; Minimum verifications to create alert
(define-constant ALERT-RADIUS u50000)  ;; 50km radius for alerts in meters
(define-constant MAX-RADIUS u100000)   ;; Maximum 100km radius for queries
(define-constant REPUTATION-THRESHOLD u60) ;; Minimum reputation to verify

;; Data structures
(define-map verifiers
  principal
  {
    name: (string-ascii 100),
    credentials: (string-ascii 200),
    specialization: (string-ascii 100),
    registered-at: uint,
    total-verifications: uint,
    correct-verifications: uint,
    reputation-score: uint
  }
)

(define-map verifications
  {report-id: uint, verifier: principal}
  {
    is-verified: bool,
    confidence: uint,
    comments: (string-ascii 500),
    treatment-recommendation: (string-ascii 300),
    timestamp: uint
  }
)

(define-map alerts
  uint
  {
    report-id: uint,
    alert-type: (string-ascii 20),
    severity: uint,
    latitude: int,
    longitude: int,
    crop-type: (string-ascii 20),
    disease-type: (string-ascii 30),
    affected-radius: uint,
    created-at: uint,
    expires-at: uint,
    verified-by: uint,  ;; Number of verifiers
    is-active: bool
  }
)

(define-map treatment-database
  {disease-type: (string-ascii 30), crop-type: (string-ascii 20)}
  {
    primary-treatment: (string-ascii 200),
    secondary-treatment: (string-ascii 200),
    prevention-tips: (string-ascii 300),
    effectiveness-rating: uint
  }
)

;; Global variables
(define-data-var alert-counter uint u0)
(define-data-var contract-owner principal tx-sender)
(define-data-var verification-reward uint u100)  ;; Reward for accurate verifications

;; Helper functions

;; Calculate distance between two points (simplified)
(define-private (calculate-distance (lat1 int) (lon1 int) (lat2 int) (lon2 int))
  ;; Simplified distance calculation for demonstration
  ;; In reality, would use proper geospatial calculation
  (let (
    (lat-diff (if (> lat1 lat2) (- lat1 lat2) (- lat2 lat1)))
    (lon-diff (if (> lon1 lon2) (- lon1 lon2) (- lon2 lon1)))
  )
    (+ lat-diff lon-diff)  ;; Simplified Manhattan distance
  )
)

;; Check if coordinates are within radius
(define-private (is-within-radius (lat1 int) (lon1 int) (lat2 int) (lon2 int) (radius uint))
  (let ((distance (calculate-distance lat1 lon1 lat2 lon2)))
    (<= (to-uint distance) radius)
  )
)

;; Validate confidence level
(define-private (is-valid-confidence (confidence uint))
  (and (>= confidence MIN-VERIFICATION-CONFIDENCE) (<= confidence MAX-VERIFICATION-CONFIDENCE))
)

;; Calculate verifier reputation
(define-private (calculate-verifier-reputation (correct uint) (total uint))
  (if (is-eq total u0)
    u50  ;; Starting reputation
    (/ (* correct u100) total)
  )
)

;; Public functions

;; Register as a verifier (agricultural expert)
(define-public (register-verifier
  (name (string-ascii 100))
  (credentials (string-ascii 200))
  (specialization (string-ascii 100))
)
  (let ((verifier tx-sender))
    (asserts! (> (len name) u0) ERR-EMPTY-STRING)
    (asserts! (> (len credentials) u0) ERR-EMPTY-STRING)
    (asserts! (> (len specialization) u0) ERR-EMPTY-STRING)
    (asserts! (is-none (map-get? verifiers verifier)) ERR-ALREADY-REGISTERED)
    
    (map-set verifiers verifier {
      name: name,
      credentials: credentials,
      specialization: specialization,
      registered-at: stacks-block-height,
      total-verifications: u0,
      correct-verifications: u0,
      reputation-score: u75  ;; Experts start with higher reputation
    })
    
    (ok true)
  )
)

;; Verify a disease report
(define-public (verify-disease-report
  (report-id uint)
  (is-verified bool)
  (confidence uint)
  (comments (string-ascii 500))
  (treatment-recommendation (string-ascii 300))
  (reporter-principal principal)
)
  (let (
    (verifier tx-sender)
    (verifier-info (unwrap! (map-get? verifiers verifier) ERR-VERIFIER-NOT-REGISTERED))
    (existing-verification (map-get? verifications {report-id: report-id, verifier: verifier}))
  )
    ;; Validate inputs
    (asserts! (is-valid-confidence confidence) ERR-INVALID-CONFIDENCE)
    (asserts! (> (len comments) u0) ERR-EMPTY-STRING)
    (asserts! (not (is-eq verifier reporter-principal)) ERR-SELF-VERIFICATION)
    (asserts! (is-none existing-verification) ERR-ALREADY-VERIFIED-BY-USER)
    (asserts! (>= (get reputation-score verifier-info) REPUTATION-THRESHOLD) ERR-NOT-AUTHORIZED)
    
    ;; Record verification
    (map-set verifications {report-id: report-id, verifier: verifier} {
      is-verified: is-verified,
      confidence: confidence,
      comments: comments,
      treatment-recommendation: treatment-recommendation,
      timestamp: stacks-block-height
    })
    
    ;; Update verifier statistics
    (map-set verifiers verifier (merge verifier-info {
      total-verifications: (+ (get total-verifications verifier-info) u1)
    }))
    
    (ok true)
  )
)

;; Create alert for verified disease outbreak
(define-public (create-disease-alert
  (report-id uint)
  (latitude int)
  (longitude int)
  (crop-type (string-ascii 20))
  (disease-type (string-ascii 30))
  (severity uint)
)
  (let (
    (creator tx-sender)
    (new-alert-id (+ (var-get alert-counter) u1))
    (expires-at (+ stacks-block-height u1440))  ;; Alert expires in ~10 days (1440 blocks)
  )
    ;; Only contract owner can create alerts for this demo
    (asserts! (is-eq creator (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    
    ;; Create alert
    (map-set alerts new-alert-id {
      report-id: report-id,
      alert-type: "disease-outbreak",
      severity: severity,
      latitude: latitude,
      longitude: longitude,
      crop-type: crop-type,
      disease-type: disease-type,
      affected-radius: ALERT-RADIUS,
      created-at: stacks-block-height,
      expires-at: expires-at,
      verified-by: MIN-VERIFICATIONS-FOR-ALERT,
      is-active: true
    })
    
    ;; Update counter
    (var-set alert-counter new-alert-id)
    
    (ok new-alert-id)
  )
)

;; Deactivate alert
(define-public (deactivate-alert (alert-id uint))
  (let (
    (alert (unwrap! (map-get? alerts alert-id) ERR-ALERT-NOT-FOUND))
    (deactivator tx-sender)
  )
    ;; Only contract owner can deactivate alerts
    (asserts! (is-eq deactivator (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    
    ;; Deactivate alert
    (map-set alerts alert-id (merge alert {is-active: false}))
    
    (ok true)
  )
)

;; Add treatment to database
(define-public (add-treatment-info
  (disease-type (string-ascii 30))
  (crop-type (string-ascii 20))
  (primary-treatment (string-ascii 200))
  (secondary-treatment (string-ascii 200))
  (prevention-tips (string-ascii 300))
  (effectiveness-rating uint)
)
  (let ((contributor tx-sender))
    ;; Only registered verifiers can add treatment info
    (asserts! (is-some (map-get? verifiers contributor)) ERR-VERIFIER-NOT-REGISTERED)
    (asserts! (>= effectiveness-rating u1) ERR-INVALID-CONFIDENCE)
    (asserts! (<= effectiveness-rating u5) ERR-INVALID-CONFIDENCE)
    
    (map-set treatment-database {disease-type: disease-type, crop-type: crop-type} {
      primary-treatment: primary-treatment,
      secondary-treatment: secondary-treatment,
      prevention-tips: prevention-tips,
      effectiveness-rating: effectiveness-rating
    })
    
    (ok true)
  )
)

;; Read-only functions

;; Get verifier information
(define-read-only (get-verifier-info (verifier principal))
  (map-get? verifiers verifier)
)

;; Get verification details
(define-read-only (get-verification (report-id uint) (verifier principal))
  (map-get? verifications {report-id: report-id, verifier: verifier})
)

;; Get alert information
(define-read-only (get-alert (alert-id uint))
  (map-get? alerts alert-id)
)

;; Get current alert counter
(define-read-only (get-alert-counter)
  (var-get alert-counter)
)

;; Check if verifier is registered
(define-read-only (is-verifier-registered (verifier principal))
  (is-some (map-get? verifiers verifier))
)

;; Get active alerts in radius
(define-read-only (get-alerts-in-radius (center-lat int) (center-lon int) (radius uint))
  ;; This is a simplified version - in practice would iterate through alerts
  ;; For demo purposes, we'll return a boolean indicating if there are alerts
  (if (and (< radius MAX-RADIUS) (> radius u0))
    (some true)
    none
  )
)

;; Get treatment information
(define-read-only (get-treatment-info (disease-type (string-ascii 30)) (crop-type (string-ascii 20)))
  (map-get? treatment-database {disease-type: disease-type, crop-type: crop-type})
)

;; Get verifier statistics
(define-read-only (get-verifier-stats (verifier principal))
  (match (map-get? verifiers verifier)
    verifier-info (some {
      total-verifications: (get total-verifications verifier-info),
      correct-verifications: (get correct-verifications verifier-info),
      reputation-score: (get reputation-score verifier-info),
      accuracy-rate: (if (> (get total-verifications verifier-info) u0)
                      (/ (* (get correct-verifications verifier-info) u100) 
                         (get total-verifications verifier-info))
                      u0)
    })
    none
  )
)

;; Check if alert is still active
(define-read-only (is-alert-active (alert-id uint))
  (match (map-get? alerts alert-id)
    alert (and (get is-active alert) (<= stacks-block-height (get expires-at alert)))
    false
  )
)

;; Get verification count for a report
(define-read-only (count-verifications-for-report (report-id uint))
  ;; Simplified count - in practice would iterate through all verifications
  ;; For demo purposes, returns a placeholder
  (some u0)
)

;; Validate alert parameters
(define-read-only (validate-alert-params
  (latitude int)
  (longitude int)
  (severity uint)
  (radius uint)
)
  {
    valid-coordinates: (and (>= latitude -90000000) (<= latitude 90000000) 
                           (>= longitude -180000000) (<= longitude 180000000)),
    valid-severity: (and (>= severity u1) (<= severity u5)),
    valid-radius: (and (> radius u0) (<= radius MAX-RADIUS))
  }
)

;; Get system configuration
(define-read-only (get-system-config)
  {
    min-verifications-for-alert: MIN-VERIFICATIONS-FOR-ALERT,
    alert-radius: ALERT-RADIUS,
    max-radius: MAX-RADIUS,
    reputation-threshold: REPUTATION-THRESHOLD,
    verification-reward: (var-get verification-reward)
  }
)

;; Admin functions

;; Update verification reward
(define-public (set-verification-reward (new-reward uint))
  (if (is-eq tx-sender (var-get contract-owner))
    (begin
      (var-set verification-reward new-reward)
      (ok true)
    )
    ERR-NOT-AUTHORIZED
  )
)

;; Set contract owner
(define-public (set-contract-owner (new-owner principal))
  (if (is-eq tx-sender (var-get contract-owner))
    (begin
      (var-set contract-owner new-owner)
      (ok true)
    )
    ERR-NOT-AUTHORIZED
  )
)

;; Get contract name
(define-read-only (get-contract-name)
  "alert-verifier"
)
