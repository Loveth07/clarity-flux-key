;; FluxKey Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))

;; Data structures
(define-map keys
  { key-id: uint }
  {
    owner: principal,
    encrypted-data: (string-utf8 1024),
    created-at: uint
  }
)

(define-map access-rights
  { key-id: uint, user: principal }
  {
    can-read: bool,
    can-update: bool,
    granted-by: principal,
    granted-at: uint
  }
)

;; Store a new key
(define-public (store-key (key-id uint) (encrypted-data (string-utf8 1024)))
  (let ((existing-key (get-key-owner key-id)))
    (asserts! (is-none existing-key) err-already-exists)
    (map-set keys
      { key-id: key-id }
      {
        owner: tx-sender,
        encrypted-data: encrypted-data,
        created-at: block-height
      }
    )
    (ok true))
)

;; Share key with another user
(define-public (share-key (key-id uint) (user principal) (can-read bool) (can-update bool))
  (let ((key-owner (get-key-owner key-id)))
    (asserts! (is-eq (some tx-sender) key-owner) err-unauthorized)
    (map-set access-rights
      { key-id: key-id, user: user }
      {
        can-read: can-read,
        can-update: can-update,
        granted-by: tx-sender,
        granted-at: block-height
      }
    )
    (ok true))
)

;; Get key data if authorized
(define-public (get-key (key-id uint))
  (let (
    (key-data (map-get? keys { key-id: key-id }))
    (access-data (map-get? access-rights { key-id: key-id, user: tx-sender }))
  )
    (asserts! (or
      (is-eq (some tx-sender) (get-key-owner key-id))
      (and (is-some access-data) (get can-read (unwrap-panic access-data)))
    ) err-unauthorized)
    (ok (unwrap! key-data err-not-found)))
)

;; Revoke access
(define-public (revoke-access (key-id uint) (user principal))
  (let ((key-owner (get-key-owner key-id)))
    (asserts! (is-eq (some tx-sender) key-owner) err-unauthorized)
    (map-delete access-rights { key-id: key-id, user: user })
    (ok true))
)

;; Helper functions
(define-private (get-key-owner (key-id uint))
  (get owner (map-get? keys { key-id: key-id }))
)
