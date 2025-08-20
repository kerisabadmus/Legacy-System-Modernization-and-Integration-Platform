;; Budget Manager Contract
;; Manages project budgets, expenses, and financial tracking

;; Constants
(define-constant ERR-NOT-AUTHORIZED (err u300))
(define-constant ERR-INSUFFICIENT-BUDGET (err u301))
(define-constant ERR-INVALID-AMOUNT (err u302))
(define-constant ERR-EXPENSE-NOT-FOUND (err u303))
(define-constant ERR-BUDGET-NOT-FOUND (err u304))

;; Data Variables
(define-data-var next-expense-id uint u1)

;; Data Maps
(define-map project-budgets
  { project-id: uint }
  {
    total-budget: uint,
    allocated-budget: uint,
    spent-budget: uint,
    remaining-budget: uint,
    manager: principal,
    created-at: uint,
    updated-at: uint
  }
)

(define-map budget-categories
  { project-id: uint, category: (string-ascii 50) }
  {
    allocated-amount: uint,
    spent-amount: uint,
    description: (string-ascii 200)
  }
)

(define-map expenses
  { expense-id: uint }
  {
    project-id: uint,
    category: (string-ascii 50),
    amount: uint,
    description: (string-ascii 200),
    requester: principal,
    approver: (optional principal),
    status: (string-ascii 20),
    created-at: uint,
    approved-at: uint
  }
)

(define-map budget-approvers
  { project-id: uint, approver: principal }
  { authorized: bool, added-at: uint }
)

;; Public Functions

(define-public (initialize-budget (project-id uint) (total-budget uint))
  (begin
    (asserts! (> total-budget u0) ERR-INVALID-AMOUNT)
    (asserts! (is-none (map-get? project-budgets { project-id: project-id })) ERR-BUDGET-NOT-FOUND)

    (map-set project-budgets
      { project-id: project-id }
      {
        total-budget: total-budget,
        allocated-budget: u0,
        spent-budget: u0,
        remaining-budget: total-budget,
        manager: tx-sender,
        created-at: block-height,
        updated-at: block-height
      }
    )

    (map-set budget-approvers
      { project-id: project-id, approver: tx-sender }
      { authorized: true, added-at: block-height }
    )
    (ok true)
  )
)

(define-public (allocate-budget-category (project-id uint) (category (string-ascii 50)) (amount uint) (description (string-ascii 200)))
  (let ((budget (unwrap! (map-get? project-budgets { project-id: project-id }) ERR-BUDGET-NOT-FOUND)))
    (asserts! (is-budget-manager project-id tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (<= (+ (get allocated-budget budget) amount) (get total-budget budget)) ERR-INSUFFICIENT-BUDGET)

    (map-set budget-categories
      { project-id: project-id, category: category }
      {
        allocated-amount: amount,
        spent-amount: u0,
        description: description
      }
    )

    (map-set project-budgets
      { project-id: project-id }
      (merge budget {
        allocated-budget: (+ (get allocated-budget budget) amount),
        remaining-budget: (- (get remaining-budget budget) amount),
        updated-at: block-height
      })
    )
    (ok true)
  )
)

(define-public (submit-expense (project-id uint) (category (string-ascii 50)) (amount uint) (description (string-ascii 200)))
  (let ((expense-id (var-get next-expense-id)))
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (> (len description) u0) ERR-INVALID-AMOUNT)
    (asserts! (is-some (map-get? budget-categories { project-id: project-id, category: category })) ERR-BUDGET-NOT-FOUND)

    (map-set expenses
      { expense-id: expense-id }
      {
        project-id: project-id,
        category: category,
        amount: amount,
        description: description,
        requester: tx-sender,
        approver: none,
        status: "pending",
        created-at: block-height,
        approved-at: u0
      }
    )

    (var-set next-expense-id (+ expense-id u1))
    (ok expense-id)
  )
)

(define-public (approve-expense (expense-id uint))
  (let ((expense (unwrap! (map-get? expenses { expense-id: expense-id }) ERR-EXPENSE-NOT-FOUND))
        (category-budget (unwrap! (map-get? budget-categories { project-id: (get project-id expense), category: (get category expense) }) ERR-BUDGET-NOT-FOUND)))

    (asserts! (is-budget-approver (get project-id expense) tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status expense) "pending") ERR-NOT-AUTHORIZED)
    (asserts! (<= (+ (get spent-amount category-budget) (get amount expense)) (get allocated-amount category-budget)) ERR-INSUFFICIENT-BUDGET)

    ;; Update expense status
    (map-set expenses
      { expense-id: expense-id }
      (merge expense {
        status: "approved",
        approver: (some tx-sender),
        approved-at: block-height
      })
    )

    ;; Update category spending
    (map-set budget-categories
      { project-id: (get project-id expense), category: (get category expense) }
      (merge category-budget {
        spent-amount: (+ (get spent-amount category-budget) (get amount expense))
      })
    )

    ;; Update project budget
    (let ((project-budget (unwrap! (map-get? project-budgets { project-id: (get project-id expense) }) ERR-BUDGET-NOT-FOUND)))
      (map-set project-budgets
        { project-id: (get project-id expense) }
        (merge project-budget {
          spent-budget: (+ (get spent-budget project-budget) (get amount expense)),
          updated-at: block-height
        })
      )
    )
    (ok true)
  )
)

(define-public (add-budget-approver (project-id uint) (approver principal))
  (begin
    (asserts! (is-budget-manager project-id tx-sender) ERR-NOT-AUTHORIZED)

    (map-set budget-approvers
      { project-id: project-id, approver: approver }
      { authorized: true, added-at: block-height }
    )
    (ok true)
  )
)

;; Read-only Functions

(define-read-only (get-project-budget (project-id uint))
  (map-get? project-budgets { project-id: project-id })
)

(define-read-only (get-budget-category (project-id uint) (category (string-ascii 50)))
  (map-get? budget-categories { project-id: project-id, category: category })
)

(define-read-only (get-expense (expense-id uint))
  (map-get? expenses { expense-id: expense-id })
)

(define-read-only (calculate-budget-utilization (project-id uint))
  (match (map-get? project-budgets { project-id: project-id })
    budget (ok (/ (* (get spent-budget budget) u100) (get total-budget budget)))
    ERR-BUDGET-NOT-FOUND
  )
)

;; Private Functions

(define-private (is-budget-manager (project-id uint) (user principal))
  (match (map-get? project-budgets { project-id: project-id })
    budget (is-eq (get manager budget) user)
    false
  )
)

(define-private (is-budget-approver (project-id uint) (user principal))
  (match (map-get? budget-approvers { project-id: project-id, approver: user })
    approver (get authorized approver)
    false
  )
)
