//
//  AndersMembersProvider+InsertSomeHardcodedMemberData.swift
//  Photo Club Hub
//
//  Created by Peter van den Hamer on 29/10/2023.
//

import CoreData // for NSManagedObjectContext
import Foundation // for date processing
import MapKit // for CLLocationCoordinate2D

extension AndersMembersProvider { // fill with some initial hard-coded content

    private static let andersURL = URL(string: "https://nl.qrcodechimp.com/page/a6d3r7?v=chk1697032881")
    private static let fotogroepAndersIdPlus = OrganizationIdPlus(fullName: "Fotogroep Anders",
                                                                  town: "Eindhoven",
                                                                  nickname: "FG Anders")

    func insertSomeHardcodedMemberData(bgContext: NSManagedObjectContext) {
        bgContext.perform { // from here on, we are running on a background thread
            self.insertSomeHardcodedMemberDataCommon(bgContext: bgContext)
            do {
                if bgContext.hasChanges { // optimisation
                    try bgContext.save() // persist FG Anders and its online member data (on private context)
                    print("Sucess loading FG Anders member data")
                }
            } catch {
                ifDebugFatalError("Error saving members of FG Anders: \(error.localizedDescription)")
            }
        }
    }

    // swiftlint:disable:next function_body_length
    private func insertSomeHardcodedMemberDataCommon(bgContext: NSManagedObjectContext) {

        // add De Gender to Photo Clubs (if needed)
        let clubAnders = Organization.findCreateUpdate(
                                                    context: bgContext,
                                                    organizationTypeEnum: .club,
                                                    idPlus: Self.fotogroepAndersIdPlus
                                                   )

        ifDebugPrint("""
                     \(clubAnders.fullNameTown): \
                     Starting insertSomeHardcodedMemberData() in background
                     """)
        clubAnders.hasHardCodedMemberData = true // store in database that we ran insertSomeHardcodedMembers...
        
        let members: [(givenName: String, infixName: String, familyName: String, role: [MemberRole: Bool], stat: [MemberStatus: Bool], memberWebsite: URL?, latestImage: URL?, latestThumbnail: URL?)] = [
            (
                givenName: "Helga",
                infixName: "",
                familyName: "Nuchelmans",
                role: [MemberRole.admin: true],
                stat: [:],
                memberWebsite: URL(string: "https://helganuchelmans.nl"),
                latestImage: URL(string: "https://cdn.myportfolio.com/d8801b208f49ae95bc80b15c07cde6f2/902cb616-6aaf-4f1f-9d40-3487d0e1254a_rw_1200.jpg?h=7fee8b232bc10216ccf294e69a81be4c"),
                latestThumbnail: nil
            ),
            (
                givenName: "Mirjam",
                infixName: "",
                familyName: "Evers",
                role: [MemberRole.admin: true],
                stat: [:],
                memberWebsite: URL(string: "https://me4photo.jimdosite.com/portfolio/"),
                latestImage: URL(string: "https://jimdo-storage.freetls.fastly.net/image/bf4d707f-ff72-4e16-8f2f-63680e7a8f91.jpg?format=pjpg&quality=80,90&auto=webp&disable=upscale&width=2560&height=2559"),
                latestThumbnail: nil
            ),
            (
                givenName: "Lotte",
                infixName: "",
                familyName: "Vrij",
                role: [MemberRole.admin: true],
                stat: [:],
                memberWebsite: URL(string: FotogroepWaalreMembersProvider.baseURL + "Empty_Website/"),
                latestImage: URL(string: "https://image.jimcdn.com/app/cms/image/transf/none/path/sb2e92183adfb60fb/image/ie69f110f416b6822/version/1678882175/image.jpg"),
                latestThumbnail: URL(string: "https://image.jimcdn.com/app/cms/image/transf/dimension=150x150:mode=crop:format=jpg/path/sb2e92183adfb60fb/image/ie69f110f416b6822/version/1678882175/image.jpg")
            ),
            (
                givenName: "Dennis",
                infixName: "",
                familyName: "Verbruggen",
                role: [MemberRole.admin: true],
                stat: [:],
                memberWebsite: URL(string: FotogroepWaalreMembersProvider.baseURL + "/Empty_Website/"),
                latestImage: URL(string: "http://www.vdhamer.com/wp-content/uploads/2023/11/DennisVerbruggen.jpeg"),
                latestThumbnail: nil
            )
        ]
        
        for member in members {
            addMember(bgContext: bgContext,
                      personName: PersonName(givenName: member.0, infixName: member.1, familyName: member.2),
                      organization: clubAnders,
                      memberRolesAndStatus: MemberRolesAndStatus(role: member.3, stat: member.4),
                      memberWebsite: member.5,
                      latestImage: member.6,
                      latestThumbnail: member.7)
        }
    }
}
