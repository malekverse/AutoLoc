# Fetch and cascade strategy — AutoLoc

Rule of thumb applied everywhere: **every association is `LAZY`** (including `@ManyToOne` and
`@OneToOne`, whose JPA default is `EAGER`). Related data needed outside a transaction is loaded
with an explicit fetch query (`JOIN FETCH`, `@EntityGraph`) or a DTO projection.
Cascades are only used when the child has no lifecycle of its own.

| Association | Mapping / owning side | Fetch | Cascade | Justification |
|---|---|---|---|---|
| Contrat → Paiement | `@OneToMany(mappedBy = "contrat")` / `@ManyToOne`; `Paiement` owns FK `contrat_id_contrat` | LAZY | ALL + orphanRemoval | Composition: a payment only exists inside its contract. Saving the contract saves its new payments, deleting it deletes them, and removing a payment from the list deletes the row. |
| Agence → Vehicule | `@OneToMany(mappedBy = "agence")` / `@ManyToOne`; `Vehicule` owns FK `agence_id_agence` | LAZY | None | A vehicle survives the closure of an agency (it gets transferred). Deleting an agency must never delete the fleet. |
| Agence → Employe | `@OneToMany(mappedBy = "agence")` / `@ManyToOne`; `Employe` owns FK `agence_id_agence` | LAZY | None | Employees have their own lifecycle (HR data, transfers). Loading an agency should not load its staff. |
| Vehicule ↔ Equipement | `@ManyToMany`; `Vehicule` owns join table `vehicule_equipement` (`vehicule_id`, `equipement_id`); `Equipement` is the `mappedBy` side | LAZY | None | Equipment (GPS, child seat…) is a shared catalogue: removing a vehicle must not delete equipment used by others. `Set` avoids duplicates and Hibernate's inefficient "delete all + reinsert" behaviour on `List` many-to-many. |
| Client → Reservation | `@OneToMany(mappedBy = "client")` / `@ManyToOne`; `Reservation` owns FK `client_id_client` | LAZY | PERSIST | A new client can be saved together with their first reservation. No REMOVE: reservations are history and must not disappear with a client. |
| Reservation → Vehicule | `@ManyToOne` (unidirectional); `Reservation` owns FK `vehicule_id_vehicule` | LAZY | None | The vehicle is an independent resource; a reservation only references it. Unidirectional because a vehicle does not need to navigate to all its reservations (use a repository query instead). |
| Reservation ↔ Contrat | `@OneToOne`; `Contrat` owns FK `reservation_id_reservation` (unique); `Reservation` is the `mappedBy` side | LAZY | ALL (on the Reservation side) | A contract is the result of a reservation (1 — 0..1). Saving/deleting a reservation propagates to its contract. Note: on the inverse (`mappedBy`) side Hibernate can't proxy a nullable one-to-one, so `LAZY` there is only a hint unless bytecode enhancement is enabled. |
| Vehicule → Maintenance | `@OneToMany(mappedBy = "vehicule")` / `@ManyToOne`; `Maintenance` owns FK `vehicule_id_vehicule` | LAZY | PERSIST | A maintenance can be created through its vehicle. No REMOVE: the maintenance history is kept for traceability. |

## LAZY vs EAGER comparison (Contrat → Paiement)

- **LAZY**: `contratRepository.findById(id)` runs a single `select … from contrat`. The `paiement`
  table is only queried when `getPaiements()` is accessed inside an open persistence context;
  outside it you get a `LazyInitializationException`.
- **EAGER** (temporary test): the same call also loads the payments (an extra select or a
  join) every time a contract is read, even when the payments are not used.
- **Final choice**: LAZY restored.

## Keeping both sides in sync

The owning side (`@ManyToOne` / `@JoinColumn` / `@JoinTable`) is the one Hibernate writes to the
database. `Contrat.addPaiement()` / `removePaiement()` update both sides at once so the in-memory
model and the database stay consistent.
