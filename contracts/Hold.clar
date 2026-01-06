(define-constant ERR_NO_LOCK u100)
(define-constant ERR_ZERO_AMOUNT u101)
(define-constant ERR_ZERO_PERIOD u102)
(define-constant ERR_LOCK_EXISTS u103)
(define-constant ERR_LOCK_ACTIVE u104)
(define-constant ERR_TRANSFER_FAILED u105)

(define-map locks
  {user: principal}
  {amount: uint, unlock-height: uint}
)

(define-private (calculate-voting-power (user principal) (height uint))
  (match (map-get? locks {user: user})
    lock
      (let (
            (locked-amount (get amount lock))
            (unlock-height (get unlock-height lock))
           )
        (if (is-eq locked-amount u0)
            (err ERR_NO_LOCK)
            (let (
                  (lock-period (if (> unlock-height height)
                                   (- unlock-height height)
                                   u0))
                  (voting-power (* locked-amount lock-period))
                 )
              ;; Return structured data for downstream use.
              (ok {
                   locked: locked-amount,
                   unlock-height: unlock-height,
                   lock-period: lock-period,
                   voting-power: voting-power
                  })
            )
        )
      )
    (err ERR_NO_LOCK)
  )
)

(define-public (lock-stx (amount uint) (lock-period uint))
  (if (is-eq amount u0)
      (err ERR_ZERO_AMOUNT)
      (if (is-eq lock-period u0)
          (err ERR_ZERO_PERIOD)
          (if (is-some (map-get? locks {user: tx-sender}))
              (err ERR_LOCK_EXISTS)
              (let ((unlock-height (+ stacks-block-height lock-period)))
                (begin
                  (unwrap! (stx-transfer? amount tx-sender (as-contract tx-sender)) (err ERR_TRANSFER_FAILED))
                  (map-set locks {user: tx-sender} {amount: amount, unlock-height: unlock-height})
                  (ok {amount: amount, unlock-height: unlock-height})
                )
              )
          )
      )
  )
)

(define-public (unlock-stx)
  (let ((user tx-sender))
    (match (map-get? locks {user: user})
      lock
        (if (< stacks-block-height (get unlock-height lock))
            (err ERR_LOCK_ACTIVE)
            (begin
              (unwrap! (as-contract (stx-transfer? (get amount lock) tx-sender user)) (err ERR_TRANSFER_FAILED))
              (map-delete locks {user: user})
              (ok (get amount lock))
            )
        )
      (err ERR_NO_LOCK)
    )
  )
)

(define-read-only (get-voting-power (user principal))
  (calculate-voting-power user stacks-block-height)
)

;; Allows callers to compute voting power at an arbitrary block height.
(define-read-only (get-voting-power-at (user principal) (height uint))
  (calculate-voting-power user height)
)
