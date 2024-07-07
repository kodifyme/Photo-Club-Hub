//
//  OrganizationListView.swift
//  Photo Club Hub
//
//  Created by Peter van den Hamer on 07/01/2022.
//

import SwiftUI
import CoreData // for implementing .refreshable

struct OrganizationListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject var model = PreferencesViewModel()
    @State var locationManager = LocationManager()
    @State private var searchText: String = "" // bindable string with content of Search bar

    @FetchRequest(
        sortDescriptors: [], // organizations is only used for counting, so sorting doesn't matter
        animation: .default)
    private var organizations: FetchedResults<Organization>

    private static let predicateAll = NSPredicate(format: "TRUEPREDICATE")
    private var predicate: NSPredicate = Self.predicateAll
    private var navigationTitle = String(localized: "Clubs and Museums",
                                         comment: "Title of page with maps for Clubs and Museums")

    init(predicate: NSPredicate? = nil,
         navigationTitle: String? = nil) {
        if predicate != nil {
            self.predicate = predicate!
        } else {
            self.predicate = model.preferences.photoClubPredicate // dummy data for Preview
        }
        if let navigationTitle {
            self.navigationTitle = navigationTitle
        }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {

            LazyVStack {
                FilteredOrganizationView(predicate: model.preferences.photoClubPredicate, searchText: $searchText)
            }
            .scrollTargetLayout()

            if organizations.isEmpty {
                NoClubsText()
            }

            VStack(alignment: .leading) {
                Text("PhotoClubs_Caption_1",
                     comment: "Shown in gray at the bottom of the Clubs and Museums page (1/2).")
                Divider()
                Text("PhotoClubs_Caption_2",
                     comment: "Shown in gray at the bottom of the Clubs and Museums page (2/2).")
            }
            .foregroundColor(Color.secondary)
        } // ScrollView

        .scrollTargetBehavior(.viewAligned) // iOS 17 smart scrolling
        .refreshable { // for pull-to-refresh
            PhotoClubHubApp.loadClubsAndMembers() // carefull: runs asynchronously
        }
        .task {
            try? await locationManager.requestUserAuthorization()
            try? await locationManager.startCurrentLocationUpdates()
            // remember that nothing will run here until the for try await loop finishes
        }
        .navigationTitle(navigationTitle)
        .searchable(text: $searchText, placement: .automatic,
                    // .automatic
                    // .toolbar The search field is placed in the toolbar. To right of person.text.rect.cust
                    // .sidebar The search field is placed in the sidebar of a navigation view. not on iPad
                    // .navigationBarDrawer The search field is placed in an drawer of the navigation bar. OK
                    prompt: Text("Search names and towns", comment:
                                    """
                                    Field at top of Clubs and Museums page that allows the user to \
                                    filter the members based on a fragment of the organization name.
                                    """
                                ))
        .disableAutocorrection(true)
    }

    private let toolbarItemPlacement: ToolbarItemPlacement = UIDevice.isIPad ?
        .destructiveAction : // iPad: Search field in toolbar
        .navigationBarTrailing // iPhone: Search field in drawer
}

struct NoClubsText: View {
    var body: some View {
        Text("""
             No photo clubs seem to be currently loaded.
             Try dragging down the Clubs and Museums screen to reload the default clubs.
             """, comment: "Hint to the user if the database returns zero PhotoClubs.")
    }
}

struct PhotoClubListView_Previews: PreviewProvider {
    static let predicate = NSPredicate(format: "fullName_ = %@ || fullName_ = %@ || fullName_ = %@",
                                       argumentArray: ["PhotoClub2", "PhotoClub1", "PhotoClub3"])

    static var previews: some View {
        NavigationStack {
            OrganizationListView(predicate: predicate, navigationTitle: String("PhotoClubView"))
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
}
