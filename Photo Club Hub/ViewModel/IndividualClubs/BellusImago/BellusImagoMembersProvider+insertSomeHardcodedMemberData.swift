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
                                                            idPlus: Self.photoClubBellusImagoIdPlus,
                                                            optionalFields: OrganizationOptionalFields() // empty
                                                           )

        ifDebugPrint("""
                     \(clubBellusImago.fullNameTown): \
                     Starting insertSomeHardcodedMemberData() in background
                     """)
        clubBellusImago.hasHardCodedMemberData = true // store in database that we ran insertSomeHardcodedMembers...

        addMember(bgContext: bgContext, // add Rico to Photographers and member of Bellus (if needed)
                  personName: PersonName(givenName: "Rico", infixName: "", familyName: "Coolen"),
                  website: URL(string: "https://www.ricoco.nl"),
                  organization: clubBellusImago,
                  optionalFields: MemberOptionalFields(
                    memberWebsite: URL(string: "https://www.fotoclubbellusimago.nl/rico.html"),
                    latestImage: URL(string: "https://www.fotoclubbellusimago" +
                                             ".nl/uploads/5/5/1/2/55129719/vrijwerk-rico-3_orig.jpg")
                  ),
                  eMail: "info@ricoco.nl"
        )

        addMember(bgContext: bgContext, // add Loek to Photographers and member of Bellus (if needed)
                  personName: PersonName(givenName: "Loek", infixName: "", familyName: "Dirkx"),
                  organization: clubBellusImago,
                  optionalFields: MemberOptionalFields(
                    memberRolesAndStatus: MemberRolesAndStatus(role: [ .chairman: true ]),
                    memberWebsite: URL(string: "https://www.fotoclubbellusimago.nl/loek.html"),
                    latestImage: URL(string: "https://www.fotoclubbellusimago" +
                                             ".nl/uploads/5/5/1/2/55129719/vrijwerk-loek-1_2_orig.jpg")
                  )
        )

    }

    private func addMember(bgContext: NSManagedObjectContext,
                           personName: PersonName,
                           website: URL? = nil,
                           bornDT: Date? = nil,
                           organization: Organization,
                           optionalFields: MemberOptionalFields,
                           phoneNumber: String? = nil,
                           eMail: String? = nil) {

        let photographer = Photographer.findCreateUpdate(context: bgContext,
                                                         personName: personName,
                                                         isDeceased: optionalFields.memberRolesAndStatus.isDeceased(),
                                                         website: website,
                                                         bornDT: bornDT,
                                                         organization: organization
                                                         )

        var localOptionalFields = optionalFields // in order to change two fields in optionalFields
        // if latestImage is nil, use thumbnail (which might also be nil)
        localOptionalFields.latestImage = optionalFields.latestImage ?? optionalFields.latestThumbnail
        // if latestThumbnail is nil, use image (which might also be nil)
        localOptionalFields.latestImage = optionalFields.latestThumbnail ?? optionalFields.latestImage

        _ = MemberPortfolio.findCreateUpdate(bgContext: bgContext,
                                             organization: organization,
                                             photographer: photographer,
                                             optionalFields: localOptionalFields
                                             )
    }

}
