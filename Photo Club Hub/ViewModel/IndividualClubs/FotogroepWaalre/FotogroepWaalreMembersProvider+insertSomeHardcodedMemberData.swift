//
//  FotogroepWaalreMembersProvider+insertSomeHardcodedMemberData.swift
//  Photo Club Hub
//
//  Created by Peter van den Hamer on 01/08/2021.
//

import CoreData // for NSManagedObjectContext
import MapKit // for CLLocationCoordinate2D

extension FotogroepWaalreMembersProvider { // fill with some initial hard-coded content

    func insertSomeHardcodedMemberData(bgContext: NSManagedObjectContext) { // runs on a background thread

        let clubWaalre = Organization.findCreateUpdate(
                                        context: bgContext,
                                        organizationTypeEnum: .club,
                                        idPlus: FotogroepWaalreMembersProvider.photoClubWaalreIdPlus
                                        )
        ifDebugPrint("""
                     \(clubWaalre.fullNameTown): \
                     Starting insertSomeHardcodedMemberData() in background
                     """)
        clubWaalre.hasHardCodedMemberData = true // store in database that we ran insertSomeHardcodedMembers...
        
        let members = [
            ("Carel", "", "Bullens", [MemberRole.viceChairman: true], [:]),
            ("Erik", "van", "Geest", [MemberRole.admin: true], [:]),
            ("Henriëtte", "van", "Ekert", [MemberRole.admin: true], [:]),
            ("Jos", "", "Jansen", [MemberRole.treasurer: true], [:]),
            ("Kees", "van", "Gemert", [MemberRole.secretary: true], [:]),
            ("Marijke", "", "Gallas", [:], [MemberStatus.honorary: true]),
            ("Miek", "", "Kerkhoven", [MemberRole.chairman: true], [:])
        ]
        
        for member in members {
            addMember(bgContext: bgContext,
                      personName: PersonName(givenName: member.0, infixName: member.1, familyName: member.2),
                      organization: clubWaalre,
                      memberRolesAndStatus: MemberRolesAndStatus(role: member.3, stat: member.4))
        }

        do {
            if Settings.extraCoreDataSaves && bgContext.hasChanges { // hasChanges is for optimization only
                try bgContext.save() // persist FotoGroep Waalre and its online member data
            }
            ifDebugPrint("""
                         \(clubWaalre.fullNameTown): \
                         Completed insertSomeHardcodedMemberData() in background
                         """)
        } catch {
            ifDebugFatalError("Fotogroep Waalre: ERROR - failed to save changes to Core Data",
                              file: #fileID, line: #line) // likely deprecation of #fileID in Swift 6.0
            // in release mode, the failed database inserts are only logged. App doesn't stop.
        }

    }

    private func addMember(bgContext: NSManagedObjectContext,
                           personName: PersonName,
                           bornDT: Date? = nil,
                           organization: Organization,
                           memberRolesAndStatus: MemberRolesAndStatus = MemberRolesAndStatus(role: [:], stat: [:]),
                           memberWebsite: URL? = nil,
                           latestImage: URL? = nil) {

        let photographer = Photographer.findCreateUpdate(
                           context: bgContext,
                           personName: PersonName(givenName: personName.givenName,
                                                  infixName: personName.infixName,
                                                  familyName: personName.familyName),
                           memberRolesAndStatus: memberRolesAndStatus,
                           bornDT: bornDT,
                           organization: organization)

        _ = MemberPortfolio.findCreateUpdate(
                            bgContext: bgContext,
                            organization: organization, photographer: photographer,
                            memberRolesAndStatus: memberRolesAndStatus,
                            memberWebsite: memberWebsite,
                            latestImage: latestImage
                            )
        // do not need to bgContext.save() because a series of hardcoded members will be saved simultaneously
    }
}
