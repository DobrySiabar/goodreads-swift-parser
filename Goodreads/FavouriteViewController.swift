
import UIKit
import CoreData

class FavouriteViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var managedObjectContext: NSManagedObjectContext!

    override func viewDidLoad() {
        super.viewDidLoad()
        let cellNib = UINib(nibName: "SearchResultCell", bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: "SearchResultCell")
        tableView.rowHeight = 80
        performFetch()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SeeTheBook" {
            let detailViewController = segue.destination as! DetailViewController
            let indexPath = sender as! IndexPath
            let book = fetchedResultsController.object(at: indexPath)
            let seguedBook: Books = Books()
            seguedBook.bookAuthor = book.author ?? "Unknown"
            seguedBook.bookTitle = book.title ?? "Unknown"
            seguedBook.description = book.bookDescription ?? "Unknown"
            seguedBook.bookRating = book.rating
            detailViewController.book = seguedBook
            detailViewController.imageName = book.imageName ?? ""
            detailViewController.savedBook = true
            detailViewController.managedObjectContext = managedObjectContext
        }
    }
    
    // Using NSFetchedResultsController
    lazy var fetchedResultsController:
        NSFetchedResultsController<Book> = {
            let fetchRequest = NSFetchRequest<Book>()
            let entity = Book.entity()
            fetchRequest.entity = entity
            let sortDescriptor = NSSortDescriptor(key: "date", ascending: true)
            fetchRequest.sortDescriptors = [sortDescriptor]
            fetchRequest.fetchBatchSize = 20
            let fetchedResultsController = NSFetchedResultsController(
                fetchRequest: fetchRequest,
                managedObjectContext: self.managedObjectContext,
                sectionNameKeyPath: nil,
                cacheName: "Books")
            fetchedResultsController.delegate = self
            return fetchedResultsController
    }()
    
    func performFetch() {
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print(error)
        }
    }
    
    func deleteImage(with date: Date) {
        let fileManager = FileManager.default
        let applicationDocumentsDirectory: URL = {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            return paths[0]
        }()
        let urlString = String(format: "\(applicationDocumentsDirectory.path)/\(date).jpg")
        do {
            try fileManager.removeItem(atPath: urlString)
        }
        catch let error as NSError {
            print("Ooops! Something went wrong: \(error)")
        }
    }

}

extension FavouriteViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            if let cell = tableView.cellForRow(at: indexPath!) as? SearchResultCell {
                let book = controller.object(at: indexPath!) as! Book
                cell.configure(for: book)
            }
        case .move:
            tableView.deleteRows(at: [indexPath!], with: .fade)
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        case .update: return
        case .move: return
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}

// MARK: - Table view data source
extension FavouriteViewController: UITableViewDataSource {
    
     func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
     func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultCell", for: indexPath) as! SearchResultCell
        let book = fetchedResultsController.object(at: indexPath)
        cell.configure(for: book)
        return cell
    }
}

extension FavouriteViewController: UITableViewDelegate {
     func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "SeeTheBook", sender: indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
     func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let book = fetchedResultsController.object(at: indexPath)
            let date = book.date
            deleteImage(with: date!)
            managedObjectContext.delete(book)
            do {
                try managedObjectContext.save()
            } catch {
                print(error)
            }
        }
    }
}
