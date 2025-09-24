;; Disease Reporter Contract
;; This contract manages crop disease reporting functionality
;; for the CropAlert blockchain-based agricultural monitoring system

;; Error constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-COORDINATES (err u101))
(define-constant ERR-INVALID-CROP-TYPE (err u102))
(define-constant ERR-INVALID-DISEASE-TYPE (err u103))
(define-constant ERR-INVALID-SEVERITY (err u104))
(define-constant ERR-INVALID-AREA (err u105))
(define-constant ERR-REPORTER-NOT-REGISTERED (err u106))
(define-constant ERR-REPORT-NOT-FOUND (err u107))
(define-constant ERR-ALREADY-REGISTERED (err u108))
(define-constant ERR-EMPTY-STRING (err u109))
(define-constant ERR-REPORT-ALREADY-VERIFIED (err u110))

;; System constants
(define-constant MAX-STRING-LENGTH u500)
(define-constant MIN-SEVERITY u1)
(define-constant MAX-SEVERITY u5)
(define-constant MAX-AREA u10000)  ;; Maximum 10,000 hectares
(define-constant MIN-LATITUDE -90000000)   ;; -90 degrees * 1000000 for precision
(define-constant MAX-LATITUDE 90000000)    ;; 90 degrees * 1000000
(define-constant MIN-LONGITUDE -180000000) ;; -180 degrees * 1000000
(define-constant MAX-LONGITUDE 180000000)  ;; 180 degrees * 1000000

;; Valid crop types
(define-constant VALID-CROP-TYPES
  (list "wheat" "corn" "rice" "soybeans" "barley" "cotton" "potato" "tomato" "onion" "carrot")
)

;; Valid disease types
(define-constant VALID-DISEASE-TYPES
  (list "blight" "rust" "smut" "mildew" "wilt" "mosaic" "rot" "canker" "scab" "anthracnose")
)

;; Data structures
(define-map reporters
  principal
  {
    farm-name: (string-ascii 100),
    expertise-area: (string-ascii 100),
    registered-at: uint,
    total-reports: uint,
    verified-reports: uint,
    reputation-score: uint
  }
)

(define-map disease-reports
  uint
  {
    reporter: principal,
    latitude: int,
    longitude: int,
    crop-type: (string-ascii 20),
    disease-type: (string-ascii 30),
    severity: uint,
    affected-area: uint,
    symptoms: (string-ascii 500),
    photo-hash: (string-ascii 100),
    timestamp: uint,
    status: (string-ascii 20),
    verifications: uint,
    positive-verifications: uint
  }
)

;; Global variables
(define-data-var report-counter uint u0)
(define-data-var contract-owner principal tx-sender)

;; Helper functions

;; Validate coordinates
(define-private (is-valid-coordinates (lat int) (lon int))
  (and
    (>= lat MIN-LATITUDE)
    (<= lat MAX-LATITUDE)
    (>= lon MIN-LONGITUDE)
    (<= lon MAX-LONGITUDE)
  )
)

;; Validate crop type
(define-private (is-valid-crop-type (crop-type (string-ascii 20)))
  (or
    (is-eq crop-type "wheat")
    (is-eq crop-type "corn")
    (is-eq crop-type "rice")
    (is-eq crop-type "soybeans")
    (is-eq crop-type "barley")
    (is-eq crop-type "cotton")
    (is-eq crop-type "potato")
    (is-eq crop-type "tomato")
    (is-eq crop-type "onion")
    (is-eq crop-type "carrot")
  )
)

;; Validate disease type
(define-private (is-valid-disease-type (disease-type (string-ascii 30)))
  (or
    (is-eq disease-type "blight")
    (is-eq disease-type "rust")
    (is-eq disease-type "smut")
    (is-eq disease-type "mildew")
    (is-eq disease-type "wilt")
    (is-eq disease-type "mosaic")
    (is-eq disease-type "rot")
    (is-eq disease-type "canker")
    (is-eq disease-type "scab")
    (is-eq disease-type "anthracnose")
  )
)

;; Validate severity level
(define-private (is-valid-severity (severity uint))
  (and (>= severity MIN-SEVERITY) (<= severity MAX-SEVERITY))
)

;; Validate affected area
(define-private (is-valid-area (area uint))
  (and (> area u0) (<= area MAX-AREA))
)

;; Check if string is not empty
(define-private (is-non-empty-string (str (string-ascii 500)))
  (> (len str) u0)
)

;; Calculate reputation score
(define-private (calculate-reputation (verified uint) (total uint))
  (if (is-eq total u0)
    u50  ;; Starting reputation
    (/ (* verified u100) total)
  )
)

;; Public functions

;; Register as a disease reporter
(define-public (register-reporter (farm-name (string-ascii 100)) (expertise-area (string-ascii 100)))
  (let ((reporter tx-sender))
    (asserts! (> (len farm-name) u0) ERR-EMPTY-STRING)
    (asserts! (> (len expertise-area) u0) ERR-EMPTY-STRING)
    (asserts! (is-none (map-get? reporters reporter)) ERR-ALREADY-REGISTERED)
    
    (map-set reporters reporter {
      farm-name: farm-name,
      expertise-area: expertise-area,
      registered-at: stacks-block-height,
      total-reports: u0,
      verified-reports: u0,
      reputation-score: u50
    })
    
    (ok true)
  )
)

;; Submit a disease report
(define-public (submit-disease-report
  (latitude int)
  (longitude int)
  (crop-type (string-ascii 20))
  (disease-type (string-ascii 30))
  (severity uint)
  (affected-area uint)
  (symptoms (string-ascii 500))
  (photo-hash (string-ascii 100))
)
  (let (
    (reporter tx-sender)
    (reporter-info (unwrap! (map-get? reporters reporter) ERR-REPORTER-NOT-REGISTERED))
    (new-report-id (+ (var-get report-counter) u1))
  )
    ;; Validate inputs
    (asserts! (is-valid-coordinates latitude longitude) ERR-INVALID-COORDINATES)
    (asserts! (is-valid-crop-type crop-type) ERR-INVALID-CROP-TYPE)
    (asserts! (is-valid-disease-type disease-type) ERR-INVALID-DISEASE-TYPE)
    (asserts! (is-valid-severity severity) ERR-INVALID-SEVERITY)
    (asserts! (is-valid-area affected-area) ERR-INVALID-AREA)
    (asserts! (is-non-empty-string symptoms) ERR-EMPTY-STRING)
    
    ;; Create disease report
    (map-set disease-reports new-report-id {
      reporter: reporter,
      latitude: latitude,
      longitude: longitude,
      crop-type: crop-type,
      disease-type: disease-type,
      severity: severity,
      affected-area: affected-area,
      symptoms: symptoms,
      photo-hash: photo-hash,
      timestamp: stacks-block-height,
      status: "pending",
      verifications: u0,
      positive-verifications: u0
    })
    
    ;; Update reporter statistics
    (map-set reporters reporter (merge reporter-info {
      total-reports: (+ (get total-reports reporter-info) u1)
    }))
    
    ;; Update counter
    (var-set report-counter new-report-id)
    
    (ok new-report-id)
  )
)

;; Update report verification status (called by verifier contract)
(define-public (update-report-verification (report-id uint) (is-verified bool))
  (let (
    (report (unwrap! (map-get? disease-reports report-id) ERR-REPORT-NOT-FOUND))
    (reporter (get reporter report))
    (reporter-info (unwrap! (map-get? reporters reporter) ERR-REPORTER-NOT-REGISTERED))
  )
    ;; Only allow updates from contract owner for this demo
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    
    ;; Update report status
    (let (
      (new-verifications (+ (get verifications report) u1))
      (new-positive (if is-verified (+ (get positive-verifications report) u1) (get positive-verifications report)))
    )
      (map-set disease-reports report-id (merge report {
        verifications: new-verifications,
        positive-verifications: new-positive,
        status: (if (and is-verified (>= new-positive u2)) "verified" "pending")
      }))
      
      ;; Update reporter reputation if verified
      (if is-verified
        (let ((new-verified (+ (get verified-reports reporter-info) u1)))
          (map-set reporters reporter (merge reporter-info {
            verified-reports: new-verified,
            reputation-score: (calculate-reputation new-verified (get total-reports reporter-info))
          }))
        )
        ;; Do nothing for now if not verified
        true
      )
    )
    
    (ok true)
  )
)

;; Read-only functions

;; Get reporter information
(define-read-only (get-reporter-info (reporter principal))
  (map-get? reporters reporter)
)

;; Get disease report by ID
(define-read-only (get-disease-report (report-id uint))
  (map-get? disease-reports report-id)
)

;; Get current report counter
(define-read-only (get-report-counter)
  (var-get report-counter)
)

;; Check if reporter is registered
(define-read-only (is-reporter-registered (reporter principal))
  (is-some (map-get? reporters reporter))
)

;; Get reporter's total reports
(define-read-only (get-reporter-total-reports (reporter principal))
  (match (map-get? reporters reporter)
    reporter-info (some (get total-reports reporter-info))
    none
  )
)

;; Get reporter's verified reports
(define-read-only (get-reporter-verified-reports (reporter principal))
  (match (map-get? reporters reporter)
    reporter-info (some (get verified-reports reporter-info))
    none
  )
)

;; Get reporter's reputation score
(define-read-only (get-reporter-reputation (reporter principal))
  (match (map-get? reporters reporter)
    reporter-info (some (get reputation-score reporter-info))
    none
  )
)

;; Get reports by status
(define-read-only (get-report-status (report-id uint))
  (match (map-get? disease-reports report-id)
    report (some (get status report))
    none
  )
)

;; Validate input parameters
(define-read-only (validate-report-params
  (latitude int)
  (longitude int)
  (crop-type (string-ascii 20))
  (disease-type (string-ascii 30))
  (severity uint)
  (affected-area uint)
)
  {
    valid-coordinates: (is-valid-coordinates latitude longitude),
    valid-crop-type: (is-valid-crop-type crop-type),
    valid-disease-type: (is-valid-disease-type disease-type),
    valid-severity: (is-valid-severity severity),
    valid-area: (is-valid-area affected-area)
  }
)

;; Get valid crop types
(define-read-only (get-valid-crop-types)
  VALID-CROP-TYPES
)

;; Get valid disease types
(define-read-only (get-valid-disease-types)
  VALID-DISEASE-TYPES
)

;; Admin functions

;; Set contract owner (for emergency purposes)
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
  "disease-reporter"
)
