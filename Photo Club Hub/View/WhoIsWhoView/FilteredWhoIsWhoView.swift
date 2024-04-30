//
//  FilteredWhoIsWhoView.swift
//  Photo Club Hub
//
//  Created by Peter van den Hamer on 30/12/2021.
//

import SwiftUI // for View
import WebKit // for WKWebView

// Implements list of photographer cards including
//      * defining fetchRequest to get list of photographers sorted on last name
//      * filtering the photographer list based on search bar string
//      * per photographer card, it displays
//          - an icon (with a special icon if the photographer is deceased)
//          - photographer's name (last name first)
//          - optionally a link icon that leads to the phototographer's own website
//          - some textual information
//          - a horizontally scrolling list of thumbnails representing portfolios
// Preview unfortunately doesn't work.

struct FilteredWhoIsWhoView: View {

    @Environment(\.managedObjectContext) private var viewContext // may not be correct
    @FetchRequest var fetchedPhotographers: FetchedResults<Photographer>

    private let isDeletePhotographersPermitted = true // enable/disable .delete() functionality for this screen
    let searchText: Binding<String>
    let wkWebView: WKWebView

    // regenerate Section using current FetchRequest with current filters and sorting
    init(predicate: NSPredicate, searchText: Binding<String>, wkWebView: WKWebView) {
        _fetchedPhotographers = FetchRequest<Photographer>(sortDescriptors: [ // replaces previous fetchedPhotographers
                                                        SortDescriptor(\.familyName_, order: .forward),
                                                        SortDescriptor(\.givenName_, order: .forward)],
                                                   predicate: predicate,
                                                   animation: .default)
        self.searchText = searchText
        self.wkWebView = wkWebView
    }

    var body: some View {
        ForEach(filteredPhotographers, id: \.id) { filteredPhotographer in // each photographer's "card"
            VStack(alignment: .leading) { // there are horizontal layers within each photographer's "card"
                HStack(alignment: .top) { // first row within each photographer's "card" with textual info

                    PhotographerIconView(isDeceased: filteredPhotographer.isDeceased)
                        .foregroundStyle(.photographerColor, .gray, .red) // red tertiary color should not show up
                        .font(.title3)
                        .frame(width: 35)
                        .padding(.top, 3)

                    WhoIsWhoTextInfo(photographer: filteredPhotographer)

                    Spacer() // push WhoIsTextInfo to the left

                    if let url: URL = filteredPhotographer.website {
                        Link(destination: url, label: {
                            Image(systemName: "link")
                                .foregroundColor(.linkColor)
                        })
                        .buttonStyle(.plain) // to avoid entire List element to be clickable
                    }

                } // HStack

                WhoIsWhoThumbnails(photographer: filteredPhotographer, wkWebView: wkWebView)

                Divider()
            } // VStack
            .accentColor(.photographerColor)
            .foregroundColor(chooseColor(accentColor: .accentColor,
                                         isDeceased: filteredPhotographer.isDeceased))
        } // ForEach filteredPhotographer
        .onDelete(perform: { indexSet in
            deletePhotographers(indexSet: indexSet) // can be disabled using isDeletedPhotographerEnabled flag
        })

        /* header: { // Table has only one section and it gets a header
         ItemFilterStatsView(filteredCount: filteredPhotographers.count,
         unfilteredCount: fetchRequest.count,
         elementType: ItemFilterStatsEnum.photographer)
         .textCase(nil) // https://sarunw.com/posts/swiftui-list-section-header-textcase/
         } // header
         */
    } // body

    private var filteredPhotographers: [Photographer] {
        if searchText.wrappedValue.isEmpty {
            return fetchedPhotographers.filter { _ in
                true
            }
        } else {
            return fetchedPhotographers.filter { photographer in
                photographer.fullNameFirstLast.localizedCaseInsensitiveContains(searchText.wrappedValue) }
        }
    }

    private func chooseColor(accentColor: Color, isDeceased: Bool) -> Color {
        isDeceased ? .deceasedColor : .photographerColor
    }

    private func deletePhotographers(indexSet: IndexSet) {
        guard isDeletePhotographersPermitted else { return } // exit if feature is disabled

        let fullName: String = indexSet.map { filteredPhotographers[$0] }.first?.fullNameFirstLast ?? "noName"
        indexSet.map { filteredPhotographers[$0] }.forEach( viewContext.delete )

        do {
            if viewContext.hasChanges {
                try viewContext.save() // persist deletion of photographer
                print("Deleted photographer \(fullName) and any associated memberships")
            }
        } catch {
            let nsError = error as NSError
            ifDebugFatalError("Unresolved error deleting photographer \(fullName): \(nsError), \(nsError.userInfo)",
                              file: #fileID, line: #line) // expect deprecation of #fileID in Swift 6.0
            // in release mode, the failed deletion is only logged. App doesn't stop.
        }
    }

    private struct PhotographerIconView: View {
        let isDeceased: Bool

        var body: some View {
            if isDeceased {
                Image("deceased.photographer")
            } else {
                Image(systemName: "person.text.rectangle")
            }
        }
    }
}

struct FilteredWhoIsWhoViewWrapper: View {
    var body: some View {
        let predicate = NSPredicate(format: "familyName_ = %@ || familyName_ = %@ || familyName_ = %@",
                                    argumentArray: ["Eau1", "Eau2", "Eau10"])
        @State var searchText: String = "Eau1"
        let wkWebView = WKWebView()

        return FilteredWhoIsWhoView(predicate: predicate, searchText: $searchText, wkWebView: wkWebView)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

#Preview {
    NavigationStack {
        List {
            FilteredWhoIsWhoViewWrapper()
        }
    }
    .searchable(text: .constant("Name"))
}
