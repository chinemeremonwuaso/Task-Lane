;; Collaborative Project Management Smart Contract
;; A decentralized platform for managing collaborative projects, task assignments, 
;; milestone tracking, and automated payments between team members with performance metrics

;; ERROR CONSTANTS
(define-constant err-unauthorized-access (err u100))
(define-constant err-project-does-not-exist (err u101))
(define-constant err-task-does-not-exist (err u102))
(define-constant err-invalid-status-transition (err u103))
(define-constant err-insufficient-project-balance (err u104))
(define-constant err-project-id-already-exists (err u105))
(define-constant err-task-id-already-exists (err u106))
(define-constant err-invalid-parameter-provided (err u107))
(define-constant err-team-member-already-exists (err u108))
(define-constant err-maximum-team-size-exceeded (err u109))

;; DATA STRUCTURE DEFINITIONS

;; Core project information storage
(define-map collaborative-projects
    { project-id: uint }
    {
        project-owner-address: principal,
        project-name: (string-ascii 50),
        detailed-project-description: (string-ascii 500),
        allocated-project-budget: uint,
        current-project-status: (string-ascii 20),
        project-created-at-block: uint,
        registered-team-members: (list 20 principal)
    }
)

;; Individual task management within projects
(define-map project-task-assignments
    { parent-project-id: uint, assigned-task-id: uint }
    {
        responsible-team-member: principal,
        task-title-description: (string-ascii 50),
        comprehensive-task-details: (string-ascii 500),
        task-completion-deadline: uint,
        task-compensation-amount: uint,
        current-task-status: (string-ascii 20),
        task-created-at-block: uint
    }
)

;; Global project ID counter management
(define-map global-sequence-counters
    { counter-category: (string-ascii 10) }
    { next-available-id: uint }
)

;; Per-project task ID counter management
(define-map project-task-counters
    { parent-project-id: uint }
    { next-task-id: uint }
)

;; Team member performance tracking and analytics
(define-map team-member-performance-data
    { member-wallet-address: principal }
    {
        total-completed-tasks: uint,
        cumulative-earnings-amount: uint,
        average-performance-score: uint,
        total-received-ratings: uint
    }
)

;; PRIVATE UTILITY FUNCTIONS

;; Verify if the requesting address owns the specified project
(define-private (validate-project-ownership (target-project-id uint) (requesting-wallet-address principal))
    (match (map-get? collaborative-projects { project-id: target-project-id })
        retrieved-project-data (is-eq (get project-owner-address retrieved-project-data) requesting-wallet-address)
        false
    )
)

;; Check if requesting address is project owner or team member
(define-private (validate-team-membership-access (target-project-id uint) (requesting-wallet-address principal))
    (match (map-get? collaborative-projects { project-id: target-project-id })
        retrieved-project-data (or
            (is-eq (get project-owner-address retrieved-project-data) requesting-wallet-address)
            (is-some (index-of (get registered-team-members retrieved-project-data) requesting-wallet-address))
        )
        false
    )
)

;; Generate unique project identifier using global counter
(define-private (generate-new-project-id)
    (let ((current-counter-state (default-to { next-available-id: u0 } 
                                            (map-get? global-sequence-counters { counter-category: "projects" }))))
        (begin
            (map-set global-sequence-counters 
                    { counter-category: "projects" } 
                    { next-available-id: (+ (get next-available-id current-counter-state) u1) })
            (get next-available-id current-counter-state)
        )
    )
)

;; Generate unique task identifier within a specific project
(define-private (generate-new-task-id (target-project-id uint))
    (match (map-get? collaborative-projects { project-id: target-project-id })
        retrieved-project-data 
            (let ((current-task-counter (default-to { next-task-id: u0 } 
                                                   (map-get? project-task-counters { parent-project-id: target-project-id }))))
                (begin
                    (map-set project-task-counters 
                            { parent-project-id: target-project-id } 
                            { next-task-id: (+ (get next-task-id current-task-counter) u1) })
                    (ok (get next-task-id current-task-counter))
                )
            )
        (err err-project-does-not-exist)
    )
)

;; Validate that all required project parameters are properly formatted
(define-private (validate-project-creation-parameters (project-name (string-ascii 50)) 
                                                     (project-description (string-ascii 500)) 
                                                     (project-budget uint))
    (and 
        (> (len project-name) u0)
        (> (len project-description) u0)
        (> project-budget u0)
    )
)

;; Validate task creation parameters including team member verification
(define-private (validate-task-creation-parameters (project-data-tuple {project-owner-address: principal, 
                                                                        project-name: (string-ascii 50),
                                                                        detailed-project-description: (string-ascii 500),
                                                                        allocated-project-budget: uint,
                                                                        current-project-status: (string-ascii 20),
                                                                        project-created-at-block: uint,
                                                                        registered-team-members: (list 20 principal)})
                                                   (task-name (string-ascii 50))
                                                   (task-description (string-ascii 500))
                                                   (assigned-member-address principal)
                                                   (task-deadline uint)
                                                   (task-payment uint))
    (and 
        (> (len task-name) u0)
        (> (len task-description) u0)
        (> task-deadline block-height)
        (> task-payment u0)
        (or
            (is-eq assigned-member-address (get project-owner-address project-data-tuple))
            (is-some (index-of (get registered-team-members project-data-tuple) assigned-member-address))
        )
    )
)

;; Comprehensive input validation function for all user inputs
(define-private (validate-all-inputs (project-name-opt (optional (string-ascii 50)))
                                   (description-opt (optional (string-ascii 500)))
                                   (budget-opt (optional uint))
                                   (project-id-opt (optional uint))
                                   (task-id-opt (optional uint))
                                   (status-opt (optional (string-ascii 20)))
                                   (member-opt (optional principal))
                                   (rating-opt (optional uint)))
    (let ((project-name-valid (match project-name-opt
                                some-name (> (len some-name) u0)
                                true))
          (description-valid (match description-opt
                               some-desc (> (len some-desc) u0)
                               true))
          (budget-valid (match budget-opt
                          some-budget (> some-budget u0)
                          true))
          (project-id-valid (match project-id-opt
                              some-id (>= some-id u0)
                              true))
          (task-id-valid (match task-id-opt
                           some-id (>= some-id u0)
                           true))
          (status-valid (match status-opt
                          some-status (> (len some-status) u0)
                          true))
          (rating-valid (match rating-opt
                          some-rating (and (>= some-rating u1) (<= some-rating u5))
                          true)))
        (and project-name-valid description-valid budget-valid 
             project-id-valid task-id-valid status-valid rating-valid)))

;; PUBLIC INTERFACE FUNCTIONS

;; Create a new collaborative project with specified parameters
(define-public (create-new-collaborative-project (project-name (string-ascii 50)) 
                                                (detailed-description (string-ascii 500)) 
                                                (initial-budget uint))
    (let ((new-project-id (generate-new-project-id))
          (project-creator-address tx-sender))
        (asserts! (validate-all-inputs (some project-name) (some detailed-description) 
                                     (some initial-budget) none none none none none) 
                 err-invalid-parameter-provided)
        (asserts! (validate-project-creation-parameters project-name detailed-description initial-budget)
                 err-invalid-parameter-provided)
        (map-set collaborative-projects
            { project-id: new-project-id }
            {
                project-owner-address: project-creator-address,
                project-name: project-name,
                detailed-project-description: detailed-description,
                allocated-project-budget: initial-budget,
                current-project-status: "active",
                project-created-at-block: block-height,
                registered-team-members: (list)
            }
        )
        (ok new-project-id)
    )
)

;; Add a new team member to an existing project
(define-public (add-team-member-to-project (target-project-id uint) (new-member-wallet-address principal))
    (let ((requesting-user-address tx-sender))
        (asserts! (validate-all-inputs none none none (some target-project-id) 
                                     none none (some new-member-wallet-address) none)
                 err-invalid-parameter-provided)
        (match (map-get? collaborative-projects { project-id: target-project-id })
            existing-project-data
                (begin
                    (asserts! (is-eq (get project-owner-address existing-project-data) requesting-user-address)
                             err-unauthorized-access)
                    (asserts! (is-none (index-of (get registered-team-members existing-project-data) new-member-wallet-address))
                             err-team-member-already-exists)
                    (map-set collaborative-projects
                        { project-id: target-project-id }
                        (merge existing-project-data { 
                            registered-team-members: (unwrap! (as-max-len? 
                                                              (append (get registered-team-members existing-project-data) 
                                                                     new-member-wallet-address) 
                                                              u20) 
                                                             err-maximum-team-size-exceeded) 
                        })
                    )
                    (ok true)
                )
            err-project-does-not-exist
        )
    )
)

;; Create and assign a new task to a team member
(define-public (create-and-assign-task
    (target-project-id uint)
    (task-name (string-ascii 50))
    (comprehensive-task-description (string-ascii 500))
    (designated-assignee-address principal)
    (task-completion-deadline uint)
    (task-payment-amount uint)
)
    (let ((requesting-user-address tx-sender))
        (asserts! (validate-all-inputs (some task-name) (some comprehensive-task-description) 
                                     (some task-payment-amount) (some target-project-id) 
                                     none none (some designated-assignee-address) none)
                 err-invalid-parameter-provided)
        (asserts! (> task-completion-deadline block-height) err-invalid-parameter-provided)
        (match (map-get? collaborative-projects { project-id: target-project-id })
            existing-project-data
                (begin
                    (asserts! (is-eq (get project-owner-address existing-project-data) requesting-user-address)
                             err-unauthorized-access)
                    (asserts! (validate-task-creation-parameters existing-project-data 
                                                               task-name 
                                                               comprehensive-task-description 
                                                               designated-assignee-address 
                                                               task-completion-deadline 
                                                               task-payment-amount)
                             err-invalid-parameter-provided)
                    (match (generate-new-task-id target-project-id)
                        generated-task-id
                            (begin
                                (map-set project-task-assignments
                                    { parent-project-id: target-project-id, assigned-task-id: generated-task-id }
                                    {
                                        responsible-team-member: designated-assignee-address,
                                        task-title-description: task-name,
                                        comprehensive-task-details: comprehensive-task-description,
                                        task-completion-deadline: task-completion-deadline,
                                        task-compensation-amount: task-payment-amount,
                                        current-task-status: "pending",
                                        task-created-at-block: block-height
                                    }
                                )
                                (ok generated-task-id)
                            )
                        error-response err-project-does-not-exist
                    )
                )
            err-project-does-not-exist
        )
    )
)

;; Update the status of an existing task
(define-public (modify-task-status (target-project-id uint) 
                                  (target-task-id uint) 
                                  (updated-status-value (string-ascii 20)))
    (let ((requesting-user-address tx-sender))
        (asserts! (validate-all-inputs none none none (some target-project-id) 
                                     (some target-task-id) (some updated-status-value) none none)
                 err-invalid-parameter-provided)
        (match (map-get? collaborative-projects { project-id: target-project-id })
            existing-project-data
                (match (map-get? project-task-assignments { parent-project-id: target-project-id, assigned-task-id: target-task-id })
                    existing-task-data
                        (begin
                            (asserts! (or (is-eq (get project-owner-address existing-project-data) requesting-user-address) 
                                         (is-eq (get responsible-team-member existing-task-data) requesting-user-address))
                                     err-unauthorized-access)
                            (map-set project-task-assignments
                                { parent-project-id: target-project-id, assigned-task-id: target-task-id }
                                (merge existing-task-data { current-task-status: updated-status-value })
                            )
                            (ok true)
                        )
                    err-task-does-not-exist
                )
            err-project-does-not-exist
        )
    )
)

;; Complete a task and process payment automatically
(define-public (finalize-task-completion (target-project-id uint) (target-task-id uint))
    (let ((requesting-user-address tx-sender))
        (asserts! (validate-all-inputs none none none (some target-project-id) 
                                     (some target-task-id) none none none)
                 err-invalid-parameter-provided)
        (match (map-get? collaborative-projects { project-id: target-project-id })
            existing-project-data
                (match (map-get? project-task-assignments { parent-project-id: target-project-id, assigned-task-id: target-task-id })
                    existing-task-data
                        (begin
                            (asserts! (is-eq (get responsible-team-member existing-task-data) requesting-user-address)
                                     err-unauthorized-access)
                            (asserts! (is-eq (get current-task-status existing-task-data) "pending")
                                     err-invalid-status-transition)
                            ;; Process payment transfer from project owner to task assignee
                            (try! (stx-transfer? (get task-compensation-amount existing-task-data) 
                                               (get project-owner-address existing-project-data) 
                                               requesting-user-address))
                            ;; Update task status to completed
                            (map-set project-task-assignments
                                { parent-project-id: target-project-id, assigned-task-id: target-task-id }
                                (merge existing-task-data { current-task-status: "completed" })
                            )
                            ;; Update team member performance metrics
                            (let ((current-member-metrics (default-to
                                    { total-completed-tasks: u0, cumulative-earnings-amount: u0, average-performance-score: u0, total-received-ratings: u0 }
                                    (map-get? team-member-performance-data { member-wallet-address: requesting-user-address })
                                )))
                                (map-set team-member-performance-data
                                    { member-wallet-address: requesting-user-address }
                                    {
                                        total-completed-tasks: (+ (get total-completed-tasks current-member-metrics) u1),
                                        cumulative-earnings-amount: (+ (get cumulative-earnings-amount current-member-metrics) 
                                                                      (get task-compensation-amount existing-task-data)),
                                        average-performance-score: (get average-performance-score current-member-metrics),
                                        total-received-ratings: (get total-received-ratings current-member-metrics)
                                    }
                                )
                            )
                            (ok true)
                        )
                    err-task-does-not-exist
                )
            err-project-does-not-exist
        )
    )
)

;; Submit performance rating for a team member
(define-public (submit-team-member-rating (target-member-address principal) (performance-rating-score uint))
    (begin
        (asserts! (validate-all-inputs none none none none none none 
                                     (some target-member-address) (some performance-rating-score))
                 err-invalid-parameter-provided)
        (let ((current-member-metrics (default-to
                { total-completed-tasks: u0, cumulative-earnings-amount: u0, average-performance-score: u0, total-received-ratings: u0 }
                (map-get? team-member-performance-data { member-wallet-address: target-member-address })
            )))
            (map-set team-member-performance-data
                { member-wallet-address: target-member-address }
                {
                    total-completed-tasks: (get total-completed-tasks current-member-metrics),
                    cumulative-earnings-amount: (get cumulative-earnings-amount current-member-metrics),
                    average-performance-score: (/ (+ (* (get average-performance-score current-member-metrics) 
                                                      (get total-received-ratings current-member-metrics)) 
                                                   performance-rating-score) 
                                                (+ (get total-received-ratings current-member-metrics) u1)),
                    total-received-ratings: (+ (get total-received-ratings current-member-metrics) u1)
                }
            )
            (ok true)
        )
    )
)

;; READ-ONLY QUERY FUNCTIONS

;; Retrieve complete project information
(define-read-only (fetch-project-information (target-project-id uint))
    (begin
        (asserts! (validate-all-inputs none none none (some target-project-id) 
                                     none none none none) 
                 none)
        (map-get? collaborative-projects { project-id: target-project-id })
    )
)

;; Retrieve specific task details
(define-read-only (fetch-task-information (target-project-id uint) (target-task-id uint))
    (begin
        (asserts! (validate-all-inputs none none none (some target-project-id) 
                                     (some target-task-id) none none none)
                 none)
        (map-get? project-task-assignments { parent-project-id: target-project-id, assigned-task-id: target-task-id })
    )
)

;; Get team member performance analytics
(define-read-only (fetch-member-performance-analytics (target-member-address principal))
    (map-get? team-member-performance-data { member-wallet-address: target-member-address })
)

;; Verify if an address has access to a specific project
(define-read-only (check-project-access-permissions (target-project-id uint) (requesting-member-address principal))
    (begin
        (asserts! (validate-all-inputs none none none (some target-project-id) 
                                     none none (some requesting-member-address) none)
                 false)
        (validate-team-membership-access target-project-id requesting-member-address)
    )
)