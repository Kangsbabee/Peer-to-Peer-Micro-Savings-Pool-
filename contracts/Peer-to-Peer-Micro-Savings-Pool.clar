(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-insufficient-funds (err u103))
(define-constant err-pool-full (err u104))
(define-constant err-not-member (err u105))
(define-constant err-already-member (err u106))
(define-constant err-pool-active (err u107))
(define-constant err-pool-inactive (err u108))
(define-constant err-invalid-amount (err u109))
(define-constant err-payout-not-ready (err u110))
(define-constant err-already-contributed (err u111))
(define-constant err-not-your-turn (err u112))
(define-constant err-transfer-to-self (err u113))
(define-constant err-recipient-already-member (err u114))

(define-data-var pool-counter uint u0)

(define-map pools
  { pool-id: uint }
  {
    creator: principal,
    contribution-amount: uint,
    max-members: uint,
    current-members: uint,
    payout-schedule: uint,
    current-cycle: uint,
    total-cycles: uint,
    pool-balance: uint,
    is-active: bool,
    created-at: uint
  }
)

(define-map pool-members
  { pool-id: uint, member: principal }
  {
    position: uint,
    total-contributed: uint,
    cycles-contributed: uint,
    has-received-payout: bool,
    penalty-count: uint,
    joined-at: uint
  }
)

(define-map member-contributions
  { pool-id: uint, member: principal, cycle: uint }
  {
    amount: uint,
    contributed-at: uint
  }
)

(define-map payout-queue
  { pool-id: uint, cycle: uint }
  {
    recipient: principal,
    amount: uint,
    is-paid: bool
  }
)

(define-read-only (get-pool (pool-id uint))
  (map-get? pools { pool-id: pool-id })
)

(define-read-only (get-member-info (pool-id uint) (member principal))
  (map-get? pool-members { pool-id: pool-id, member: member })
)

(define-read-only (get-contribution (pool-id uint) (member principal) (cycle uint))
  (map-get? member-contributions { pool-id: pool-id, member: member, cycle: cycle })
)

(define-read-only (get-payout-info (pool-id uint) (cycle uint))
  (map-get? payout-queue { pool-id: pool-id, cycle: cycle })
)

(define-public (create-pool (contribution-amount uint) (max-members uint) (payout-schedule uint))
  (let
    (
      (new-pool-id (+ (var-get pool-counter) u1))
    )
    (asserts! (> contribution-amount u0) err-invalid-amount)
    (asserts! (and (>= max-members u2) (<= max-members u20)) err-invalid-amount)
    (asserts! (> payout-schedule u0) err-invalid-amount)
    
    (map-set pools
      { pool-id: new-pool-id }
      {
        creator: tx-sender,
        contribution-amount: contribution-amount,
        max-members: max-members,
        current-members: u0,
        payout-schedule: payout-schedule,
        current-cycle: u1,
        total-cycles: max-members,
        pool-balance: u0,
        is-active: false,
        created-at: stacks-block-height
      }
    )
    
    (var-set pool-counter new-pool-id)
    (ok new-pool-id)
  )
)

(define-public (join-pool (pool-id uint))
  (let
    (
      (pool-data (unwrap! (get-pool pool-id) err-not-found))
      (member-exists (is-some (get-member-info pool-id tx-sender)))
    )
    (asserts! (not member-exists) err-already-member)
    (asserts! (< (get current-members pool-data) (get max-members pool-data)) err-pool-full)
    
    (let
      (
        (new-position (+ (get current-members pool-data) u1))
      )
      (map-set pool-members
        { pool-id: pool-id, member: tx-sender }
        {
          position: new-position,
          total-contributed: u0,
          cycles-contributed: u0,
          has-received-payout: false,
          penalty-count: u0,
          joined-at: stacks-block-height
        }
      )
      
      (map-set pools
        { pool-id: pool-id }
        (merge pool-data { current-members: new-position })
      )
      
      (if (is-eq new-position (get max-members pool-data))
        (begin
          (map-set pools
            { pool-id: pool-id }
            (merge pool-data { 
              current-members: new-position,
              is-active: true 
            })
          )
          (ok true)
        )
        (ok true)
      )
    )
  )
)

(define-public (contribute (pool-id uint))
  (let
    (
      (pool-data (unwrap! (get-pool pool-id) err-not-found))
      (member-data (unwrap! (get-member-info pool-id tx-sender) err-not-member))
      (current-cycle (get current-cycle pool-data))
      (existing-contribution (get-contribution pool-id tx-sender current-cycle))
    )
    (asserts! (get is-active pool-data) err-pool-inactive)
    (asserts! (is-none existing-contribution) err-already-contributed)
    
    (try! (stx-transfer? (get contribution-amount pool-data) tx-sender (as-contract tx-sender)))
    
    (map-set member-contributions
      { pool-id: pool-id, member: tx-sender, cycle: current-cycle }
      {
        amount: (get contribution-amount pool-data),
        contributed-at: stacks-block-height
      }
    )
    
    (map-set pool-members
      { pool-id: pool-id, member: tx-sender }
      (merge member-data {
        total-contributed: (+ (get total-contributed member-data) (get contribution-amount pool-data)),
        cycles-contributed: (+ (get cycles-contributed member-data) u1)
      })
    )
    
    (map-set pools
      { pool-id: pool-id }
      (merge pool-data {
        pool-balance: (+ (get pool-balance pool-data) (get contribution-amount pool-data))
      })
    )
    
    (ok true)
  )
)

(define-public (claim-payout (pool-id uint))
  (let
    (
      (pool-data (unwrap! (get-pool pool-id) err-not-found))
      (member-data (unwrap! (get-member-info pool-id tx-sender) err-not-member))
      (current-cycle (get current-cycle pool-data))
      (payout-data (get-payout-info pool-id current-cycle))
    )
    (asserts! (get is-active pool-data) err-pool-inactive)
    (asserts! (is-eq (get position member-data) current-cycle) err-not-your-turn)
    (asserts! (not (get has-received-payout member-data)) err-already-contributed)
    
    (let
      (
        (payout-amount (* (get contribution-amount pool-data) (get max-members pool-data)))
      )
      (asserts! (>= (get pool-balance pool-data) payout-amount) err-insufficient-funds)
      
      (try! (as-contract (stx-transfer? payout-amount tx-sender tx-sender)))
      
      (map-set pool-members
        { pool-id: pool-id, member: tx-sender }
        (merge member-data { has-received-payout: true })
      )
      
      (map-set payout-queue
        { pool-id: pool-id, cycle: current-cycle }
        {
          recipient: tx-sender,
          amount: payout-amount,
          is-paid: true
        }
      )
      
      (map-set pools
        { pool-id: pool-id }
        (merge pool-data {
          pool-balance: (- (get pool-balance pool-data) payout-amount)
        })
      )
      
      (ok payout-amount)
    )
  )
)

(define-public (advance-cycle (pool-id uint))
  (let
    (
      (pool-data (unwrap! (get-pool pool-id) err-not-found))
      (current-cycle (get current-cycle pool-data))
    )
    (asserts! (is-eq tx-sender (get creator pool-data)) err-owner-only)
    (asserts! (get is-active pool-data) err-pool-inactive)
    (asserts! (< current-cycle (get total-cycles pool-data)) err-invalid-amount)
    
    (map-set pools
      { pool-id: pool-id }
      (merge pool-data {
        current-cycle: (+ current-cycle u1)
      })
    )
    
    (if (is-eq (+ current-cycle u1) (+ (get total-cycles pool-data) u1))
      (begin
        (map-set pools
          { pool-id: pool-id }
          (merge pool-data {
            current-cycle: (+ current-cycle u1),
            is-active: false
          })
        )
        (ok true)
      )
      (ok true)
    )
  )
)

(define-public (transfer-position (pool-id uint) (recipient principal))
  (let
    (
      (pool-data (unwrap! (get-pool pool-id) err-not-found))
      (member-data (unwrap! (get-member-info pool-id tx-sender) err-not-member))
      (recipient-exists (is-some (get-member-info pool-id recipient)))
    )
    (asserts! (not (is-eq tx-sender recipient)) err-transfer-to-self)
    (asserts! (not recipient-exists) err-recipient-already-member)
    (asserts! (not (get has-received-payout member-data)) err-already-contributed)
    
    (map-delete pool-members { pool-id: pool-id, member: tx-sender })
    
    (map-set pool-members
      { pool-id: pool-id, member: recipient }
      (merge member-data { joined-at: stacks-block-height })
    )
    
    (ok true)
  )
)

(define-public (penalize-member (pool-id uint) (member principal))
  (let
    (
      (pool-data (unwrap! (get-pool pool-id) err-not-found))
      (member-data (unwrap! (get-member-info pool-id member) err-not-member))
    )
    (asserts! (is-eq tx-sender (get creator pool-data)) err-owner-only)
    
    (map-set pool-members
      { pool-id: pool-id, member: member }
      (merge member-data {
        penalty-count: (+ (get penalty-count member-data) u1)
      })
    )
    
    (ok true)
  )
)

(define-read-only (get-pool-stats (pool-id uint))
  (match (get-pool pool-id)
    pool-data
    (ok {
      total-contributed: (get pool-balance pool-data),
      members-count: (get current-members pool-data),
      current-cycle: (get current-cycle pool-data),
      is-active: (get is-active pool-data)
    })
    err-not-found
  )
)
