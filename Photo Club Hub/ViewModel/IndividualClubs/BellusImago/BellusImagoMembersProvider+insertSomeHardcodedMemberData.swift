//
//  BellusImagoMembersProvider+insertSomeHardcodedMemberData.swift
//  Photo Club Hub
//
//  Created by Peter van den Hamer on 01/08/2021.
//

import CoreData // for NSManagedObjectContext
import MapKit // for CLLocationCoordinate2D

extension BellusImagoMembersProvider { // fill with some initial hard-coded content

    private static let bellusImagoURL = URL(string: "https://www.fotoClubBellusImago.nl")
    private static let photoClubBellusImagoIdPlus = OrganizationIdPlus(fullName: "Fotoclub Bellus Imago",
                                                                       town: "Veldhoven",
                                                                       nickname: "FC BellusImago")

    func insertSomeHardcodedMemberData(bgContext: NSManagedObjectContext) {
        bgContext.perform { // from here on, we are running on a background thread
            self.insertSomeHardcodedMemberDataCommon(bgContext: bgContext)
            do {
                if bgContext.hasChanges { // optimisation
                    try bgContext.save() // persist FC Bellus Imago and its online member data
                    print("Sucess loading persist FC Bellus Imago member data")
                }
            } catch {
                ifDebugFatalError("Could not save members of persist FC Bellus Imago")
            }
        }
    }

    private func insertSomeHardcodedMemberDataCommon(bgContext: NSManagedObjectContext) {

        // add Bellus Imago to Photo Clubs (if needed)
        let clubBellusImago = Organization.findCreateUpdate(
                                                            context: bgContext,
                                                            organizationTypeEnum: .club,
                                                            idPlus: Self.photoClubBellusImagoIdPlus
                                                           )

        ifDebugPrint("""
                     \(clubBellusImago.fullNameTown): \
                     Starting insertSomeHardcodedMemberData() in background
                     """)
        clubBellusImago.hasHardCodedMemberData = true // store in database that we ran insertSomeHardcodedMembers...

        let members: [(
            givenName: String,
            infixName: String,
            familyName: String,
            website: URL?,
            organization: Organization,
            rolesAndStatus: MemberRolesAndStatus,
            memberWebsite: URL?,
            latestImage: URL?,
            latestThumbnail: URL?,
            eMail: String?)] = [
                (
                    givenName: "Rico",
                    infixName: "",
                    familyName: "Coolen",
                    website: URL(string: "https://www.ricoco.nl"),
                    organization: clubBellusImago,
                    rolesAndStatus: MemberRolesAndStatus(role: [:], stat: [:]),
                    memberWebsite: URL(string: "https://www.fotoclubbellusimago.nl/rico.html"),
                    latestImage: URL(string: "https://www.fotoclubbellusimago.nl/uploads/5/5/1/2/55129719/vrijwerk-rico-3_orig.jpg"),
                    latestThumbnail: nil,
                    eMail: "info@ricoco.nl"
                ),
                (
                    givenName: "Loek",
                    infixName: "",
                    familyName: "Dirkx",
                    website: nil,
                    organization: clubBellusImago,
                    rolesAndStatus: MemberRolesAndStatus(role: [ .chairman: true ], stat: [:]),
                    memberWebsite: URL(string: "https://www.fotoclubbellusimago.nl/loek.html"),
                    latestImage: URL(string: "https://www.fotoclubbellusimago.nl/uploads/5/5/1/2/55129719/vrijwerk-loek-1_2_orig.jpg"),
                    latestThumbnail: nil,
                    eMail: nil
                )
            ]
        
        for member in members {
            addMember(bgContext: bgContext,
                      personName: PersonName(givenName: member.0, infixName: member.1, familyName: member.2),
                      website: member.3,
                      organization: member.4,
                      memberRolesAndStatus: member.5,
                      memberWebsite: member.6,
                      latestImage: member.7,
                      latestThumbnail: member.8,
                      eMail: member.9)
        }
    }
}
