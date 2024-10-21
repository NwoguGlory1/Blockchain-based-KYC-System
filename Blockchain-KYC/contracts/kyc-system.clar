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