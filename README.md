## Hold Contract

This contract implements a simple STX locking mechanism and exposes voting power derived from the lock amount and remaining lock duration.

### Storage
- `locks` map keyed by `{user: principal}` with values `{amount: uint, unlock-height: uint}`.

### Errors
- `ERR_NO_LOCK (u100)`: No lock exists for the user.
- `ERR_ZERO_AMOUNT (u101)`: Lock amount is zero.
- `ERR_ZERO_PERIOD (u102)`: Lock period is zero.
- `ERR_LOCK_EXISTS (u103)`: User already has a lock.
- `ERR_LOCK_ACTIVE (u104)`: Unlock attempted before `unlock-height`.
- `ERR_TRANSFER_FAILED (u105)`: STX transfer failed.

### Public Functions
- `lock-stx (amount uint) (lock-period uint)`
  - Transfers `amount` from the caller into the contract and records a lock with `unlock-height = stacks-block-height + lock-period`.
  - Returns `{amount, unlock-height}` on success.
- `unlock-stx`
  - Releases the caller's locked STX once `stacks-block-height >= unlock-height`.
  - Returns the unlocked amount.

### Read-Only Functions
- `get-voting-power (user principal)`
  - Calculates voting power for `user` at the current `stacks-block-height`.
- `get-voting-power-at (user principal) (height uint)`
  - Calculates voting power for `user` at an arbitrary block height.

### Voting Power Calculation
If a lock exists and `locked-amount > 0`, voting power is:

```
lock-period = max(unlock-height - height, 0)
voting-power = locked-amount * lock-period
```

The function returns a tuple:
`{ locked, unlock-height, lock-period, voting-power }`.
