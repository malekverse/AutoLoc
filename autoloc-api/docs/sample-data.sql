-- Sample data for autoloc_db.
-- Start the application once first so Hibernate creates the tables, then run this script
-- (MySQL client, DBeaver, or: docker exec -i <container> mysql -uroot -p autoloc_db < sample-data.sql).

INSERT INTO agence (nom, ville, adresse, telephone) VALUES
  ('AutoLoc Paris', 'Paris', '10 rue de Rivoli', '0102030405');

INSERT INTO vehicule (immatriculation, marque, modele, categorie, tarif_journalier, statut, agence_id_agence) VALUES
  ('AB-123-CD', 'Peugeot', '208', 'CITADINE', 35.00, 'DISPONIBLE', 1),
  ('EF-456-GH', 'Renault', 'Megane', 'BERLINE', 50.00, 'LOUE', 1);

INSERT INTO client (nom, prenom, email, telephone, num_permis, date_inscription) VALUES
  ('Martin', 'Lea', 'lea.martin@example.com', '0611223344', 'P123456', CURDATE());

INSERT INTO reservation (date_debut, date_fin, statut, client_id_client, vehicule_id_vehicule) VALUES
  ('2026-12-01', '2026-12-05', 'CONFIRMEE', 1, 2);

INSERT INTO contrat (date_signature, montant_total, valide, reservation_id_reservation) VALUES
  (CURDATE(), 200.00, true, 1);

INSERT INTO paiement (montant, date_paiement, mode_paiement, contrat_id_contrat) VALUES
  (100.00, CURDATE(), 'CARTE', 1),
  (100.00, CURDATE(), 'VIREMENT', 1);

-- Foreign-key check: this fails because vehicles still reference agency 1.
-- DELETE FROM agence WHERE id_agence = 1;
