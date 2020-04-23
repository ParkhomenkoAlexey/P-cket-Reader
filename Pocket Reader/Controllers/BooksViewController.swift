//
//  BooksViewController.swift
//  Pocket Reader
//
//  Created by Алексей Пархоменко on 01.03.2020.
//  Copyright © 2020 Алексей Пархоменко. All rights reserved.
//

import UIKit
import WatchConnectivity

class BooksViewController: UIViewController {
    
    var objects = BookItem.getBooks()
    
    enum Section: Int {
        case activeNow = 0, psychology, children, novels, detectives
        func description() -> String {
            switch self {
            case .activeNow:
                return "ВАШ ВЫБОР"
            case .psychology:
                return "ПСИХОЛОГИЯ, МОТИВАЦИЯ"
            case .children:
                 return "ДЕТСКИЕ КНИГИ"
            case .novels:
                return "ЛЮБОВНЫЕ РОМАНЫ"
            case .detectives:
                return "ДЕТЕКТИВЫ"
            }
        }
        
        func gengeType() -> GenreType {
            switch self {
            case .activeNow:
                return .activeNow
            case .psychology:
                return .psychology
            case .children:
                return .children
            case .novels:
                return .novels
            case .detectives:
                return .detectives
            }
        }
    }
    
    var dataSource: DataSource!
    var tableView: UITableView!
    var notificationObserver: NSObjectProtocol?
    
    // MARK: - View Setup
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(UserSettings.userBooks)
        setupNavigationController()
        setupElements()
        setupConstraints()
        configureDataSource()
        
        notificationObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "GetBooksFromWatch"), object: nil, queue: nil, using: { (_) in
            let snapshot = self.initialSnapshot()
            self.dataSource.apply(snapshot, animatingDifferences: false)
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.setEditing(true, animated: true)
    }

    func initialSnapshot() -> NSDiffableDataSourceSnapshot<Section, BookItem> {
        var snapshot = NSDiffableDataSourceSnapshot<Section, BookItem>()
        
        let pickedBooks = Set(UserSettings.userBooks.lazy.map { $0.name })
        let noPickedBooks = objects.filter { !pickedBooks.contains($0.name) }
        objects = noPickedBooks

        snapshot.appendSections([.activeNow])
        snapshot.appendItems(UserSettings.userBooks)
        snapshot.appendSections([.psychology])
        snapshot.appendItems(objects.filter { $0.genre == .psychology })
        snapshot.appendSections([.children])
        snapshot.appendItems(objects.filter { $0.genre == .children })
        snapshot.appendSections([.novels])
        snapshot.appendItems(objects.filter { $0.genre == .novels })
        snapshot.appendSections([.detectives])
        snapshot.appendItems(objects.filter { $0.genre == .detectives })
        
        return snapshot
    }
}

// MARK: - View Setup
extension BooksViewController {
    func setupNavigationController() {
        title = "Pocket Reader"
        navigationItem.rightBarButtonItem?.isEnabled = false
    }

    func setupElements() {
        view.backgroundColor = .systemBackground
    
        tableView = UITableView(frame: .zero, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.allowsSelectionDuringEditing  = true
    }
}

// MARK: - Setup Constraints
extension BooksViewController {
    private func setupConstraints() {
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

// MARK: - Data Source
extension BooksViewController {
    
    class DataSource: UITableViewDiffableDataSource<Section, BookItem> {
        
        override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            let sectionKind = Section(rawValue: section)
            return sectionKind?.description()

        }
        
        override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
            if section == 0 {
                return "Добавляй в эту секцию те книги, которые хочешь прочитать!"
            } else {
                return nil
            }
        }
        
        override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
            return true
        }
        
        override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            if editingStyle == .insert {
                let destinationIndexPath = IndexPath(row: 0, section: 0)
                guard let sourceIdentifier = itemIdentifier(for: indexPath) else { return }
                let destinationIdentifier = itemIdentifier(for: destinationIndexPath)
                
                var snapshot = self.snapshot()
                
                if let destinationIdentifier = destinationIdentifier {
                    snapshot.deleteItems([sourceIdentifier])
                    snapshot.insertItems([sourceIdentifier], beforeItem: destinationIdentifier)
                    apply(snapshot)
                } else {
                    let destinationSectionIdentifier = snapshot.sectionIdentifiers[destinationIndexPath.section]
                    snapshot.deleteItems([sourceIdentifier])
                    snapshot.appendItems([sourceIdentifier], toSection: destinationSectionIdentifier)
                    
                    apply(snapshot)
                }
            }
            if editingStyle == .delete {
                guard let sourceIdentifier = itemIdentifier(for: indexPath) else { return }
                var snapshot = self.snapshot()
                
                for section in snapshot.sectionIdentifiers {
                    if section.gengeType() == sourceIdentifier.genre {
                        snapshot.deleteItems([sourceIdentifier])
                        snapshot.appendItems([sourceIdentifier], toSection: section)
                        apply(snapshot)
                    }
                }
            }
            
            let snapshot = self.snapshot()
            let pickedItems = snapshot.itemIdentifiers(inSection: .activeNow)
            UserSettings.userBooks = pickedItems
            
            sendSelectedBooksToWatch()
        }
        
        func sendSelectedBooksToWatch() {
            if WCSession.isSupported() {
                let pickedBooks = UserSettings.userBooks.map { (book) in
                    return book.representation
                }
                
                do {
                    let dict: [String: Any] = ["books": pickedBooks]
                    try WCSession.default.updateApplicationContext(dict)
                } catch {
                    print("Error: \(error)")
                }
            }
        }
    }

    
    func configureDataSource() {
        
        dataSource = DataSource(tableView: tableView) { (tableView, indexPath, book) -> UITableViewCell? in
            
            var cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            
            cell = UITableViewCell(style: UITableViewCell.CellStyle.value1,
                           reuseIdentifier: "cell")
            cell.textLabel?.text = book.name
            cell.backgroundColor = .systemBackground
            cell.editingAccessoryType = UITableViewCell.AccessoryType.disclosureIndicator
            return cell
        }
        
        let snapshot = initialSnapshot()
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}


// MARK: - UITableViewDelegate
extension BooksViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        
        if indexPath.section == 0 {
            return .delete
        } else {
            return .insert
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let menuItem = self.dataSource.itemIdentifier(for: indexPath) else { return }
        let detailVC = DetailBookController()
        detailVC.setup(bookitem: menuItem)
        self.navigationController?.pushViewController(detailVC, animated: true)
    }
}
