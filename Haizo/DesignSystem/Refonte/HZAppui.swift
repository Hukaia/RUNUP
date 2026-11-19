import SwiftUI

/// L'APPUI SUR UN BOUTON QUI N'A PAS DE FOND À ENFONCER : il rétrécit à peine et pâlit un peu.
///
/// Il remplace `PressableStyle`, de l'ancien système. Les trois nombres sont ceux qu'il portait.
struct HZStyleDAppui: ButtonStyle {
    static let echelle: CGFloat = 0.96
    static let opacite: Double = 0.88
    static let duree: Double = 0.12

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? HZStyleDAppui.echelle : HZLancement.echellePleine)
            .opacity(configuration.isPressed ? HZStyleDAppui.opacite : HZHub.opaciteNormale)
            .animation(.easeOut(duration: HZStyleDAppui.duree), value: configuration.isPressed)
    }
}
