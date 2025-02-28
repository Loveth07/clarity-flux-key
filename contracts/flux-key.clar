;; FluxKey Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-invalid-input (err u103))

;; Data structures
(define-map keys
  { key-id: uint }
  {
    owner: principal,
    encrypted-data: (string-utf8 1024),
    name: (optional (string-utf8 50)),
    description: (optional (string-utf8 200)),
    created-at: uint,
    updated-at: uint
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

;; Events
(define-data-var event-counter uint u0)

(define-private (emit-event (event-type (string-utf8 20)) (key-id uint))
  (begin
    (var-set event-counter (+ (var-get event-counter) u1))
    (print { event-id: (var-get event-counter), type: event-type, key-id: key-id, triggered-by: tx-sender }))
)

;; Store a new key
(define-public (store-key (key-id uint) (encrypted-data (string-utf8 1024)) 
                         (name (optional (string-utf8 50))) (description (optional (string-utf8 200))))
  (let ((existing-key (get-key-owner key-id)))
    (asserts! (is-none existing-key) err-already-exists)
    (map-set keys
      { key-id: key-id }
      {
        owner: tx-sender,
        encrypted-data: encrypted-data,
        name: name,
        description: description,
        created-at: block-height,
        updated-at: block-height
      }
    )
    (emit-event "store" key-id)
    (ok true))
)

;; Update existing key
(define-public (update-key (key-id uint) (encrypted-data (string-utf8 1024)))
  (let (
    (key-data (map-get? keys { key-id: key-id }))
    (access-data (map-get? access-rights { key-id: key-id, user: tx-sender }))
  )
    (asserts! (is-some key-data) err-not-found)
    (asserts! (or
      (is-eq (some tx-sender) (get-key-owner key-id))
      (and (is-some access-data) (get can-update (unwrap-panic access-data)))
    ) err-unauthorized)
    
    (map-set keys
      { key-id: key-id }
      (merge (unwrap-panic key-data)
        {
          encrypted-data: encrypted-data,
          updated-at: block-height
        }
      )
    )
    (emit-event "update" key-id)
    (ok true))
)

;; [Previous functions remain unchanged: share-key, get-key, revoke-access, get-key-owner]
