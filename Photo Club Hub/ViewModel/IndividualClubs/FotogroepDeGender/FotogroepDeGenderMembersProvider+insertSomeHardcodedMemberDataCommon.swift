//
//  FotogroepDeGenderMembersProvider+insertSomeHardcodedMemberDataCommon.swift
//  Photo Club Hub
//
//  Created by Peter van den Hamer on 29/09/2023.
//

import CoreData // for NSManagedObjectContext
import Foundation // for date processing
import MapKit // for CLLocationCoordinate2D

extension FotogroepDeGenderMembersProvider { // fill with some initial hard-coded content

    private static let deGenderURL = URL(string: "https://www.fcdegender.nl")
    private static let fotogroepDeGenderIdPlus = OrganizationIdPlus(fullName: "Fotogroep de Gender",
                                                                    town: "Eindhoven",
                                                                    nickname: "FG deGender")

    func insertSomeHardcodedMemberData(bgContext: NSManagedObjectContext) {
        bgContext.perform {
            self.insertSomeHardcodedMemberDataCommon(bgContext: bgContext) // perform inserts on a background thread
            do {
                if bgContext.hasChanges { // optimisation
                    try bgContext.save() // persist FG de Gender and its online member data
                    print("Sucess loading FG de Gender member data")
                }
            } catch {
                ifDebugFatalError("Could not save members of FG de Gender")
            }
        }
    }

    private func insertSomeHardcodedMemberDataCommon(bgContext: NSManagedObjectContext) {

        // add De Gender to Photo Clubs (if needed)
        let clubDeGender = Organization.findCreateUpdate(context: bgContext,
                                                         organizationTypeEnum: .club,
                                                         idPlus: Self.fotogroepDeGenderIdPlus)
        ifDebugPrint("\(clubDeGender.fullNameTown): Starting insertSomeHardcodedMemberData() in background")
        clubDeGender.hasHardCodedMemberData = true // store in database that we ran insertSomeHardcodedMembers...

        let isoDate = "1954-10-09T00:12:00.000000Z"
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let bornDT = dateFormatter.date(from: isoDate)!
        
        let members: [(
            givenName: String,
            infixName: String,
            familyName: String,
            website: URL?,
            bornDT: Date?,
            organization: Organization,
            rolesAndStatus: MemberRolesAndStatus,
            memberWebsite: URL?,
            latestImage: URL?,
            latestThumbnail: URL?,
            eMail: String?)] = [
                (
                    givenName: "Mariet",
                    infixName: "",
                    familyName: "Wielders",
                    website: URL(string: "https://www.m3w.nl"),
                    bornDT: bornDT,
                    organization: clubDeGender,
                    rolesAndStatus: MemberRolesAndStatus(role: [.chairman: false], stat: [:]),
                    memberWebsite: URL(string: "https://www.fcdegender.nl/wp-content/uploads/Expositie%202023/Mariet/"),
                    latestImage: URL(string: "https://www.fcdegender.nl/wp-content/uploads/Expositie%202023/Mariet/slides/Mariet%203.jpg"),
                    latestThumbnail: nil,
                    eMail: nil
                ),
                (
                    givenName: "Peter",
                    infixName: "van den",
                    familyName: "Hamer",
                    website: nil,
                    bornDT: nil,
                    organization: clubDeGender,
                    rolesAndStatus: MemberRolesAndStatus(role: [:], stat: [.prospective: false]),
                    memberWebsite: URL(string: FotogroepWaalreMembersProvider.baseURL + "Empty_Website/"),
                    latestImage: URL(string: "http://www.vdhamer.com/wp-content/uploads/2024/04/2023_Cornwall_R5_581-Pano.jpg"),
                    latestThumbnail: nil,
                    eMail: nil
                ),
                (
                    givenName: "Bettina",
                    infixName: "de",
                    familyName: "Graaf",
                    website: nil,
                    bornDT: nil,
                    organization: clubDeGender,
                    rolesAndStatus: MemberRolesAndStatus(role: [:], stat: [.prospective: false]),
                    memberWebsite: URL(string: FotogroepWaalreMembersProvider.baseURL + "Empty_Website/"),
                    latestImage: URL(string: "http://www.vdhamer.com/wp-content/uploads/2023/11/BettinaDeGraaf.jpeg"),
                    latestThumbnail: nil,
                    eMail: nil
                )
            ]
        
        for member in members {
            addMember(bgContext: bgContext,
                      personName: PersonName(givenName: member.0, infixName: member.1, familyName: member.2),
                      website: member.3,
                      bornDT: member.4,
                      organization: member.5,
                      memberRolesAndStatus: member.6,
                      memberWebsite: member.7,
                      latestImage: member.8,
                      latestThumbnail: member.9,
                      eMail: member.10)
        }
    }

    private func addMember(bgContext: NSManagedObjectContext,
                           personName: PersonName,
                           website: URL? = nil,
                           bornDT: Date? = nil,
                           organization: Organization,
                           memberRolesAndStatus: MemberRolesAndStatus = MemberRolesAndStatus(role: [:], stat: [:]),
                           memberWebsite: URL? = nil,
                           latestImage: URL? = nil,
                           latestThumbnail: URL? = nil,
                           phoneNumber: String? = nil,
                           eMail: String? = nil) {

        let photographer = Photographer.findCreateUpdate(context: bgContext,
                                                         personName: personName,
                                                         memberRolesAndStatus: memberRolesAndStatus,
                                                         website: website,
                                                         bornDT: bornDT,
                                                         organization: organization
                                                         )

        let image = latestImage ?? latestThumbnail // if image not available, use thumbnail (which might also be nil)
        let thumb = latestThumbnail ?? latestImage // if thumb not available, use image (which might also be nil)
        _ = MemberPortfolio.findCreateUpdate(bgContext: bgContext,
                                             organization: organization, photographer: photographer,
                                             memberRolesAndStatus: memberRolesAndStatus,
                                             memberWebsite: memberWebsite,
                                             latestImage: image,
                                             latestThumbnail: thumb)
    }

}
