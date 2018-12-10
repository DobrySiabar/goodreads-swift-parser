
import UIKit
import CoreData

class DetailViewController: UIViewController, XMLParserDelegate {
    
    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var bookNameLabel: UILabel!
    @IBOutlet weak var authorNameLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    var book: Books!
    var descriptionText = ""
    var eName: String = String()
    var id = 0
    var imageName = ""
    var bookRating = 0.0
    var savedBook = false
    var date = Date()
    var dataTask: URLSessionDataTask?
    var downloadTask: URLSessionDownloadTask?
    var managedObjectContext: NSManagedObjectContext!
    let applicationDocumentsDirectory: URL = {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }()
    
    @IBOutlet weak var addToFavourite: UIButton!
    
    @IBAction func close() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addToFavourite(_ sender: UIButton) {
        if savedBook {
            return
        }
        let bookModel = Book(context: managedObjectContext)
        bookModel.author = book.bookAuthor
        bookModel.title = book.bookTitle
        bookModel.rating = book.bookRating
        bookModel.bookDescription = descriptionText
        bookModel.date = date
        bookModel.imageName = String(describing: date)
        if let image = artworkImageView.image {
            let data = image.jpegData(compressionQuality: 1.0)
            try? data!.write(to: applicationDocumentsDirectory.appendingPathComponent("\(date).jpg"))
        }
        do {
            try managedObjectContext.save()
        } catch {
            fatalError("Error: \(error)")
        }
        addToFavourite.setImage(UIImage(named: "filledStar"), for: .normal)
        savedBook = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorStyle = .none
        descriptionLabel.isHidden = true
        view.tintColor = UIColor(red: 114/255, green: 216/255, blue: 255/255, alpha: 1)
        popupView.layer.cornerRadius = 10
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(close))
        gestureRecognizer.cancelsTouchesInView = false
        gestureRecognizer.delegate = self
        view.addGestureRecognizer(gestureRecognizer)
        if book != nil {
            updateUI()
        }
        parsing(withId: id)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        modalPresentationStyle = .custom
        transitioningDelegate = self
    }
    
    func updateUI() {
        bookNameLabel.text = book.bookTitle
        if book.bookAuthor.isEmpty {
            authorNameLabel.text = "Unknown"
        } else {
            authorNameLabel.text = book.bookAuthor
        }
        id = book.bookId
        bookRating = book.bookRating
        if let largeURL = URL(string: book.artworkLargeURL) {
            downloadTask = artworkImageView.loadImage(url: largeURL)
        }
        if savedBook {
            let filePath = applicationDocumentsDirectory.appendingPathComponent("\(imageName).jpg").path
            if FileManager.default.fileExists(atPath: filePath) {
                artworkImageView.image =  UIImage(contentsOfFile: filePath)
            }
            addToFavourite.isHidden = true
        }
    }
    
    deinit {
        downloadTask?.cancel()
    }
    
    func removeTags() {
        descriptionText = descriptionText.deleteTags(tag: descriptionText)
    }
    
    func xmlURL(bookId: String) -> URL {
        let urlString = String(format:
            "https://www.goodreads.com/book/show/%@?format=xml&key=l4kB49iPjOOqVecSReNA",
                               bookId)
        
        let url = URL(string: urlString)
        return url!
    }
    
    func parsing(withId id: Int) {
        dataTask?.cancel()
        let url = xmlURL(bookId: String(id))
        let queue = DispatchQueue.global()
        queue.async {
            if let parser = XMLParser(contentsOf: url) {
            parser.delegate = self
            parser.parse()
            }
            DispatchQueue.main.async {
                self.removeTags()
                self.descriptionLabel.isHidden = false
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: XMLParserDelegate
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        eName = elementName
        if elementName == "description" {
            descriptionText = String()
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "description" {
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let data = string.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        if (!data.isEmpty) {
            if eName == "description" {
                descriptionText = data
            }
        }
    }

}

extension DetailViewController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController,
                                presenting: UIViewController?,
                                source: UIViewController)
        -> UIPresentationController? {
            return DimmingPresentationController(
                presentedViewController: presented, presenting: presenting)
    }
    
}

extension DetailViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldReceive touch: UITouch) -> Bool {
        return (touch.view === self.view)
    }
    
}

extension DetailViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Description", for: indexPath)
        let label = cell.viewWithTag(1000) as! UILabel
        if !savedBook {
            label.text = descriptionText
        } else {
            label.text = book.description
        }
        ratingLabel.text = String(bookRating)
        return cell
    }
    
}

extension DetailViewController: UITableViewDelegate {
}

extension String {
    func deleteTags(tag: String) -> String {
        var textWithoutTags = ""
        textWithoutTags = self.replacingOccurrences(of: "<br /><br />", with: "\n\n", options: .regularExpression, range: nil)
        textWithoutTags = textWithoutTags.replacingOccurrences(of: "<i>", with: "", options: .regularExpression, range: nil)
        textWithoutTags = textWithoutTags.replacingOccurrences(of: "</i>", with: "", options: .regularExpression, range: nil)
        return textWithoutTags
    }

}
