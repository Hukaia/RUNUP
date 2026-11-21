import SwiftUI

/// LE CLASSEMENT : la semaine ou le général (XP), des lignes de liste, la mienne repérée.
///
/// Deux affichages pour la semaine : les kilomètres, ou le pourcentage de l'objectif de chacune.
/// Un membre sans objectif connu garde ses kilomètres dans le second, plutôt qu'un « 0 % » faux.
struct ClubBoardSection: View {
    let board: ClubBoard
    let isLoading: Bool
    @Binding var reportTarget: ReportTarget?
    @Binding var pendingBlock: (userId: String, name: String)?

    @Environment(AppState.self) private var appState

    @State private var boardMode: BoardMode = .week
    @State private var weeklyDisplayMode: WeeklyDisplayMode = .km

    private enum BoardMode { case week, general }
    private enum WeeklyDisplayMode: CaseIterable, Identifiable, Equatable {
        case km, pctObjectif
        var id: Self { self }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: HZEspace.sousUnTitre) {
            HStack(spacing: HZEspace.entrePilules) {
                HZFiltre(libelle: String(localized: "Cette semaine"), actif: boardMode == .week, fond: .clair) {
                    withAnimation(.easeInOut(duration: HZHub.dureeDeLOnglet)) { boardMode = .week }
                }
                HZFiltre(libelle: String(localized: "Général (XP)"), actif: boardMode == .general, fond: .clair) {
                    withAnimation(.easeInOut(duration: HZHub.dureeDeLOnglet)) { boardMode = .general }
                }
            }
            if boardMode == .week {
                weekBoardContent
            } else {
                generalBoardContent
            }
        }
    }

    private var rankedWeekly: [WeeklyRow] {
        let rows = board.weekly ?? []
        guard weeklyDisplayMode == .pctObjectif else { return rows }
        return rows.sorted { a, b in
            switch (a.pctOfTarget, b.pctOfTarget) {
            case let (pa?, pb?): return pa > pb
            case (nil, nil): return a.weekKm > b.weekKm
            case (nil, _): return false
            case (_, nil): return true
            }
        }
    }

    @ViewBuilder private var weekBoardContent: some View {
        if (board.weekly ?? []).isEmpty && !isLoading {
            HZPhrase(texte: String(localized: "Personne n'a encore couru cette semaine. Lance-toi !"))
        } else {
            HZTitreDeSection(titre: String(localized: "Classement de la semaine"))
            HStack(spacing: HZEspace.entrePilules) {
                HZFiltre(libelle: String(localized: "Km"), actif: weeklyDisplayMode == .km, fond: .contour,
                         graisse: .semi, margeVerticale: HZFiltre.margeDePeriode) {
                    Haptics.selection()
                    weeklyDisplayMode = .km
                }
                HZFiltre(libelle: String(localized: "% objectif"), actif: weeklyDisplayMode == .pctObjectif,
                         fond: .contour, graisse: .semi, margeVerticale: HZFiltre.margeDePeriode) {
                    Haptics.selection()
                    weeklyDisplayMode = .pctObjectif
                }
            }
            let rows = rankedWeekly
            LazyVStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, entry in
                    weekRow(entry, displayRank: index + 1, dernier: index == rows.count - 1)
                }
            }
        }
    }

    private func rang(_ valeur: Int, estMoi: Bool) -> some View {
        Text("\(valeur)")
            .hzTexte(.c15, .gras, tabulaire: true)
            .foregroundStyle(estMoi ? HZCouleur.encre : HZCouleur.secondaireSurClair)
            .frame(width: HZHub.largeurDuRang)
    }

    private func photo(nom: String, nomDeFamille: String?, url: String?, base64: String?)
        -> HZPhotoDePersonne {
        HZPhotoDePersonne(urlString: url, base64DataURI: base64,
                          initiales: HZInitiales.de(nom, nomDeFamille), cote: HZHub.avatarCompact)
    }

    private func weekRow(_ entry: WeeklyRow, displayRank: Int, dernier: Bool) -> some View {
        Button(action: { if !entry.isMe { appState.ouvrirLeProfil(entry.id) } }) {
            HZLigneDeListe(titre: entry.isMe ? String(localized: "\(entry.nomComplet) · toi") : entry.nomComplet,
                           graisse: entry.isMe ? .gras : .semi, filet: !dernier) {
                HStack(spacing: HZEspace.entreCommandes) {
                    rang(displayRank, estMoi: entry.isMe)
                    photo(nom: entry.name, nomDeFamille: entry.lastName,
                          url: entry.avatarUrl, base64: entry.avatarBase64)
                }
            } queue: {
                if weeklyDisplayMode == .pctObjectif, let pct = entry.pctOfTarget {
                    HStack(spacing: HZEspace.entrePilules) {
                        HZCouronne(fraction: Double(pct) / HZHub.centPourcent,
                                   couleur: pct >= Int(HZHub.centPourcent) ? HZCouleur.accent : HZCouleur.encre)
                        Text(verbatim: "\(pct) %").hzTexte(.c16, .gras, tabulaire: true)
                            .foregroundStyle(HZCouleur.encre)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(pct) pour cent de l'objectif de la semaine")
                } else {
                    Text(verbatim: String(format: "%.1f km", locale: Locale.current, entry.weekKm))
                        .hzTexte(.c16, .gras, tabulaire: true)
                        .foregroundStyle(HZCouleur.encre)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(entry.isMe)
    }

    private var generalBoardContent: some View {
        let rows = board.leaderboard
        return LazyVStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, entry in
                generalRow(entry, dernier: index == rows.count - 1)
            }
        }
    }

    private func generalRow(_ entry: LeaderboardRow, dernier: Bool) -> some View {
        Button(action: { if !entry.isMe { appState.ouvrirLeProfil(entry.id) } }) {
            HZLigneDeListe(titre: entry.isMe ? String(localized: "\(entry.nomComplet) · toi") : entry.nomComplet,
                           graisse: entry.isMe ? .gras : .semi, filet: !dernier) {
                HStack(spacing: HZEspace.entreCommandes) {
                    rang(entry.rank, estMoi: entry.isMe)
                    photo(nom: entry.name, nomDeFamille: entry.lastName,
                          url: entry.avatarUrl, base64: entry.avatarBase64)
                }
            } queue: {
                Text(verbatim: "\(entry.xp)").hzTexte(.c16, .gras, tabulaire: true)
                    .foregroundStyle(HZCouleur.encre)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(entry.isMe)
        .contextMenu {
            if !entry.isMe {
                Button("Signaler \(entry.name)") {
                    reportTarget = ReportTarget(targetType: "user", targetId: entry.id, displayName: entry.nomComplet)
                }
                Button("Bloquer \(entry.name)", role: .destructive) {
                    pendingBlock = (entry.id, entry.name)
                }
            }
        }
    }
}

/// LES MEMBRES : des lignes de liste — l'avatar, le nom, ce que la personne a couru cette semaine.
/// Un tap ouvre son profil. Les rangs et les XP restent dans l'onglet Classement.
struct ClubMembresSection: View {
    let board: ClubBoard
    @Environment(AppState.self) private var appState

    var body: some View {
        if !board.leaderboard.isEmpty {
            VStack(alignment: .leading, spacing: HZEspace.sousUnTitre) {
                HZTitreDeSection(titre: String(localized: "Membres"))
                LazyVStack(spacing: 0) {
                    ForEach(Array(board.leaderboard.enumerated()), id: \.element.id) { index, membre in
                        ligne(membre, dernier: index == board.leaderboard.count - 1)
                    }
                }
            }
        }
    }

    private func kilometres(de membre: LeaderboardRow) -> Double? {
        board.weekly?.first(where: { $0.id == membre.id }).map(\.weekKm)
    }

    private func ligne(_ membre: LeaderboardRow, dernier: Bool) -> some View {
        Button(action: { if !membre.isMe { appState.ouvrirLeProfil(membre.id) } }) {
            HZLigneDeListe(
                titre: membre.isMe ? String(localized: "\(membre.nomComplet) · toi") : membre.nomComplet,
                sousTitre: sousTitre(membre), filet: !dernier) {
                HZPhotoDePersonne(urlString: membre.avatarUrl, base64DataURI: membre.avatarBase64,
                                  initiales: HZInitiales.de(membre.name, membre.lastName))
            } queue: {
                if !membre.isMe { HZChevron() }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(membre.isMe)
    }

    /// Le statut de la personne s'il y en a un, sinon sa semaine : jamais une ligne vide pour dire
    /// « rien ».
    private func sousTitre(_ membre: LeaderboardRow) -> String? {
        if let bio = membre.bio, !bio.isEmpty { return bio }
        guard let km = kilometres(de: membre), km > 0 else { return nil }
        return String(localized: "\(Distances.valeur(km)) km cette semaine")
    }
}
