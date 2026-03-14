/*
 LARP Settings — GUI for profile overrides
 Accès: 10 taps sur l'onglet Settings
 */
import Foundation
import UIKit
import Display
import SwiftSignalKit
import Postbox
import TelegramCore
import TelegramPresentationData
import ItemListUI
import AccountContext
import PhoneNumberFormat
import OverlayStatusController
import TelegramUIPreferences

private enum LarpSection: Int32 {
    case user
    case spoof
    case actions
}

private enum LarpEntry: ItemListNodeEntry {
    case usernameHeader(PresentationTheme)
    case username(PresentationTheme, String)
    case phoneHeader(PresentationTheme)
    case phone(PresentationTheme, String)
    case aliasesHeader(PresentationTheme)
    case aliases(PresentationTheme, String)
    case spoofHeader(PresentationTheme)
    case spoofInput(PresentationTheme, String)
    case spoofStatus(PresentationTheme, String)
    case spoofSet(PresentationTheme)
    case spoofClear(PresentationTheme)
    case save(PresentationTheme)
    case reset(PresentationTheme)
    
    var section: ItemListSectionId {
        switch self {
        case .usernameHeader, .username, .phoneHeader, .phone, .aliasesHeader, .aliases:
            return LarpSection.user.rawValue
        case .spoofHeader, .spoofInput, .spoofStatus, .spoofSet, .spoofClear:
            return LarpSection.spoof.rawValue
        case .save, .reset:
            return LarpSection.actions.rawValue
        }
    }
    
    var stableId: Int32 {
        switch self {
        case .usernameHeader: return 0
        case .username: return 1
        case .phoneHeader: return 2
        case .phone: return 3
        case .aliasesHeader: return 4
        case .aliases: return 5
        case .spoofHeader: return 6
        case .spoofInput: return 7
        case .spoofStatus: return 8
        case .spoofSet: return 9
        case .spoofClear: return 10
        case .save: return 11
        case .reset: return 12
        }
    }
    
    static func < (lhs: LarpEntry, rhs: LarpEntry) -> Bool { lhs.stableId < rhs.stableId }
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let args = arguments as! LarpSettingsControllerArguments
        switch self {
        case let .usernameHeader(theme):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "Pseudo (username)", sectionId: self.section)
        case let .username(theme, value):
            return ItemListSingleLineInputItem(presentationData: presentationData, systemStyle: .glass, title: NSAttributedString(string: "@", textColor: theme.list.itemPrimaryTextColor), text: value, placeholder: "username", type: .username, clearType: .always, tag: nil, sectionId: self.section, textUpdated: { args.updateUsername($0) }, action: {})
        case let .phoneHeader(theme):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "Numéro de téléphone", sectionId: self.section)
        case let .phone(theme, value):
            return ItemListSingleLineInputItem(presentationData: presentationData, systemStyle: .glass, title: NSAttributedString(), text: value, placeholder: "+33 6 12 34 56 78", type: .phone, clearType: .always, tag: nil, sectionId: self.section, textUpdated: { args.updatePhone($0) }, action: {})
        case let .aliasesHeader(theme):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "Aliases (@alias:price)", sectionId: self.section)
        case let .aliases(theme, value):
            return ItemListSingleLineInputItem(presentationData: presentationData, systemStyle: .glass, title: NSAttributedString(), text: value, placeholder: "@alias:440 @other:8783", type: .regular(capitalization: false, autocorrection: false), clearType: .always, tag: nil, sectionId: self.section, textUpdated: { args.updateAliases($0) }, action: {})
        case let .spoofHeader(theme):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "Spoof (se faire passer pour)", sectionId: self.section)
        case let .spoofInput(theme, value):
            return ItemListSingleLineInputItem(presentationData: presentationData, systemStyle: .glass, title: NSAttributedString(), text: value, placeholder: "@username", type: .username, clearType: .always, tag: nil, sectionId: self.section, textUpdated: { args.updateSpoofInput($0) }, action: {})
        case let .spoofStatus(theme, value):
            return ItemListTextItem(presentationData: presentationData, text: .plain(value), sectionId: self.section)
        case .spoofSet(theme):
            return ItemListActionItem(presentationData: presentationData, title: "Définir spoof target", kind: .generic, alignment: .natural, sectionId: self.section, style: .blocks, action: { args.resolveAndSetSpoof() })
        case .spoofClear(theme):
            return ItemListActionItem(presentationData: presentationData, title: "Effacer spoof", kind: .destructive, alignment: .natural, sectionId: self.section, style: .blocks, action: { args.clearSpoof() })
        case .save(theme):
            return ItemListActionItem(presentationData: presentationData, title: "Enregistrer", kind: .generic, alignment: .natural, sectionId: self.section, style: .blocks, action: { args.save() })
        case .reset(theme):
            return ItemListActionItem(presentationData: presentationData, title: "Réinitialiser tout", kind: .destructive, alignment: .natural, sectionId: self.section, style: .blocks, action: { args.reset() })
        }
    }
}

private struct LarpSettingsControllerArguments {
    let context: AccountContext
    let updateUsername: (String) -> Void
    let updatePhone: (String) -> Void
    let updateAliases: (String) -> Void
    let updateSpoofInput: (String) -> Void
    let resolveAndSetSpoof: () -> Void
    let clearSpoof: () -> Void
    let save: () -> Void
    let reset: () -> Void
}

private struct LarpSettingsState: Equatable {
    var username: String = ""
    var phone: String = ""
    var aliases: String = ""
    var spoofInput: String = ""
    var spoofStatus: String = ""
}

private func larpEntries(state: LarpSettingsState, presentationData: PresentationData) -> [LarpEntry] {
    let theme = presentationData.theme
    var entries: [LarpEntry] = []
    
    entries.append(.usernameHeader(theme))
    entries.append(.username(theme, state.username))
    entries.append(.phoneHeader(theme))
    entries.append(.phone(theme, state.phone))
    entries.append(.aliasesHeader(theme))
    entries.append(.aliases(theme, state.aliases))
    entries.append(.spoofHeader(theme))
    entries.append(.spoofInput(theme, state.spoofInput))
    if !state.spoofStatus.isEmpty {
        entries.append(.spoofStatus(theme, state.spoofStatus))
    }
    entries.append(.spoofSet(theme))
    entries.append(.spoofClear(theme))
    entries.append(.save(theme))
    entries.append(.reset(theme))
    
    return entries
}

public func larpSettingsController(context: AccountContext) -> ViewController {
    let initialState = LarpSettingsState(
        username: LarpConfig.shared.customUsername,
        phone: LarpConfig.shared.customPhone,
        aliases: LarpConfig.shared.aliasesRaw,
        spoofInput: "",
        spoofStatus: LarpConfig.shared.hasSpoofTarget ? "Spoof actif" : ""
    )
    
    let statePromise = ValuePromise(initialState, ignoreRepeated: true)
    let stateValue = Atomic(value: initialState)
    
    var pushControllerImpl: ((ViewController) -> Void)?
    var presentControllerImpl: ((ViewController, ViewControllerPresentationArguments?) -> Void)?
    
    let arguments = LarpSettingsControllerArguments(
        context: context,
        updateUsername: { value in
            stateValue.with { state in
                var s = state
                s.username = value
                stateValue.swap(s)
                statePromise.set(s)
            }
        },
        updatePhone: { value in
            stateValue.with { state in
                var s = state
                s.phone = value
                stateValue.swap(s)
                statePromise.set(s)
            }
        },
        updateAliases: { value in
            stateValue.with { state in
                var s = state
                s.aliases = value
                stateValue.swap(s)
                statePromise.set(s)
            }
        },
        updateSpoofInput: { value in
            stateValue.with { state in
                var s = state
                s.spoofInput = value
                stateValue.swap(s)
                statePromise.set(s)
            }
        },
        resolveAndSetSpoof: {
            let input = stateValue.with { $0.spoofInput }.trimmingCharacters(in: .whitespaces)
            var username = input
            if username.hasPrefix("@") { username = String(username.dropFirst()) }
            if username.isEmpty { return }
            
            let _ = (context.engine.peers.resolvePeerByName(name: username, referrer: nil)
                |> deliverOnMainQueue).start(next: { result in
                    switch result {
                    case .progress:
                        break
                    case let .result(peer):
                        if case let .user(user) = peer {
                            LarpConfig.shared.spoofTargetPeerId = user.id
                            stateValue.with { state in
                                var s = state
                                s.spoofStatus = "Spoof: \(user.firstName ?? "") \(user.lastName ?? "")"
                                s.spoofInput = ""
                                stateValue.swap(s)
                                statePromise.set(s)
                            }
                        }
                    }
                })
        },
        clearSpoof: {
            LarpConfig.shared.spoofTargetPeerId = nil
            stateValue.with { state in
                var s = state
                s.spoofStatus = ""
                stateValue.swap(s)
                statePromise.set(s)
            }
        },
        save: {
            let s = stateValue.with { $0 }
            LarpConfig.shared.customUsername = s.username
            LarpConfig.shared.customPhone = s.phone
            LarpConfig.shared.aliasesRaw = s.aliases
            context.sharedContext.presentGlobalOverlayController(OverlayStatusController(theme: context.sharedContext.currentPresentationData.with { $0 }.theme, type: .success), nil)
        },
        reset: {
            LarpConfig.shared.reset()
            let s = LarpSettingsState(username: "", phone: "", aliases: "", spoofInput: stateValue.with { $0.spoofInput }, spoofStatus: "")
            stateValue.swap(s)
            statePromise.set(s)
        }
    )
    
    let signal = combineLatest(context.sharedContext.presentationData, statePromise.get())
        |> map { presentationData, state -> (ItemListControllerState, (ItemListNodeState, Any)) in
            let controllerState = ItemListControllerState(
                presentationData: ItemListPresentationData(presentationData),
                title: .text("LARP"),
                leftNavigationButton: nil,
                rightNavigationButton: nil,
                backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
            )
            let listState = ItemListNodeState(
                presentationData: ItemListPresentationData(presentationData),
                entries: larpEntries(state: state, presentationData: presentationData),
                style: .blocks
            )
            return (controllerState, (listState, arguments))
        }
    
    let controller = ItemListController(context: context, state: signal)
    pushControllerImpl = { [weak controller] c in
        (controller?.navigationController as? NavigationController)?.pushViewController(c)
    }
    presentControllerImpl = { [weak controller] c, a in
        controller?.present(c, in: .window(.root), with: a)
    }
    return controller
}
