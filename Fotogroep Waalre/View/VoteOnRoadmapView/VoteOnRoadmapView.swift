//
//  RoadmapView.swift
//  Fotogroep Waalre
//
//  Created by Peter van den Hamer on 05/03/2023.
//

import SwiftUI
import Roadmap

struct VoteOnRoadmapView: View {
    var useOnlineList: Bool // using online allows updates, but gives empty page if device is offline

    private let title = String(localized: "Roadmap Items", comment: "Title of Roadmap screen")
    private let headerText = String(localized:
                              """
                              You can vote here on which roadmap items you would like to see. \
                              Please read the entire list before voting bacause you cannot undo a vote. \
                              Don't vote for more than half the items: the data helps us \
                              prioritize (this isn't about \"liking\" individual items).
                              """,
                              comment: "Instructions at top of Roadmap screen")

    @State var showingConfirmVote = false // true displays alert to prevent accidental votin
    static var configuration: RoadmapConfiguration? // nil gets overwritten during init() so we can have access to self

    init(useOnlineList: Bool) {
        self.useOnlineList = useOnlineList

        VoteOnRoadmapView.configuration = RoadmapConfiguration(
            roadmapJSONURL: useOnlineList ? // JSON file with list of features
                            URL(string: "https://simplejsoncms.com/api/vnlg2fq62s")! : // password protected
                            Bundle.main.url(forResource: "Roadmap", withExtension: "json")!,
            voter: CustomVoter(namespace: "com.vdhamer.photo_clubs_vote_on_features_dummy2"), // TODO remove suffix
            style: RoadmapStyle(icon: Image(systemName: "circle.square.fill"),
                                titleFont: RoadmapTemplate.standard.style.titleFont.italic(),
                                numberFont: RoadmapTemplate.standard.style.numberFont,
                                statusFont: RoadmapTemplate.standard.style.statusFont,
                                statusTintColor: lookupStatusTintColor, // function name
                                cornerRadius: 10,
                                cellColor: RoadmapTemplate.standard.style.cellColor, // cell background
                                selectedColor: RoadmapTemplate.standard.style.selectedForegroundColor,
                                tint: RoadmapTemplate.standard.style.tintColor), // voting icon
            shuffledOrder: true,
            allowVotes: true,
            allowSearching: true
        )
    }

    var body: some View {
        NavigationStack {
            RoadmapView(configuration: VoteOnRoadmapView.configuration!, header: {
                Text(headerText)
                    .italic()
                    .font(.callout)
                    .foregroundColor(.blue)
            })
                .navigationTitle(title)
        }
       .alert(String(localized: "Vote for this?", comment: "Alert dialog title. Shown if user tries to cast a vote."),
              isPresented: $showingConfirmVote) {
            Button(String(localized: "OK", comment: "Closes alert dialog if user tries to cast a vote."),
                   role: .cancel) { } // TODO
        } message: {
            Text("You cannot undo this vote.", comment: "Alert dialog message. Shown if user tries to cast a vote.")
        }
    }

    private func lookupStatusTintColor(string: String) -> Color {
        switch string.lowercased() { // string should be unlocalized version as defined in Roadmap.json file
        case "planned": return .plannedColor
        case "?": return .unplannedColor
        default: return Color.red
        }
    }

    // CustomVoter is a wrapper around the default voter used by the Roadmap package
    private struct CustomVoter: FeatureVoter {

//        @Binding var showingConfirmVote: Bool? TODO
        private let defaultVoter: FeatureVoterCountAPI

        init(namespace: String) {
            defaultVoter = FeatureVoterCountAPI(namespace: namespace)
        }

        func fetch(for feature: Roadmap.RoadmapFeature) async -> Int {
            await defaultVoter.fetch(for: feature)
        }

        func vote(for feature: Roadmap.RoadmapFeature) async -> Int? {
//            showingConfirmVote = true // TODO
            return await defaultVoter.vote(for: feature)
        }

//        func setBinding(showingConfirmVote: Binding<Bool>) { TODO
//            _showingConfirmVote = $showingConfirmVote
//        }
    }

}

struct MyRoadmapView_Previews: PreviewProvider {
    @State static private var title = "MyRoadmapView_Preview"

    static var previews: some View {
        VoteOnRoadmapView(useOnlineList: false)
            .navigationTitle(title)
    }
}
