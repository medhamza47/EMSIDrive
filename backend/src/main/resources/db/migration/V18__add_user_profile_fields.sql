-- Profile details a student can edit from the mobile app.
-- Values are free text because EMSI filieres and academic years evolve every year.
ALTER TABLE users
    ADD COLUMN filiere       VARCHAR(60),
    ADD COLUMN academic_year VARCHAR(20),
    ADD COLUMN photo_url     VARCHAR(500);
