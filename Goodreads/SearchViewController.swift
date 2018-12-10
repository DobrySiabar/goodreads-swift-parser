
import UIKit
import CoreData

class SearchViewController: UIViewController, XMLParserDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    var books: [Books] = []
    var bookTitle = ""
    var bookAuthor = ""
    var imageUrl = ""
    var smallImageUrl = ""
    var bookRating = 0.0
    var id = 0
    var imageName = ""
    
    var eName = ""
    var hasSearched = false
    var isLoading = false
    
    var resultsEnd = 0
    var totalResults = 200
    var currentResult = 0
    var pageNumber = 1
    var lastPage = true
    var titleId = false
    var searchedText = ""
    
    var dataTask: URLSessionDataTask?
    var managedObjectContext: NSManagedObjectContext!
    
    struct TableViewCellIdentifiers {
        static let searchResultCell = "SearchResultCell"
        static let nothingFoundCell = "NothingFoundCell"
        static let loadingCell = "LoadingCell"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Register new cells
        var cellNib = UINib(nibName: TableViewCellIdentifiers.searchResultCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.searchResultCell)
        
        cellNib = UINib(nibName: TableViewCellIdentifiers.nothingFoundCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.nothingFoundCell)
        
        cellNib = UINib(nibName: TableViewCellIdentifiers.loadingCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.loadingCell)
        
        tableView.rowHeight = 80
        tableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowDetail" {
            let detailViewController = segue.destination as! DetailViewController
            let indexPath = sender as! IndexPath
            let book = books[indexPath.row]
            detailViewController.book = book
            detailViewController.imageName = imageName
            detailViewController.managedObjectContext = managedObjectContext
        }
    }
    
    // Make URL
    func xmlURL(searchText: String, pageNumber: Int) -> URL {
        let escapedSearchText = searchText.addingPercentEncoding(
            withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        let urlString = String(format:
            "https://www.goodreads.com/search/index.xml?page=%@&key=l4kB49iPjOOqVecSReNA&q=%@",
                               String(pageNumber), escapedSearchText)
        let url = URL(string: urlString)
        return url!
    }
    
    
    // Start parsing
    func parsing(withText text: String) {
        dataTask?.cancel()
        isLoading = true
        hasSearched = true
        searchedText = text
        let url = xmlURL(searchText: text, pageNumber: pageNumber)
        let session = URLSession.shared
        dataTask = session.dataTask(with: url, completionHandler: {
            data, response, error in
            if let error = error as NSError?, error.code == -999 {
                return
            } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                if let data = data {
                    let parser = XMLParser(data: data)
                        parser.delegate = self
                        parser.parse()
                }
            }
            DispatchQueue.main.async {
                self.hasSearched = false
                self.isLoading = false
                self.tableView.reloadData()
                if (self.totalResults == 0) {
                    return
                }
                if !(self.resultsEnd == self.totalResults) {
                    self.pageNumber += 1
                    self.isLoading = false
                    self.lastPage = false
                } else {
                    self.lastPage = true
                    self.tableView.reloadData()
                }
            }
        
        })
        dataTask?.resume()
    }
    
    func performInserting() {
        let indexPaths = (0 ..< books.count).map { IndexPath(row: $0, section: 0) }
        tableView.insertRows(at: indexPaths, with: .none)
    }
    
    // MARK: XMLParserDelegate
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        eName = elementName
        if elementName == "best_book" {
            bookTitle = String()
            bookAuthor = String()
            smallImageUrl = String()
        }
        if eName == "best_book" {
            titleId = true
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "best_book" {
            let book = Books()
            book.bookTitle = bookTitle
            book.bookAuthor = bookAuthor
            book.artworkSmallURL = smallImageUrl
            book.artworkLargeURL = imageUrl
            book.bookId = id
            book.bookRating = bookRating
            books.append(book)
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let data = string.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        if (!data.isEmpty) {
            if eName == "results-end" {
                resultsEnd = Int(data)!
            }
            if eName == "total-results" {
                totalResults = Int(data)!
            }
            if eName == "title" {
                bookTitle += data
            }
            if eName == "name" {
                bookAuthor += data
            }
            if eName == "image_url" {
                imageUrl = data
            }
            if eName == "small_image_url" {
                smallImageUrl += data
            }
            if eName == "average_rating" {
                bookRating = Double(data)!
            }
            if titleId, eName == "id" {
                id = Int(data)!
                titleId = false
            }
        }
    }
    
}

extension SearchViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        books = []
        pageNumber = 1
        let text = searchBar.text!
        parsing(withText: text)
        tableView.reloadData()
    }
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}

extension SearchViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if totalResults == 0 {
            return 1
        } else if !lastPage {
            return books.count + 1
        } else if isLoading {
            return 1
        } else {
            return books.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let allRows = tableView.numberOfRows(inSection: 0)
        let indexes = (0 ..< allRows).map { $0 }
        if (!isLoading || indexes.contains(books.count)), (books.count != indexPath.row) {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: TableViewCellIdentifiers.searchResultCell,
                for: indexPath) as! SearchResultCell
            let book = books[indexPath.row]
            cell.configure(for: book)
            if let last = tableView.indexPathsForVisibleRows?.last?[1] {
                let indexes = (books.count-5 ..< allRows).map { $0 }
                if (indexes.contains(last)), !(lastPage) {
                    parsing(withText: searchedText)
                }
            }
            return cell
        } else if isLoading {
            let cell = tableView.dequeueReusableCell(withIdentifier:
                TableViewCellIdentifiers.loadingCell, for: indexPath)
            let spinner = cell.viewWithTag(100) as! UIActivityIndicatorView
            spinner.startAnimating()
            return cell
        } else if totalResults == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier:
                TableViewCellIdentifiers.nothingFoundCell, for: indexPath)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: TableViewCellIdentifiers.searchResultCell,
                for: indexPath) as! SearchResultCell
            return cell
        }
    }

}

extension SearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "ShowDetail", sender: indexPath)
    }
    
    func tableView(_ tableView: UITableView,
                   willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if books.count == 0 || isLoading {
            return nil
        } else {
            return indexPath
        }
    }
    
}
