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