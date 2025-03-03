;; FluxKey Contract - Enhanced Version

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-invalid-input (err u103))
(define-constant err-access-expired (err u104))
(define-constant err-max-attempts (err u105))

;; Data structures
(define-map keys
  { key-id: uint }
  {
    owner: principal,
    encrypted-data: (string-utf8 1024),
    name: (optional (string-utf8 50)),
    description: (optional (string-utf8 200)),
    created-at: uint,
    updated-at: uint,
    version: uint,
    failed-attempts: uint
  }
)

(define-map access-rights
  { key-id: uint, user: principal }
  {
    can-read: bool,
    can-update: bool,
    granted-by: principal,
    granted-at: uint,
    expires-at: (optional uint),
    access-count: uint
  }
)

;; Events
(define-data-var event-counter uint u0)

(define-private (emit-event (event-type (string-utf8 20)) (key-id uint) (details (optional (string-utf8 50))))
  (begin
    (var-set event-counter (+ (var-get event-counter) u1))
    (print {
      event-id: (var-get event-counter),
      type: event-type,
      key-id: key-id,
      details: details,
      triggered-by: tx-sender,
      block: block-height
    })
  )
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
        updated-at: block-height,
        version: u1,
        failed-attempts: u0
      }
    )
    (emit-event "store" key-id name)
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
      (and 
        (is-some access-data)
        (get can-update (unwrap-panic access-data))
        (check-access-validity key-id tx-sender)
      )
    ) err-unauthorized)
    
    (map-set keys
      { key-id: key-id }
      (merge (unwrap-panic key-data)
        {
          encrypted-data: encrypted-data,
          updated-at: block-height,
          version: (+ (get version (unwrap-panic key-data)) u1)
        }
      )
    )
    (emit-event "update" key-id none)
    (ok true))
)

;; Check access validity
(define-private (check-access-validity (key-id uint) (user principal))
  (let ((access-data (unwrap! (map-get? access-rights { key-id: key-id, user: user }) false)))
    (and
      (match (get expires-at access-data)
        expiry (< block-height expiry)
        true
      )
      (< (get failed-attempts (default-to 
        { failed-attempts: u0 } 
        (map-get? keys { key-id: key-id }))) u3)
    )
  )
)

;; Share key with time limit
(define-public (share-key-timed (key-id uint) (recipient principal) (can-read bool) (can-update bool) (expires-in uint))
  (let ((key-data (map-get? keys { key-id: key-id })))
    (asserts! (is-some key-data) err-not-found)
    (asserts! (is-eq (some tx-sender) (get-key-owner key-id)) err-unauthorized)
    
    (map-set access-rights
      { key-id: key-id, user: recipient }
      {
        can-read: can-read,
        can-update: can-update,
        granted-by: tx-sender,
        granted-at: block-height,
        expires-at: (some (+ block-height expires-in)),
        access-count: u0
      }
    )
    (emit-event "share" key-id (some "time-limited"))
    (ok true))
)

;; Batch update keys
(define-public (batch-update-keys (key-ids (list 10 uint)) (encrypted-data (list 10 (string-utf8 1024))))
  (fold check-and-update key-ids encrypted-data (ok true))
)

(define-private (check-and-update (key-id uint) (data (string-utf8 1024)) (previous-result (response bool uint)))
  (match previous-result
    prev-ok (update-key key-id data)
    prev-err previous-result
  )
)
