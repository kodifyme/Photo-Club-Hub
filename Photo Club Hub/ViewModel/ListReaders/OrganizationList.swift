//
//  OrganizationList.swift
//  Photo Club Hub
//
//  Created by Peter van den Hamer on 16/12/2023.
//

import SwiftyJSON
import CoreData // for NSManagedObjectContext
import CoreLocation // for CLLocationCoordinate2D

private let dataSourcePath: String = """
                                     https://raw.githubusercontent.com/\
                                     vdhamer/Photo-Club-Hub/\
                                     main/\
                                     Photo%20Club%20Hub/ViewModel/Lists/
                                     """
// private let dataSourceFile: String = "Test2Club2MuseumList.json"
private let dataSourceFile: String = "OrganizationList.json"
private let organizationTypesToLoad: [OrganizationTypeEnum] = [.club, .museum]

/* Example of basic OrganizationList.json content
{
    "clubs": [
        {
            "idPlus": {
                "town": "Eindhoven",
                "fullName": "Fotogroep de Gender",
                "nickName": "FG deGender"
            },
            "coordinates": {
                "latitude": 51.42398,
                "longitude": 5.45010
            }
            "website": "https://www.fcdegender.nl",
            "memberList": "https://www.example.com/deGenderMemberList.json"
            "description": [
                {
                    "language": "NL",
                    "value": "In dit museum zijn scenes van het TV programma 'Het Perfecte Plaatje' opgenomen."
                }
            ]
        }
    ],
    "museums": [
        {
            "idPlus": {
                "town": "New York",
                "fullName": "Fotografiska New York",
                "nickName": "Fotografiska NYC"
            },
            "coordinates": {
                "latitude": 40.739278,
                "longitude": -73.986722
            }
            "website": "https://www.fotografiska.com/nyc/",
            "wikipedia": "https://en.wikipedia.org/wiki/Fotografiska_New_York",
            "image": "https://commons.wikimedia.org/wiki/File:Fotografiska_New_York_(51710073919).jpg"
            "description": [
                {
                    "language": "EN",
                    "value": "Associated with the original Fotografiska Museum in Stockholm"
                }
            ]
        }
    ]
}
*/

class OrganizationList {

    init(bgContext: NSManagedObjectContext) {

        bgContext.perform { // switch to supplied background thread
            self.readJSONOrganizationList(bgContext: bgContext, for: organizationTypesToLoad)
        }
    }

    private func readJSONOrganizationList(bgContext: NSManagedObjectContext,
                                          for organizationTypeEnumsToLoad: [OrganizationTypeEnum]) {

        ifDebugPrint("\nStarting readJSONOrganizationList(\(dataSourceFile)) in background")

        guard let data = try? String(contentsOf: URL(string: dataSourcePath+dataSourceFile)!) else {
            // calling fatalError is ok for a compile-time constant (as defined above)
            fatalError("Please check URL \(dataSourcePath+dataSourceFile)")
        }
        // give the data to SwiftyJSON to parse
        let jsonRoot = JSON(parseJSON: data) // call to SwiftyJSON

        // extract the requested organizationType one-by-one from the json file
        for organizationTypeEnum in organizationTypeEnumsToLoad {
            PhotoClub.hackOrganizationTypeEnum = organizationTypeEnum

            let jsonOrganizationsOfOneType: [JSON] = jsonRoot[organizationTypeEnum.unlocalizedPlural].arrayValue
            ifDebugPrint("Found \(jsonOrganizationsOfOneType.count) \(organizationTypeEnum.unlocalizedPlural) " +
                         "in \(dataSourceFile).")

            // extract the requested items (clubs, musea) of that organizationType one-by-one from the json file
            for jsonOrganization in jsonOrganizationsOfOneType {
                let idPlus = PhotoClubIdPlus(fullName: jsonOrganization["idPlus"]["fullName"].stringValue,
                                             town: jsonOrganization["idPlus"]["town"].stringValue,
                                             nickname: jsonOrganization["idPlus"]["nickName"].stringValue)
                ifDebugPrint("Adding organization \(idPlus.fullName), \(idPlus.town), aka \(idPlus.nickname)")
                let jsonCoordinates = jsonOrganization["coordinates"]
                let coordinates = CLLocationCoordinate2D(latitude: jsonCoordinates["latitude"].doubleValue,
                                                         longitude: jsonCoordinates["longitude"].doubleValue)
                let photoClubWebsite = URL(string: jsonOrganization["website"].stringValue)
                let wikipedia = URL(string: jsonOrganization["wikipedia"].stringValue)
                let localizedDescriptions = jsonOrganization["description"].arrayValue
                let fotobondNumber = jsonOrganization["nlSpecific"]["fotobondNumber"].int16Value
                let kvkNumber = jsonOrganization["nlSpecific"]["kvkNumber"].int32Value
                _ = PhotoClub.findCreateUpdate(context: bgContext,
                                               organizationTypeEum: organizationTypeEnum,
                                               photoClubIdPlus: idPlus,
                                               photoClubWebsite: photoClubWebsite,
                                               wikipedia: wikipedia,
                                               fotobondNumber: fotobondNumber, // int16
                                               kvkNumber: kvkNumber, // int32
                                               coordinates: coordinates,
                                               localizedDescriptions: localizedDescriptions)
            }
            do {
                if bgContext.hasChanges { // optimization recommended by Apple
                    try bgContext.save() // persist contents of OrganizationList.json
                }
                ifDebugPrint("Completed readJSONOrganizationList() in background")
            } catch {
                ifDebugFatalError("Failed to save changes to Core Data",
                                  file: #fileID, line: #line) // likely deprecation of #fileID in Swift 6.0
                // in release mode, the failed database update is only logged. App doesn't stop.
                ifDebugPrint("Failed to save JSON ClubList items in background")
            }
        }
    }

}
