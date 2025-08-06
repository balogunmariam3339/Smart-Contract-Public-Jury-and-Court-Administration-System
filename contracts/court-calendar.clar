;; Court Calendar and Scheduling Contract
;; Manages hearing dates, courtroom assignments, and judge scheduling

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u200))
(define-constant ERR-INVALID-INPUT (err u201))
(define-constant ERR-SCHEDULING-CONFLICT (err u202))
(define-constant ERR-COURTROOM-UNAVAILABLE (err u203))
(define-constant ERR-JUDGE-UNAVAILABLE (err u204))

;; Data Variables
(define-data-var hearing-counter uint u0)
(define-data-var courtroom-counter uint u0)

;; Data Maps
(define-map hearings
  { hearing-id: uint }
  {
    case-id: uint,
    judge-id: uint,
    courtroom-id: uint,
    hearing-date: uint,
    hearing-time: uint,
    duration-minutes: uint,
    hearing-type: (string-ascii 50),
    status: (string-ascii 20),
    participants: (list 10 uint)
  }
)

(define-map courtrooms
  { courtroom-id: uint }
  {
    name: (string-ascii 50),
    capacity: uint,
    equipment: (list 5 (string-ascii 30)),
    available: bool,
    maintenance-schedule: (optional uint)
  }
)

(define-map judges
  { judge-id: uint }
  {
    name: (string-ascii 100),
    specialization: (string-ascii 50),
    available: bool,
    calendar-blocked: (list 20 uint)
  }
)

(define-map daily-schedule
  { date: uint, courtroom-id: uint }
  {
    scheduled-hearings: (list 10 uint),
    available-slots: (list 10 uint)
  }
)

(define-data-var contract-admin principal tx-sender)

;; Authorization check
(define-private (is-authorized (caller principal))
  (or (is-eq caller CONTRACT-OWNER)
      (is-eq caller (var-get contract-admin)))
)

;; Register a new courtroom
(define-public (register-courtroom (name (string-ascii 50)) (capacity uint) (equipment (list 5 (string-ascii 30))))
  (let
    (
      (courtroom-id (+ (var-get courtroom-counter) u1))
    )
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> capacity u0) ERR-INVALID-INPUT)
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)

    (var-set courtroom-counter courtroom-id)
    (map-set courtrooms
      { courtroom-id: courtroom-id }
      {
        name: name,
        capacity: capacity,
        equipment: equipment,
        available: true,
        maintenance-schedule: none
      }
    )
    (ok courtroom-id)
  )
)

;; Register a new judge
(define-public (register-judge (judge-id uint) (name (string-ascii 100)) (specialization (string-ascii 50)))
  (begin
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (map-set judges
      { judge-id: judge-id }
      {
        name: name,
        specialization: specialization,
        available: true,
        calendar-blocked: (list)
      }
    )
    (ok judge-id)
  )
)

;; Schedule a hearing
(define-public (schedule-hearing
  (case-id uint)
  (judge-id uint)
  (courtroom-id uint)
  (hearing-date uint)
  (hearing-time uint)
  (duration-minutes uint)
  (hearing-type (string-ascii 50))
  (participants (list 10 uint)))
  (let
    (
      (hearing-id (+ (var-get hearing-counter) u1))
    )
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> duration-minutes u0) ERR-INVALID-INPUT)
    (asserts! (<= duration-minutes u480) ERR-INVALID-INPUT) ;; Max 8 hours
    (asserts! (is-courtroom-available courtroom-id hearing-date hearing-time) ERR-COURTROOM-UNAVAILABLE)
    (asserts! (is-judge-available judge-id hearing-date) ERR-JUDGE-UNAVAILABLE)

    (var-set hearing-counter hearing-id)
    (map-set hearings
      { hearing-id: hearing-id }
      {
        case-id: case-id,
        judge-id: judge-id,
        courtroom-id: courtroom-id,
        hearing-date: hearing-date,
        hearing-time: hearing-time,
        duration-minutes: duration-minutes,
        hearing-type: hearing-type,
        status: "scheduled",
        participants: participants
      }
    )

    ;; Update daily schedule
    (update-daily-schedule hearing-date courtroom-id hearing-id)
    (ok hearing-id)
  )
)

;; Private function to check courtroom availability
(define-private (is-courtroom-available (courtroom-id uint) (date uint) (time uint))
  (match (map-get? courtrooms { courtroom-id: courtroom-id })
    courtroom-data
    (get available courtroom-data)
    false
  )
)

;; Private function to check judge availability
(define-private (is-judge-available (judge-id uint) (date uint))
  (match (map-get? judges { judge-id: judge-id })
    judge-data
    (get available judge-data)
    false
  )
)

;; Private function to update daily schedule
(define-private (update-daily-schedule (date uint) (courtroom-id uint) (hearing-id uint))
  (let
    (
      (current-schedule (default-to
        { scheduled-hearings: (list), available-slots: (list u9 u10 u11 u13 u14 u15 u16 u17) }
        (map-get? daily-schedule { date: date, courtroom-id: courtroom-id })
      ))
    )
    (map-set daily-schedule
      { date: date, courtroom-id: courtroom-id }
      (merge current-schedule
        { scheduled-hearings: (unwrap-panic (as-max-len? (append (get scheduled-hearings current-schedule) hearing-id) u10)) }
      )
    )
  )
)

;; Reschedule a hearing
(define-public (reschedule-hearing
  (hearing-id uint)
  (new-date uint)
  (new-time uint)
  (new-courtroom-id uint))
  (begin
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (match (map-get? hearings { hearing-id: hearing-id })
      hearing-data
      (begin
        (asserts! (is-courtroom-available new-courtroom-id new-date new-time) ERR-COURTROOM-UNAVAILABLE)
        (map-set hearings
          { hearing-id: hearing-id }
          (merge hearing-data {
            hearing-date: new-date,
            hearing-time: new-time,
            courtroom-id: new-courtroom-id,
            status: "rescheduled"
          })
        )
        (ok true)
      )
      ERR-INVALID-INPUT
    )
  )
)

;; Cancel a hearing
(define-public (cancel-hearing (hearing-id uint) (reason (string-ascii 200)))
  (begin
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (match (map-get? hearings { hearing-id: hearing-id })
      hearing-data
      (begin
        (map-set hearings
          { hearing-id: hearing-id }
          (merge hearing-data { status: "cancelled" })
        )
        (ok true)
      )
      ERR-INVALID-INPUT
    )
  )
)

;; Set courtroom maintenance
(define-public (set-courtroom-maintenance (courtroom-id uint) (maintenance-date uint))
  (begin
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (match (map-get? courtrooms { courtroom-id: courtroom-id })
      courtroom-data
      (begin
        (map-set courtrooms
          { courtroom-id: courtroom-id }
          (merge courtroom-data {
            available: false,
            maintenance-schedule: (some maintenance-date)
          })
        )
        (ok true)
      )
      ERR-INVALID-INPUT
    )
  )
)

;; Read-only functions
(define-read-only (get-hearing-info (hearing-id uint))
  (map-get? hearings { hearing-id: hearing-id })
)

(define-read-only (get-courtroom-info (courtroom-id uint))
  (map-get? courtrooms { courtroom-id: courtroom-id })
)

(define-read-only (get-judge-info (judge-id uint))
  (map-get? judges { judge-id: judge-id })
)

(define-read-only (get-daily-schedule (date uint) (courtroom-id uint))
  (map-get? daily-schedule { date: date, courtroom-id: courtroom-id })
)

(define-read-only (get-hearing-status (hearing-id uint))
  (match (map-get? hearings { hearing-id: hearing-id })
    hearing-data
    (some (get status hearing-data))
    none
  )
)
