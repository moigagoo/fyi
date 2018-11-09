ALTER TABLE entries ADD COLUMN rating INT;
UPDATE entries SET rating = 0;
ALTER TABLE entries ALTER COLUMN rating SET DEFAULT 0;