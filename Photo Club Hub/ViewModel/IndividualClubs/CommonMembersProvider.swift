//
//  CommonMembersProvider.swift
//  Photo Club Hub
//
//  Created by KOДИ on 07.08.2024.
//

import CoreData
import Foundation

func addMember(bgContext: NSManagedObjectContext,
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
