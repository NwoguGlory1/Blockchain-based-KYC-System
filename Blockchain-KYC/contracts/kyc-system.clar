;; KYC System Smart Contract

;; Define data variables
(define-data-var contract-owner principal tx-sender)

(define-map customers 
  { customer-id: uint }
  {
    address: principal,
    name: (string-utf8 100),
    date-of-birth: uint,
    residence-country: (string-utf8 50),
    is-verified: bool,
    verification-date: uint
  }
)

(define-map businesses
  { business-id: uint }
  {
    address: principal,
    name: (string-utf8 100),
    is-approved: bool
  }
)

(define-map verification-history
  { customer-id: uint, verification-number: uint }
  {
    business-id: uint,
    verification-date: uint,
    verification-type: (string-utf8 50),
    expiration-date: uint
  }
)

(define-map customer-verification-nonce 
  { customer-id: uint }
  { nonce: uint }
)

(define-constant err-expired-verification (err u104))
(define-constant err-invalid-data (err u105))
(define-constant err-verification-required (err u106))
(define-data-var customer-id-nonce uint u0)
(define-data-var business-id-nonce uint u0)

;; Define error constants
(define-constant err-unauthorized (err u100))
(define-constant err-already-exists (err u101))
(define-constant err-not-found (err u102))
(define-constant err-already-verified (err u103))


;; Helper functions
(define-private (is-contract-owner)
  (is-eq tx-sender (var-get contract-owner))
)

(define-private (is-approved-business (business-id uint))
  (match (map-get? businesses { business-id: business-id })
    business (get is-approved business)
    false
  )
)

(define-private (get-verification-nonce (customer-id uint))
  (default-to { nonce: u0 }
    (map-get? customer-verification-nonce { customer-id: customer-id })
  )
)

;; Public functions
(define-public (add-customer (name (string-utf8 100)) (date-of-birth uint) (residence-country (string-utf8 50)))
  (let
    (
      (new-id (+ (var-get customer-id-nonce) u1))
    )
    (asserts! (is-none (map-get? customers { customer-id: new-id })) err-already-exists)
    (map-set customers
      { customer-id: new-id }
      {
        address: tx-sender,
        name: name,
        date-of-birth: date-of-birth,
        residence-country: residence-country,
        is-verified: false,
        verification-date: u0
      }
    )
    (var-set customer-id-nonce new-id)
    (ok new-id)
  )
)

(define-public (verify-customer (customer-id uint) (business-id uint))
  (let
    (
      (customer (unwrap! (map-get? customers { customer-id: customer-id }) err-not-found))
    )
    (asserts! (is-approved-business business-id) err-unauthorized)
    (asserts! (not (get is-verified customer)) err-already-verified)
    (map-set customers
      { customer-id: customer-id }
      (merge customer { 
        is-verified: true,
        verification-date: block-height
      })
    )
    (ok true)
  )
)

(define-public (approve-business (address principal) (name (string-utf8 100)))
  (let
    (
      (new-id (+ (var-get business-id-nonce) u1))
    )
    (asserts! (is-contract-owner) err-unauthorized)
    (asserts! (is-none (map-get? businesses { business-id: new-id })) err-already-exists)
    (map-set businesses
      { business-id: new-id }
      {
        address: address,
        name: name,
        is-approved: true
      }
    )
    (var-set business-id-nonce new-id)
    (ok new-id)
  )
)

(define-public (revoke-business (business-id uint))
  (let
    (
      (business (unwrap! (map-get? businesses { business-id: business-id }) err-not-found))
    )
    (asserts! (is-contract-owner) err-unauthorized)
    (map-set businesses
      { business-id: business-id }
      (merge business { is-approved: false })
    )
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-customer-details (customer-id uint))
  (map-get? customers { customer-id: customer-id })
)

(define-read-only (is-customer-verified (customer-id uint))
  (match (map-get? customers { customer-id: customer-id })
    customer (get is-verified customer)
    false
  )
)

(define-read-only (is-business-approved (business-id uint))
  (is-approved-business business-id)
)

(define-public (update-customer-data 
    (customer-id uint)
    (new-name (optional (string-utf8 100)))
    (new-residence-country (optional (string-utf8 50)))
  )
  (let
    (
      (customer (unwrap! (map-get? customers { customer-id: customer-id }) err-not-found))
    )
    (asserts! (is-eq tx-sender (get address customer)) err-unauthorized)
    (map-set customers
      { customer-id: customer-id }
      (merge customer
        {
          name: (default-to (get name customer) new-name),
          residence-country: (default-to (get residence-country customer) new-residence-country)
        }
      )
    )
    (ok true)
  )
)



