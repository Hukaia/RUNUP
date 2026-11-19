import SwiftUI
import AuthenticationServices

/// LE COMPTE : se connecter ou en créer un — avec Apple, ou avec une adresse e-mail et un mot de passe —
/// puis choisir son pseudo. C'est ce qui donne à quelqu'un ses identifiants pour le Club et les amis.
///
/// Deux emplois, un seul écran :
/// · dans l'inscription (`dansLInscription`), c'est la dernière question : le compte enregistre le
///   programme qu'on vient de choisir, et le prénom et le nom déjà donnés l'accompagnent. « Plus tard »
///   le laisse pour après : le plan fonctionne sans compte, seul le Club en demande un ;
/// · partout ailleurs, c'est une feuille qu'on ouvre quand le Club ou les amis le demandent.
struct SignInView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    var dansLInscription: Bool = false
    var onTermine: (() -> Void)? = nil

    @State private var mode: Mode
    @State private var name = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    @State private var showChooseUsername = false
    @State private var usernameField = ""
    @State private var isSavingUsername = false
    @State private var usernameError: String?

    private enum Mode { case signIn, signUp }

    init(dansLInscription: Bool = false, onTermine: (() -> Void)? = nil) {
        self.dansLInscription = dansLInscription
        self.onTermine = onTermine
        _mode = State(initialValue: dansLInscription ? .signUp : .signIn)
    }

    /// Le nom est déjà connu quand on arrive de l'inscription : le redemander ferait deux fois la même
    /// question.
    private var nomConnu: Bool {
        dansLInscription && !appState.profile.name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        if dansLInscription {
            ScrollView {
                corps.padding(.top, HZEntree.sousLaProgression)
            }
            .scrollIndicators(.hidden)
            .disabled(isLoading)
            .overlay { if isLoading { ProgressView() } }
        } else {
            HZFeuilleModale(titre: showChooseUsername ? String(localized: "Choisis ton pseudo")
                                                      : String(localized: "Connecte-toi")) {
                ScrollView { corps }
                    .scrollIndicators(.hidden)
            }
            .disabled(isLoading)
            .overlay { if isLoading { ProgressView() } }
        }
    }

    @ViewBuilder private var corps: some View {
        if showChooseUsername {
            choixDuPseudo
        } else {
            VStack(alignment: .leading, spacing: HZEspace.groupe) {
                if dansLInscription {
                    Text(String(localized: "Enregistre ton programme"))
                        .hzAffichage(.titreDeReglages)
                        .foregroundStyle(HZCouleur.encre)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Text(dansLInscription
                     ? String(localized: "Un compte garde ton programme et te donne tes identifiants pour le Club : un classement et un fil d'activité réels, et tes amis qui te retrouvent.")
                     : String(localized: "Pour rejoindre un vrai club, avec un classement et un fil d'activité réels."))
                    .hzParagraphe(.c15, .medium, interligne: HZBandeauDuCoach.interligne)
                    .foregroundStyle(HZCouleur.secondaireSurClair)
                    .fixedSize(horizontal: false, vertical: true)

                SignInWithAppleButton(mode == .signUp ? .signUp : .signIn,
                                      onRequest: configureAppleRequest, onCompletion: handleAppleCompletion)
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: HZHauteurDeBouton.grande.rawValue)
                    .clipShape(Capsule())

                HStack(spacing: HZEspace.entreCommandes) {
                    Rectangle().fill(HZCouleur.filetGroupe).frame(height: HZMesuresDeLigne.filet)
                    Text("ou").hzTexte(.c13, .semi).foregroundStyle(HZCouleur.secondaireSurClair)
                    Rectangle().fill(HZCouleur.filetGroupe).frame(height: HZMesuresDeLigne.filet)
                }

                emailForm

                if let errorMessage {
                    Text(errorMessage)
                        .hzParagraphe(.c14, .semi, interligne: HZBandeauDuCoach.interligne)
                        .foregroundStyle(HZCouleur.encre)
                        .padding(HZEspace.groupe)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(HZCouleur.surfaceClaire,
                                    in: RoundedRectangle(cornerRadius: HZRayon.bandeau, style: .circular))
                }

                Button(mode == .signIn ? "Pas de compte ? Crée-en un" : "Déjà un compte ? Connecte-toi") {
                    mode = mode == .signIn ? .signUp : .signIn
                    errorMessage = nil
                }
                .hzTexte(.c14, .semi)
                .foregroundStyle(HZCouleur.encre)
                .frame(maxWidth: .infinity, minHeight: HZBoutonRond.zoneTactile)
                .contentShape(Rectangle())
                .buttonStyle(.plain)

                if dansLInscription {
                    Button("Plus tard") { terminer() }
                        .hzTexte(.c14, .semi)
                        .foregroundStyle(HZCouleur.secondaireSurClair)
                        .frame(maxWidth: .infinity, minHeight: HZBoutonRond.zoneTactile)
                        .contentShape(Rectangle())
                        .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, dansLInscription ? 0 : HZEspace.marge)
        }
    }

    private var choixDuPseudo: some View {
        VStack(alignment: .leading, spacing: HZEspace.groupe) {
            if dansLInscription {
                Text(String(localized: "Choisis ton pseudo"))
                    .hzAffichage(.titreDeReglages)
                    .foregroundStyle(HZCouleur.encre)
            }
            Text("Pour que tes amis te retrouvent facilement dans la recherche.")
                .hzParagraphe(.c15, .medium, interligne: HZBandeauDuCoach.interligne)
                .foregroundStyle(HZCouleur.secondaireSurClair)
                .fixedSize(horizontal: false, vertical: true)
            HZChampDeTexte(titre: String(localized: "Pseudo"), invite: String(localized: "lettres minuscules, chiffres, _"),
                           texte: $usernameField, majuscules: .never)
            if let usernameError {
                Text(usernameError)
                    .hzParagraphe(.c14, .semi, interligne: HZBandeauDuCoach.interligne)
                    .foregroundStyle(HZCouleur.encre)
                    .fixedSize(horizontal: false, vertical: true)
            }
            let valide = isValidUsernameFormat(usernameField) && !isSavingUsername
            HZBoutonPilule(libelle: isSavingUsername ? "…" : String(localized: "Continuer"),
                           fond: valide ? HZCouleur.encre : HZCouleur.filetGroupe,
                           couleur: valide ? HZCouleur.blanc : HZCouleur.secondaireSurClair,
                           etendu: true) { Task { await saveUsername() } }
                .disabled(!valide)
            Button("Plus tard") { terminer() }
                .hzTexte(.c14, .semi)
                .foregroundStyle(HZCouleur.secondaireSurClair)
                .frame(maxWidth: .infinity, minHeight: HZBoutonRond.zoneTactile)
                .contentShape(Rectangle())
                .buttonStyle(.plain)
                .disabled(isSavingUsername)
        }
        .padding(.horizontal, dansLInscription ? 0 : HZEspace.marge)
        .onAppear {
            guard usernameField.isEmpty else { return }
            usernameField = suggestedUsername()
        }
    }

    private var emailForm: some View {
        VStack(alignment: .leading, spacing: HZEspace.entreCommandes) {
            if mode == .signUp && !nomConnu {
                HZChampDeTexte(titre: String(localized: "Prénom"), invite: String(localized: "Ton prénom"),
                               texte: $name, majuscules: .words, contenu: .givenName)
                HZChampDeTexte(titre: String(localized: "Nom (facultatif)"),
                               invite: String(localized: "Ton nom de famille"),
                               texte: $lastName, majuscules: .words, contenu: .familyName)
            }
            HZChampDeTexte(titre: String(localized: "Email"), invite: String(localized: "prenom@exemple.com"),
                           texte: $email, clavier: .emailAddress, majuscules: .never, contenu: .emailAddress)
            HZChampDeTexte(titre: String(localized: "Mot de passe"), invite: String(localized: "8 caractères minimum"),
                           texte: $password, securise: true,
                           contenu: mode == .signIn ? .password : .newPassword)

            if !email.isEmpty && !isValidEmailFormat {
                Text("Adresse email invalide.").hzTexte(.c13, .semi).foregroundStyle(HZCouleur.encre)
            }
            if mode == .signUp && !password.isEmpty && password.count < HZHub.longueurDuMotDePasse {
                Text("8 caractères minimum.").hzTexte(.c13, .semi).foregroundStyle(HZCouleur.encre)
            }

            HZBoutonPilule(libelle: mode == .signIn ? String(localized: "Me connecter")
                                                    : String(localized: "Créer mon compte"),
                           fond: isEmailFormSubmittable ? HZCouleur.encre : HZCouleur.filetGroupe,
                           couleur: isEmailFormSubmittable ? HZCouleur.blanc : HZCouleur.secondaireSurClair,
                           etendu: true) { submitEmailForm() }
                .disabled(!isEmailFormSubmittable)
        }
    }

    private var isValidEmailFormat: Bool {
        email.range(of: #"^\S+@\S+\.\S+$"#, options: .regularExpression) != nil
    }

    private var isEmailFormSubmittable: Bool {
        guard isValidEmailFormat, !password.isEmpty else { return false }
        if mode == .signUp {
            let prenom = nomConnu ? appState.profile.name : name
            return password.count >= HZHub.longueurDuMotDePasse && !prenom.trimmingCharacters(in: .whitespaces).isEmpty
        }
        return true
    }

    private func terminer() {
        if let onTermine { onTermine() } else { dismiss() }
    }

    // MARK: Apple

    private func configureAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }

    /// Apple ne rend le nom QU'À LA PREMIÈRE connexion, et parfois pas du tout : le prénom et le nom que
    /// la personne a donnés à l'inscription prennent le relais, sans quoi elle arriverait au Club sans
    /// nom.
    private func handleAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let identityToken = String(data: tokenData, encoding: .utf8) else {
                errorMessage = String(localized: "Connexion Apple impossible.")
                return
            }
            let prenomDeLInscription = appState.profile.name.trimmingCharacters(in: .whitespaces)
            let nomDeLInscription = appState.profile.lastName.trimmingCharacters(in: .whitespaces)
            let givenName = credential.fullName?.givenName
                ?? (prenomDeLInscription.isEmpty ? nil : prenomDeLInscription)
            let familyName = credential.fullName?.familyName
                ?? (nomDeLInscription.isEmpty ? nil : nomDeLInscription)
            Task { await runAuth { try await appState.auth.signInWithApple(identityToken: identityToken, name: givenName, lastName: familyName) } }
        case .failure:
            errorMessage = String(localized: "Connexion Apple annulée ou impossible.")
        }
    }

    // MARK: E-mail

    private func submitEmailForm() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        Task {
            await runAuth {
                if mode == .signIn {
                    try await appState.auth.logIn(email: trimmedEmail, password: password)
                } else {
                    let prenom = nomConnu ? appState.profile.name : name
                    let nomDeFamille = (nomConnu ? appState.profile.lastName : lastName)
                        .trimmingCharacters(in: .whitespaces)
                    try await appState.auth.signUp(
                        email: trimmedEmail, password: password, name: prenom.trimmingCharacters(in: .whitespaces),
                        lastName: nomDeFamille.isEmpty ? nil : nomDeFamille
                    )
                }
            }
        }
    }

    @MainActor
    private func runAuth(_ action: @escaping () async throws -> Void) async {
        isLoading = true
        errorMessage = nil
        do {
            try await action()
            Task { await NotificationService.shared.sendPendingDeviceTokenIfSignedIn() }
            if let jpeg = appState.profile.avatarImageData {
                let dataURI = "data:image/jpeg;base64,\(jpeg.base64EncodedString())"
                Task { try? await appState.auth.updateAvatar(dataURI: dataURI) }
            }
            if appState.auth.currentUser?.username == nil {
                showChooseUsername = true
            } else {
                terminer()
            }
        } catch AuthServiceError.badResponse(let code, let corps) where code == HZHub.conflit {
            errorMessage = corps.contains("email_has_password_account")
                ? String(localized: "Cette adresse a déjà un compte avec mot de passe. Connecte-toi avec ton mot de passe.")
                : String(localized: "Un compte existe déjà avec cet email.")
        } catch AuthServiceError.badResponse(let code, _) where code == HZHub.nonAutorise {
            errorMessage = String(localized: "Email ou mot de passe incorrect.")
        } catch AuthServiceError.badResponse(let code, _) where code == HZHub.refuse {
            errorMessage = String(localized: "Ce prénom n'est pas autorisé — choisis-en un autre.")
        } catch {
            errorMessage = PanneReseau.phrase(pour: error)
        }
        isLoading = false
    }

    // MARK: Pseudo

    private func isValidUsernameFormat(_ value: String) -> Bool {
        let clean = value.trimmingCharacters(in: .whitespaces).lowercased()
        guard clean.count >= HZHub.pseudoMinimal, clean.count <= HZHub.pseudoMaximal else { return false }
        return clean.allSatisfy { $0.isLowercase || $0.isNumber || $0 == "_" }
    }

    private func suggestedUsername() -> String {
        let base = (appState.auth.currentUser?.name ?? (nomConnu ? appState.profile.name : name))
            .folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()
            .filter { $0.isLetter || $0.isNumber }
            .prefix(HZHub.baseDuPseudo)
        let suffix = Int.random(in: HZHub.suffixesDePseudo)
        let candidate = "\(base)\(suffix)"
        return candidate.count >= HZHub.pseudoMinimal ? candidate : "coureur\(suffix)"
    }

    private func saveUsername() async {
        isSavingUsername = true
        usernameError = nil
        let clean = usernameField.trimmingCharacters(in: .whitespaces).lowercased()
        do {
            try await ClubService(auth: appState.auth).updateProfile(username: clean)
            _ = try? await appState.auth.refreshMe()
            terminer()
        } catch ClubServiceError.badResponse(let code, _) where code == HZHub.conflit {
            usernameError = String(localized: "Ce pseudo est déjà pris.")
        } catch ClubServiceError.badResponse(let code, _) where code == HZHub.malFormee {
            usernameError = String(localized: "Pseudo invalide — lettres minuscules, chiffres, underscore, 3 à 20 caractères.")
        } catch {
            usernameError = PanneReseau.phrase(pour: error)
        }
        isSavingUsername = false
    }
}
