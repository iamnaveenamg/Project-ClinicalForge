-- =========================================================================
-- 11. SEED DATA: FINANCIAL.BILLINGINVOICES (10 Records)
-- =========================================================================
SET IDENTITY_INSERT Financial.BillingInvoices ON;
INSERT INTO Financial.BillingInvoices (InvoiceID, EncounterID, PatientID, InvoiceNumber, GrossAmount, NetOutstandingBalance, InvoiceStatus, LastModifiedDateTime) VALUES
(1, 1, 1, 'INV-2026-001', 150.0000, 0.0000, 'Fully Paid', '2026-09-12 17:00:00'),
(2, 2, 2, 'INV-2026-002', 120.0000, 20.0000, 'Written-Off', '2026-09-12 17:00:00'),
(3, 3, 4, 'INV-2026-003', 350.0000, 0.0000, 'Fully Paid', '2026-09-12 17:00:00'),
(4, 5, 5, 'INV-2026-004', 1200.0000, 150.0000, 'Active', '2026-09-12 17:00:00'),
(5, 6, 7, 'INV-2026-005', 8500.0000, 0.0000, 'Fully Paid', '2026-09-12 17:00:00'),
(6, 10, 10, 'INV-2026-006', 450.0000, 0.0000, 'Fully Paid', '2026-09-12 17:00:00'),
(7, 4, 3, 'INV-2026-007', 3100.0000, 3100.0000, 'Active', '2026-09-12 18:00:00'),
(8, 7, 1, 'INV-2026-008', 14200.0000, 14200.0000, 'Active', '2026-09-12 18:00:00'),
(9, 9, 9, 'INV-2026-009', 5400.0000, 5400.0000, 'Active', '2026-09-12 18:00:00'),
(10, 1, 1, 'INV-2026-010', 85.0000, 85.0000, 'Active', '2026-09-12 18:15:00');
SET IDENTITY_INSERT Financial.BillingInvoices OFF;
GO