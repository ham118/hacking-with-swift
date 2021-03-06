//
//  ViewController.swift
//  Project32
//
//  Created by clarknt on 2019-09-30.
//  Copyright © 2019 clarknt. All rights reserved.
//

import UIKit
import SafariServices
import CoreSpotlight
import MobileCoreServices

class ViewController: UITableViewController {

    // challenge 1
    var projects = [Project]()

    var favorites = [Int]()
    let favoritesKey = "favorites"

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.isEditing = true
        tableView.allowsSelectionDuringEditing = true

        // challenge 3
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(contentSizeCategoryDidChange), name: UIContentSizeCategory.didChangeNotification, object: nil)

        // challenge 1
        performSelector(inBackground: #selector(loadData), with: nil)
    }

    // challenge 1
    @objc func loadData() {
        // load projects from JSON file
        guard let projectsUrl = Bundle.main.url(forResource: "projects", withExtension: ".json") else {
            fatalError("Cannot load projects list (projects.json) in the app bundle")
        }
        do {
            let data = try Data(contentsOf: projectsUrl)
            let jsonProjects = try JSONDecoder().decode([Project].self, from: data)
            projects = jsonProjects
        }
        catch let error {
            fatalError("Cannot decode projects list (projects.json) in the app bundle: \(error)")
        }

        // load favorites
        let defaults = UserDefaults.standard
        if let savedFavorites = defaults.object(forKey: favoritesKey) as? [Int] {
            favorites = savedFavorites
        }

        tableView.performSelector(onMainThread: #selector(UITableView.reloadData), with: nil, waitUntilDone: false)
    }

    // challenge 3
    @objc func contentSizeCategoryDidChange() {
        // only this combination seems to work when switching from a large font to a small one
        // without that the cell height is to small, making the subtitle disappear
        for cell in tableView.visibleCells {
            cell.textLabel?.numberOfLines = 0
        }
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return projects.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        let project = projects[indexPath.row]
        // challenge 1
        cell.textLabel?.attributedText = makeAttributedString(title: project.title, subtitle: project.subtitle)

        if favorites.contains(indexPath.row) {
            cell.editingAccessoryType = .checkmark
        }
        else {
            cell.editingAccessoryType = .none
        }

        return cell
    }

    func makeAttributedString(title: String, subtitle: String) -> NSAttributedString {
        let titleAttributes = [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .headline), NSAttributedString.Key.foregroundColor: UIColor.purple]
        let subtitleAttributes = [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .subheadline)]

        let titleString = NSMutableAttributedString(string: "\(title)\n", attributes: titleAttributes)
        let subtitleString = NSMutableAttributedString(string: subtitle, attributes: subtitleAttributes)

        // challenge 2: highlight some known keywords
        highlight(in: subtitle, wordsStartingWith: ["UI", "CA", "URL", "NS", "WK"], attributedString: subtitleString)

        titleString.append(subtitleString)

        return titleString
    }

    // challenge 2
    func highlight(in s: String, wordsStartingWith prefixes: [String], attributedString: NSMutableAttributedString) {
        s.enumerateSubstrings(in: s.startIndex..<s.endIndex, options: .byWords) { (substring, substringRange, _, _) in
            guard let substring = substring else { return }

            for prefix in prefixes {
                guard substring.starts(with: prefix) else { continue }

                attributedString.addAttribute(NSAttributedString.Key.backgroundColor,
                                          value: UIColor.black.withAlphaComponent(0.03),
                                          range: NSRange(substringRange, in: s))
            }
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        showTutorial(indexPath.row)
    }

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if favorites.contains(indexPath.row) {
            return .delete
        }
        else {
            return .insert
        }
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .insert {
            favorites.append(indexPath.row)
            index(item: indexPath.row)
        }
        else {
            if let index = favorites.firstIndex(of: indexPath.row) {
                favorites.remove(at: index)
                deindex(item: indexPath.row)
            }
        }

        let defaults = UserDefaults.standard
        defaults.set(favorites, forKey: favoritesKey)

        tableView.reloadRows(at: [indexPath], with: .none)
    }

    func index(item: Int) {
        let project = projects[item]

        let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
        attributeSet.title = project.title // challenge 1
        attributeSet.contentDescription = project.subtitle // challenge 1

        let item = CSSearchableItem(uniqueIdentifier: "\(item)", domainIdentifier: "com.hackingwithswift", attributeSet: attributeSet)
        // if one wanted to override the default 1 month expiration date
        //item.expirationDate = Date.distantFuture

        CSSearchableIndex.default().indexSearchableItems([item]) { error in
            if let error = error {
                print("Indexing error: \(error.localizedDescription)")
            }
            else {
                print("Search item successfully indexed")
            }
        }
    }

    func deindex(item: Int) {
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: ["\(item)"]) { error in
            if let error = error {
                print("Deindexing error: \(error.localizedDescription)")
            }
            else {
                print("Search item successfuly removed")
            }
        }
    }

    func showTutorial(_ which: Int) {
        if let url = URL(string: "https://www.hackingwithswift.com/read/\(which + 1)") {
            let config = SFSafariViewController.Configuration()
            config.entersReaderIfAvailable = true

            let vc = SFSafariViewController(url: url, configuration: config)
            present(vc, animated: true)
        }
    }
}
