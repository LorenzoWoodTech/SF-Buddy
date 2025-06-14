//
//  IconProvider.swift
//  SF Buddy
//
//  Central, **single-source-of-truth** for all icons (SF Symbols + custom assets).
//

import SwiftUI

// MARK: – Public API
enum IconProvider {

    // Return a ready-to-use SwiftUI Image
    static func icon(_ icon: AppIcon,
                     style: IconStyle = .regular,
                     context: IconContext = .default) -> Image
    {
        let definition = registry[icon] ?? fallback
        let symbolName  = definition.name(for: context).styled(as: style,
                                                               isCustomAsset: definition.isCustomAsset)

        return definition.isCustomAsset
        ? Image(symbolName)                   // asset-catalogue image
        : Image(systemName: symbolName)       // SF Symbol
    }

    // Convenience to fetch just the raw symbol / asset name
    static func name(for icon: AppIcon,
                     style: IconStyle = .regular,
                     context: IconContext = .default) -> String
    {
        let definition = registry[icon] ?? fallback
        return definition.name(for: context).styled(as: style,
                                                    isCustomAsset: definition.isCustomAsset)
    }

    // Is the given icon backed by an asset-catalogue image?
    static func isCustomAsset(_ icon: AppIcon) -> Bool {
        registry[icon]?.isCustomAsset ?? false
    }
}

// MARK: – Type-safe identifiers
enum AppIcon: String, CaseIterable, Identifiable {
    // NAV
    case home, calendar, tasks, search, settings, more, wiki
    // CORE ACTIONS
    case add, delete, edit, save, cancel, export, import_, sort, filter
    // COMMUNICATION
    case dialogs, comments, problemReports, activityLog, chat, email, phone, message
    // BUSINESS & CONTENT
    case gigs, shows, songs, artist, organization, people, person, team, locations, venue
    // EQUIPMENT
    case microphone, guitar, keyboard, drums, monitor, amplifier, directInput, riser, stage, mixer, lighting, camera, video
    // BUSINESS OPS
    case inventory, products, packages, laborPackage, prepPackage, rentalPackage,
         quotes, invoices, purchases, credits, expenses, advances
    // DATABASE
    case database, rigDesigns, templates, documents, files, folders
    // STATUS
    case success, warning, error, info, loading, complete, pending, draft
    // MEDIA
    case photo, images, attachments, notes, tags, bookmarks

    var id: String { rawValue }
}

enum IconStyle { case regular, filled, circle, circleFilled }          // keep minimal – extend later
enum IconContext { case `default`, sidebar, tabBar, list, singular, plural }
typealias Variants = [IconContext : String]

// MARK: – Internal model
private struct Definition {
    let base: String
    let isCustomAsset: Bool
    let variants: Variants

    init(base: String,
         isCustomAsset: Bool = false,
         variants: Variants = [:]) {
        self.base = base
        self.isCustomAsset = isCustomAsset
        self.variants = variants
    }

    func name(for context: IconContext) -> String {
        variants[context] ?? base
    }
}

// MARK: – Styling helper
private extension String {
    func styled(as style: IconStyle, isCustomAsset: Bool) -> String {
        guard !isCustomAsset else { return self }      // no suffixes on asset names
        switch style {
        case .regular:        return self
        case .filled:         return hasSuffix(".fill")      ? self : self + ".fill"
        case .circle:         return hasSuffix(".circle")    ? self : self + ".circle"
        case .circleFilled:
            if hasSuffix(".circle.fill") { return self }
            if hasSuffix(".circle")      { return self + ".fill" }
            return self + ".circle.fill"
        }
    }
}

// MARK: – Registry
private let registry: [AppIcon : Definition] = [
    // NAV
    .home        : .init(base: "house",       variants: [.sidebar : "house.fill"]),
    .calendar    : .init(base: "calendar"),
    .tasks       : .init(base: "checklist"),
    .search      : .init(base: "magnifyingglass"),
    .settings    : .init(base: "gear"),
    .more        : .init(base: "ellipsis"),
    .wiki        : .init(base: "book"),
    
    // COMMUNICATION
    .dialogs        : .init(base: "bubble.left.and.bubble.right"),
    .comments       : .init(base: "text.bubble"),
    .problemReports : .init(base: "exclamationmark.triangle"),
    .activityLog    : .init(base: "list.bullet.clipboard"),
    .chat           : .init(base: "message"),
    .email          : .init(base: "envelope"),
    .phone          : .init(base: "phone"),
    .message        : .init(base: "message"),
    
    // BUSINESS & CONTENT
    .gigs        : .init(base: "briefcase",   variants: [.sidebar : "briefcase.fill"]),
    .shows       : .init(base: "theatermasks"),
    .songs       : .init(base: "music.note"),
    .artist      : .init(base: "music.microphone"),
    .organization: .init(base: "building.2", variants: [.singular: "building", .plural: "building.2"]),
    .people      : .init(base: "person.2"),
    .person      : .init(base: "person"),
    .team        : .init(base: "person.2.crop.square.stack"),
    .locations   : .init(base: "mappin.and.ellipse"),
    .venue       : .init(base: "building.columns"),
    
    // EQUIPMENT
    .microphone  : .init(base: "mic"),
    .guitar      : .init(base: "guitars"),
    .keyboard    : .init(base: "pianokeys"),
    .drums       : .init(base: "circle.grid.2x2"),
    .monitor     : .init(base: "speaker.wave.2"),
    .amplifier   : .init(base: "speaker.3"),
    .directInput : .init(base: "square.and.line.vertical.and.square"),
    .riser       : .init(base: "square.stack.3d.up"),
    .stage       : .init(base: "square.stack.3d.up"),
    .mixer       : .init(base: "slider.horizontal.3"),
    .lighting    : .init(base: "lightbulb"),
    .camera      : .init(base: "camera"),
    .video       : .init(base: "video"),
    
    // BUSINESS OPS
    .inventory      : .init(base: "shippingbox"),
    .products       : .init(base: "cube.box"),
    .packages       : .init(base: "shippingbox"),
    .laborPackage   : .init(base: "calendar.badge.person.crop"),
    .prepPackage    : .init(base: "desktopcomputer"),
    .rentalPackage  : .init(base: "shippingbox"),
    .quotes         : .init(base: "doc.text"),
    .invoices       : .init(base: "doc.text.image"),
    .purchases      : .init(base: "creditcard"),
    .credits        : .init(base: "giftcard"),
    .expenses       : .init(base: "creditcard"),
    .advances       : .init(base: "banknote"),
    
    // DATABASE
    .database       : .init(base: "cylinder.split.1x2"),
    .rigDesigns     : .init(base: "rectangle.3.group"),
    .templates      : .init(base: "doc.on.doc"),
    .documents      : .init(base: "doc"),
    .files          : .init(base: "folder"),
    .folders        : .init(base: "folder"),
    
    // STATUS
    .success     : .init(base: "checkmark.circle"),
    .warning     : .init(base: "exclamationmark.triangle"),
    .error       : .init(base: "xmark.circle"),
    .info        : .init(base: "info.circle"),
    .loading     : .init(base: "arrow.triangle.2.circlepath"),
    .complete    : .init(base: "checkmark.circle"),
    .pending     : .init(base: "clock"),
    .draft       : .init(base: "doc.text"),
    
    // MEDIA
    .photo       : .init(base: "photo"),
    .images      : .init(base: "photo.on.rectangle"),
    .attachments : .init(base: "paperclip"),
    .notes       : .init(base: "note.text"),
    .tags        : .init(base: "tag"),
    .bookmarks   : .init(base: "bookmark"),
    
    // CORE ACTIONS
    .add         : .init(base: "plus"),
    .delete      : .init(base: "trash"),
    .edit        : .init(base: "pencil"),
    .save        : .init(base: "checkmark"),
    .cancel      : .init(base: "xmark"),
    .export      : .init(base: "square.and.arrow.up"),
    .import_     : .init(base: "square.and.arrow.down"),
    .sort        : .init(base: "arrow.up.arrow.down"),
    .filter      : .init(base: "line.3.horizontal.decrease"),
]

// fallback for unknown keys
private let fallback = Definition(base: "questionmark.circle", isCustomAsset: false, variants: [:])

// MARK: – SwiftUI sugar
extension Image {
    init(icon: AppIcon, style: IconStyle = .regular, context: IconContext = .default) {
        self = IconProvider.icon(icon, style: style, context: context)
    }
}
