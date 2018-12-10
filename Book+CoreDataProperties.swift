
import Foundation
import CoreData


extension Book {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Book> {
        return NSFetchRequest<Book>(entityName: "Book")
    }

    @NSManaged public var title: String?
    @NSManaged public var author: String?
    @NSManaged public var rating: Double
    @NSManaged public var bookDescription: String?
    @NSManaged var date: Date?
    @NSManaged var imageName: String?

}
