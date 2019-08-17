//
//  ViewController.swift
//  Timer
//
//  Created by user on 16.08.2019.
//  Copyright © 2019 user. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    
    @IBOutlet weak var header: UINavigationBar!
    @IBOutlet weak var headerTitle: UINavigationItem!
    @IBOutlet weak var startStopButton: UIButton!
    @IBOutlet weak var resultTable: UITableView!
    
    private var isRun = false
    private var startDate = Date()
    private var rounds: Int = 0
    
    var context: NSManagedObjectContext! {
        didSet {
            initTable()
        }
    }
    
    var fetchedResult: NSFetchedResultsController<TimeResult>?
    var backgroundContext: NSManagedObjectContext!
    
    func initTable() {
        initFetch(context)
        fetchData()
    }
    
    func fetchData() {
        do {
            try fetchedResult?.performFetch()
            rounds = fetchedResult?.fetchedObjects?.count ?? 1
            resultTable.refreshControl?.endRefreshing()
            resultTable.reloadData()
        } catch {
            print("cannot fetch data, \(error)")
        }
    }
    
    func initFetch(_ context: NSManagedObjectContext) {
        let sort = NSSortDescriptor(key: "round", ascending: false)
        let result = NSFetchRequest<TimeResult>(entityName: "TimeResult")
        result.sortDescriptors = [sort]
        
        fetchedResult = NSFetchedResultsController(fetchRequest: result, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResult?.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        headerTitle.title = "Результаты"
        resultTable.register(UITableViewCell.self, forCellReuseIdentifier: "ResultItem")
        resultTable.refreshControl = UIRefreshControl()
        resultTable.refreshControl?.beginRefreshing()
        NotificationCenter.default.addObserver(self, selector: #selector(managedObjectContextDidSave(notification:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: nil)
    }
    
    @objc func managedObjectContextDidSave(notification: Notification) {
        context.perform {
            self.context.mergeChanges(fromContextDidSave: notification)
        }
    }
    
    @IBAction func plus(_ sender: UIBarButtonItem) {
        guard isRun else {return}
        let time = Date().timeIntervalSince(startDate)
        
        DispatchQueue.global(qos: .userInitiated).async {[weak self] in
            guard let `self` = self else {return}
            let timeRes = TimeResult(context: self.backgroundContext)
            timeRes.timeResult = time
            self.rounds = self.rounds + 1
            timeRes.round = Int32(self.rounds)
            self.backgroundContext.performAndWait {
                do {
                    try self.backgroundContext.save()
                } catch {
                    print("cannot save round: \(error)")
                }
            }
            
        }
        
        /*
         guard let context = context else {return}

         guard let timeRes = NSEntityDescription.insertNewObject(forEntityName: "TimeResult", into: context) as? TimeResult else {return}
        timeRes.timeResult = time
        rounds = rounds + 1
        timeRes.round = Int32(rounds)
        do {
            try context.save()
        } catch {
            print("cannot save round: \(error)")
        }*/
    }
    
    @IBAction func startStop(_ sender: UIButton) {
        isRun = !isRun
        if (isRun) {
            headerTitle.title = "Время пошло"
            startStopButton.setTitle("Стоп", for: .normal)
            startDate = Date()
        } else {
            headerTitle.title = "Результаты"
            startStopButton.setTitle("Старт", for: .normal)
        }
    }
}

extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let secions = fetchedResult?.sections else {return 0}
        return secions[section].numberOfObjects
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = resultTable.dequeueReusableCell(withIdentifier: "ResultItem", for: indexPath)
        
        guard let timeResult = fetchedResult?.object(at: indexPath) else {return cell}
        let time = TimeInterval(timeResult.timeResult)
        cell.textLabel?.text = time.stringTime
        return cell
    }
    
}

extension ViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        resultTable.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        resultTable.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            resultTable.insertRows(at: [newIndexPath!], with: .automatic)
        case .update:
            resultTable.reloadRows(at: [indexPath!], with: .automatic)
        case .move:
            resultTable.deleteRows(at: [indexPath!], with: .automatic)
            resultTable.insertRows(at: [newIndexPath!], with: .automatic)
        case .delete:
            resultTable.deleteRows(at: [indexPath!], with: .automatic)
        }
    }
}

extension TimeInterval {
    
    var stringTime: String {
        var hours = "\(Int(self) / 3600)"
        if hours.count < 2 {hours = "0" + hours}
        
        var minutes = "\((Int(self) / 60 ) % 60)"
        if minutes.count < 2 {minutes = "0" + minutes}
        
        var seconds = "\(Int(self) % 60)"
        if seconds.count < 2 {seconds = "0" + seconds}
        
        var milliseconds = "\(Int((truncatingRemainder(dividingBy: 1)) * 1000))"
        if milliseconds.count < 2 {milliseconds = "0" + milliseconds}
        if milliseconds.count < 3 {milliseconds = "0" + milliseconds}
        
        return "\(hours):\(minutes):\(seconds).\(milliseconds)"
    }
}
