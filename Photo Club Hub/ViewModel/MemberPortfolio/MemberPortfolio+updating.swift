//
//  MemberPortfolio+upating.swift
//  Photo Club Hub
//
//  Created by Peter van den Hamer on 20/10/2023.
//

import CoreData // for NSFetchRequest and NSManagedObjectContext

extension MemberPortfolio { // findCreateUpdate() records in Member table

    // Find existing object or create a new object
    // Update existing attributes or fill the new object
    static func findCreateUpdate(bgContext: NSManagedObjectContext,
                                 // identifying attributes of a Member:
                                 organization: Organization, photographer: Photographer,
                                 // non-identifying attributes of a Member:
                                 memberRolesAndStatus: MemberRolesAndStatus,
                                 dateInterval: DateInterval? = nil,
                                 memberWebsite: URL? = nil,
                                 latestImage: URL? = nil,
                                 latestThumbnail: URL? = nil
                                ) -> MemberPortfolio {

        let predicateFormat: String = "organization_ = %@ AND photographer_ = %@" // avoid localization
        let predicate = NSPredicate(format: predicateFormat,
                                    argumentArray: [organization, photographer]
                                   )
        let fetchRequest: NSFetchRequest<MemberPortfolio> = MemberPortfolio.fetchRequest()
        fetchRequest.predicate = predicate
        let memberPortfolios: [MemberPortfolio] = (try? bgContext.fetch(fetchRequest)) ?? [] // nil = absolute failure

        if memberPortfolios.count > 1 { // there is actually a Core Data constraint to prevent this
            ifDebugFatalError("Query returned multiple (\(memberPortfolios.count)) memberPortfolios for " +
                              "\(photographer.fullNameFirstLast) in \(organization.fullNameTown)",
                              file: #fileID, line: #line) // likely deprecation of #fileID in Swift 6.0
            // in release mode, log that there are multiple clubs, but continue using the first one.
        }

        if let memberPortfolio = memberPortfolios.first {
            // already exists, so make sure secondary attributes are up to date
            if memberPortfolio.update(bgContext: bgContext,
                                      memberRolesAndStatus: memberRolesAndStatus,
                                      dateInterval: dateInterval,
                                      memberWebsite: memberWebsite,
                                      latestImage: latestImage,
                                      latestThumbnail: latestThumbnail) {
                print("""
                      \(memberPortfolio.organization.fullName): \
                      Updated info for member \(memberPortfolio.photographer.fullNameFirstLast)
                      """)
            }
             return memberPortfolio
        } else {
            let entity = NSEntityDescription.entity(forEntityName: "MemberPortfolio", in: bgContext)!
            let memberPortfolio = MemberPortfolio(entity: entity, insertInto: bgContext) // bg needs special .init()
            memberPortfolio.organization_ = organization
            memberPortfolio.photographer_ = photographer
            _ = memberPortfolio.update(bgContext: bgContext,
                                       memberRolesAndStatus: memberRolesAndStatus,
                                       dateInterval: dateInterval,
                                       memberWebsite: memberWebsite,
                                       latestImage: latestImage,
                                       latestThumbnail: latestThumbnail)
            print("""
                  \(memberPortfolio.organization.fullNameTown): \
                  Created new membership for \(memberPortfolio.photographer.fullNameFirstLast)
                  """)
            return memberPortfolio
        }
    }

    // Update non-identifying attributes/properties within existing instance of class MemberPortfolio
    // swiftlint:disable:next function_parameter_count function_body_length
    private func update(bgContext: NSManagedObjectContext,
                        memberRolesAndStatus: MemberRolesAndStatus,
                        dateInterval: DateInterval?,
                        memberWebsite: URL?,
                        latestImage: URL?,
                        latestThumbnail: URL?) -> Bool {
        var needsSaving: Bool = false

        // function only works for non-optional Types.
        // If optional support needed, create variant with "inout Type?" instead of "inout Type"
        func updateIfChanged<Type>(update persistedValue: inout Type,
                                   with newValue: Type?) -> Bool // true only if needsSaving
                                   where Type: Equatable {
            if let newValue { // nil means no new value known - and thus doesn't erase existing value
                if persistedValue != newValue {
                    persistedValue = newValue // actual update
                    return true // update needs to be saved
                }
            }
            return false
        }

        func updateIfChangedOptional<Type>(update persistedValue: inout Type?,
                                           with newValue: Type?) -> Bool // true only if needsSaving
                                           where Type?: Equatable {
            if let newValue { // nil means no new value known - and thus doesn't erase existing value
                if persistedValue != newValue {
                    persistedValue = newValue // actual update
                    return true // update needs to be saved
                }
            }
            return false
        }

        let oldMemberRolesAndStatus = self.memberRolesAndStatus // copy of original value
        // actually this setter does merging (overload + or += operators for this?)
        self.memberRolesAndStatus = memberRolesAndStatus
        let newMemberRolesAndStatus = self.memberRolesAndStatus // copy after possible changes

        let changed1 = oldMemberRolesAndStatus != newMemberRolesAndStatus
        let changed2 = updateIfChanged(update: &self.dateIntervalStart, with: dateInterval?.start)
        let changed3 = updateIfChanged(update: &self.dateIntervalEnd, with: dateInterval?.end)
        let changed4 = updateIfChanged(update: &self.level3URL, with: memberWebsite)
        let changed5 = updateIfChangedOptional(update: &self.featuredImage, with: latestImage)
        let changed6 = updateIfChangedOptional(update: &self.featuredImageThumbnail, with: latestThumbnail)
        needsSaving = changed1 || changed2 || changed3 ||
                      changed4 || changed5 || changed6 // forces execution of updateIfChanged()

        if needsSaving && Settings.extraCoreDataSaves {
            do {
                try bgContext.save() // persist just to be sure?
                if changed1 { print("""
                                    \(organization.fullNameTown): \
                                    Changed roles for \(photographer.fullNameFirstLast)
                                    """) }
                if changed2 { print("""
                                    \(organization.fullNameTown): \
                                    Changed start date for \(photographer.fullNameFirstLast)
                                    """) }
                if changed3 { print("""
                                    \(organization.fullNameTown): \
                                    Changed end date for \(photographer.fullNameFirstLast)
                                    """) }
                if changed4 { print("""
                                    \(organization.fullNameTown): \
                                    Changed club website for \(photographer.fullNameFirstLast)
                                    """) }
                if changed5 { print("""
                                    \(organization.fullNameTown): \
                                    Changed latest image for \(photographer.fullNameFirstLast) \
                                    to \(latestImage?.lastPathComponent ?? "<noLatestImage>")
                                    """)}
                if changed6 { print("""
                                    \(organization.fullNameTown): \
                                    Changed latest thumbnail for \(photographer.fullNameFirstLast) \
                                    to \(latestThumbnail?.lastPathComponent ?? "<noLatestThumbnail>")
                                    """)}
            } catch {
                ifDebugFatalError("Update failed for member \(photographer.fullNameFirstLast) " +
                                  "in club \(organization.fullNameTown): \(error)",
                                  file: #fileID, line: #line) // likely deprecation of #fileID in Swift 6.0
                // in release mode, failure to update this data is only logged. And the app doesn't stop.
            }
        }

        return needsSaving
    }

}
