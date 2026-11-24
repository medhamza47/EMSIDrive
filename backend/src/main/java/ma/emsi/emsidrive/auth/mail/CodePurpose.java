package ma.emsi.emsidrive.auth.mail;

/** Why a code is emailed; each purpose has its own wording in the shared template. */
public enum CodePurpose {

    PASSWORD_RESET(
            "EMSIDrive - Réinitialisation du mot de passe",
            "Réinitialisation du mot de passe",
            "Saisissez ce code dans l’application EMSIDrive pour choisir un nouveau mot de passe.",
            " Après le changement, tous vos appareils seront déconnectés.",
            "Vous n’avez pas demandé cette réinitialisation ? Ignorez ce message : votre mot de passe "
                    + "actuel reste inchangé. Ne communiquez jamais ce code."),

    REGISTRATION(
            "EMSIDrive - Confirmez votre adresse e-mail",
            "Confirmez votre adresse e-mail",
            "Bienvenue sur EMSIDrive ! Saisissez ce code dans l’application pour terminer la création "
                    + "de votre compte.",
            "",
            "Vous n’avez pas créé de compte EMSIDrive ? Ignorez ce message : aucun compte n’est créé "
                    + "sans ce code. Ne communiquez jamais ce code.");

    /** Subject line; never contains the code, which lock screens would show. */
    final String subject;
    final String title;
    final String intro;
    /** Sentence appended after the validity line, empty when there is nothing to add. */
    final String afterValidity;
    final String notice;

    CodePurpose(String subject, String title, String intro, String afterValidity, String notice) {
        this.subject = subject;
        this.title = title;
        this.intro = intro;
        this.afterValidity = afterValidity;
        this.notice = notice;
    }
}
